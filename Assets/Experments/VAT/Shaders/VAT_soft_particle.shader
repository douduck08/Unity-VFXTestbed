Shader "Houdini VAT/soft (particle)" {
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
        Cull Off

        CGPROGRAM
        #pragma surface surf Standard nolightmap nometa noforwardadd fullforwardshadows addshadow vertex:vert
        #pragma target 3.0

        #pragma multi_compile_instancing
        #pragma instancing_options procedural:vertInstancingSetup

        #pragma shader_feature _PACKED_NORMAL_ON

        #include "UnityStandardParticleInstancing.cginc"
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
            float4 color;
        };

        void vert(inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            vertInstancingColor(o.color);

            float4 bounds = float4(_PosMin, _PosMax, 0, 0);
            float currentFrames = o.color.r * _TotalFrames;

            float3 outPosition1, outNormal1;
            SoftVAT(v.vertex, v.texcoord1, _PosTex, _NormTex, _PosTex_TexelSize, bounds, _TotalFrames, currentFrames, outPosition1, outNormal1);

            float3 outPosition2, outNormal2;
            SoftVAT(v.vertex, v.texcoord1, _PosTex, _NormTex, _PosTex_TexelSize, bounds, _TotalFrames, currentFrames + 1, outPosition2, outNormal2);

            float t = frac(currentFrames);
            v.vertex.xyz = lerp(outPosition1, outPosition2, t);
            v.normal = normalize(lerp(outNormal1, outNormal2, t));
        }

        void surf (Input IN, inout SurfaceOutputStandard o) {
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a * IN.color.a;
        }
        ENDCG
    }
}
