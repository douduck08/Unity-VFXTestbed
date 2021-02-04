Shader "Custom/Standard Translucency" {
    // Ref: https://www.slideshare.net/colinbb/colin-barrebrisebois-gdc-2011-approximating-translucency-for-a-fast-cheap-and-convincing-subsurfacescattering-look-7170855
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _BumpMap ("Normal (Normal)", 2D) = "bump" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        [Gamma] _Metallic ("Metallic", Range(0,1)) = 0.0
        // Translucency
        [Header(Subsurface Setting)]
        _Ambient ("Ambient", Range(0,1)) = 0.0 // not work in deferred path
        _Distortion ("Distortion", Range(0,1)) = 0.0
        _Power ("Power", Range(0.5,20)) = 4.0  // not work in deferred path
        _Scale ("Scale", Range(0.5,20)) = 0.5  // not work in deferred path, define in light will be better
        _Thickness ("Thickness", Range(0,1)) = 0.5
        // _Thickness ("Thickness (R)", 2D) = "black" {}
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Translucent fullforwardshadows
        #pragma target 3.0

        #include "UnityPBSLighting.cginc"

        struct Input {
            float2 uv_MainTex;
        };

        struct SurfaceOutputTranslucent {
            fixed3 Albedo;
            fixed3 Normal;
            half3 Emission;
            half Metallic;
            half Smoothness;
            half Occlusion;
            fixed Alpha;
        };

        sampler2D _MainTex;
        sampler2D _BumpMap;
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        half _Ambient;
        half _Distortion;
        half _Power;
        half _Scale;
        half _Thickness;

        void surf (Input IN, inout SurfaceOutputTranslucent o) {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
            o.Emission = 0;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Occlusion = 1;
        }

        inline half4 LightingTranslucent (SurfaceOutputTranslucent s, float3 viewDir, UnityGI gi) {
            s.Normal = normalize(s.Normal);

            half oneMinusReflectivity;
            half3 specColor;
            s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

            half outputAlpha;
            s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

            // Translucency
            half3 transDir = gi.light.dir + s.Normal * _Distortion;
            half transDot = pow(saturate(dot(viewDir, -transDir)), _Power) * _Scale;
            half3 transLight = gi.light.color * (transDot + _Ambient) * _Thickness;
            half3 transAlbedo = s.Albedo * transLight;

            half4 c = UNITY_BRDF_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
            c.rgb += transAlbedo;
            c.a = outputAlpha;
            return c;
        }

        inline half4 LightingTranslucent_Deferred (SurfaceOutputTranslucent s, float3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2) {
            half oneMinusReflectivity;
            half3 specColor;
            half3 albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

            half4 c = UNITY_BRDF_PBS (albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);

            UnityStandardData data;
            data.diffuseColor   = s.Albedo;  // original albedo
            data.occlusion      = s.Occlusion;
            data.specularColor  = half3 (_Distortion, _Thickness, s.Metallic); // custom gbuffer data
            data.smoothness     = s.Smoothness;
            data.normalWorld    = s.Normal;

            UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);
            outGBuffer2.a = 0.33; // mask

            half4 emission = half4(s.Emission + c.rgb, 1);
            return emission;
        }

        inline void LightingTranslucent_GI (SurfaceOutputTranslucent s, UnityGIInput data, inout UnityGI gi) {
            // UNITY_GI(gi, s, data);
#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
#else
            Unity_GlossyEnvironmentData g = UnityGlossyEnvironmentSetup(s.Smoothness, data.worldViewDir, s.Normal, lerp(unity_ColorSpaceDielectricSpec.rgb, s.Albedo, s.Metallic));
            gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal, g);
#endif
        }

        ENDCG
    }
    FallBack "Diffuse"
}
