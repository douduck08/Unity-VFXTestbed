Shader "Custom/Toon Water" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "black" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Foam("Foamline Thickness", Range(0,3)) = 0.5
        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _Speed("Wave Speed", Range(0,1)) = 0.5
        _Amount("Wave Amount", Range(0,1)) = 0.5
        _Height("Wave Height", Range(0,1)) = 0.5
    }
    SubShader {
        Tags { "RenderType" = "Opaque"  "Queue" = "Transparent" }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert
        #pragma target 3.0

        
        struct Input {
            float2 uv_MainTex;
            float4 screenPos;
        };

        uniform sampler2D _CameraDepthTexture;
        sampler2D _MainTex;
        fixed4 _Color;
        half _Glossiness;
        half _Metallic;
        half _Foam;
        fixed4 _FoamColor;
        float _Speed, _Amount, _Height;

        void vert (inout appdata_full v) {
            v.vertex.z += sin(_Time.z * _Speed + (v.vertex.x * v.vertex.y * _Amount)) * _Height;
            //v.vertex.z += sin(_Time.z * _Speed + (v.vertex.x * v.vertex.z * _Amount)) * _Height;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            half depth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
            half foamLine = 1 - saturate(_Foam * (depth - IN.screenPos.w));
            o.Albedo = _Color.rgb + (_FoamColor.a * tex2D ( _MainTex, IN.uv_MainTex).rgb + foamLine * _FoamColor.rgb);
            o.Alpha = _Color.a;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
