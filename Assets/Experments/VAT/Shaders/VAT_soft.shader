Shader "Houdini VAT/soft" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        [Header(VAT)]
        _PosTex ("Position Map", 2D) = "white" {}
        _NormTex ("Normal Map", 2D) = "white" {}
        [Toggle(_PACKED_NORMAL_ON)] _PACKED_NORMAL ("Packed Normal into Alpha", Float) = 0
        _TotalFrames ("_numOfFrames", Float) = 0.0
        _PosMax ("_posMax", Float) = 0.0
        _PosMin ("_posMin", Float) = 0.0
        _CurrentFrames ("Current Frame", Float) = 0.0
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM
        #pragma surface surf Standard addshadow vertex:vert
        #pragma target 3.0
        #pragma shader_feature _PACKED_NORMAL_ON

        #include "VATHelper.hlsl"

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        half4 _Color;

        sampler2D _PosTex;
        sampler2D _NormTex;
        float4 _PosTex_TexelSize;

        float _PosMax;
        float _PosMin;
        float _CurrentFrames;
        float _TotalFrames;

        struct Input {
            float2 uv_MainTex;
        };

        void vert(inout appdata_full v) {
            float4 bounds = float4(_PosMin, _PosMax, 0, 0);

            float3 outPosition1, outNormal1;
            SoftVAT(v.vertex, v.texcoord1, _PosTex, _NormTex, _PosTex_TexelSize, bounds, _TotalFrames, _CurrentFrames, outPosition1, outNormal1);

            // float3 outPosition2, outNormal2;
            // SoftVAT(v.vertex, v.texcoord1, _PosTex, _NormTex, _PosTex_TexelSize, bounds, _TotalFrames, _CurrentFrames + 1, outPosition2, outNormal2);

            // float t = frac(_CurrentFrames);
            // v.vertex.xyz = lerp(outPosition1, outPosition2, t);
            // v.normal = normalize(lerp(outNormal1, outNormal2, t));

            v.vertex.xyz = outPosition1;
            v.normal = outNormal1;
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
