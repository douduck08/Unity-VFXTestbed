Shader "Custom/Standard Translucency" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
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
        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        void surf (Input IN, inout SurfaceOutputTranslucent o) {
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }

        inline half4 LightingTranslucent (SurfaceOutputTranslucent s, float3 viewDir, UnityGI gi) {
            s.Normal = normalize(s.Normal);

            half oneMinusReflectivity;
            half3 specColor;
            s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

            // shader relies on pre-multiply alpha-blend (_SrcBlend = One, _DstBlend = OneMinusSrcAlpha)
            // this is necessary to handle transparency in physically correct way - only diffuse component gets affected by alpha
            half outputAlpha;
            s.Albedo = PreMultiplyAlpha (s.Albedo, s.Alpha, oneMinusReflectivity, /*out*/ outputAlpha);

            half4 c = UNITY_BRDF_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);
            c.a = outputAlpha;
            return c;
        }

        inline half4 LightingTranslucent_Deferred (SurfaceOutputTranslucent s, float3 viewDir, UnityGI gi, out half4 outGBuffer0, out half4 outGBuffer1, out half4 outGBuffer2) {
            half oneMinusReflectivity;
            half3 specColor;
            s.Albedo = DiffuseAndSpecularFromMetallic (s.Albedo, s.Metallic, /*out*/ specColor, /*out*/ oneMinusReflectivity);

            half4 c = UNITY_BRDF_PBS (s.Albedo, specColor, oneMinusReflectivity, s.Smoothness, s.Normal, viewDir, gi.light, gi.indirect);

            UnityStandardData data;
            data.diffuseColor   = s.Albedo;
            data.occlusion      = s.Occlusion;
            data.specularColor  = specColor;
            data.smoothness     = s.Smoothness;
            data.normalWorld    = s.Normal;

            UnityStandardDataToGbuffer(data, outGBuffer0, outGBuffer1, outGBuffer2);

            half4 emission = half4(s.Emission + c.rgb, 1);
            return emission;
        }

        inline void LightingTranslucent_GI (SurfaceOutputTranslucent s, UnityGIInput data, inout UnityGI gi) {
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
