Shader "Custom/GridDeform"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows addshadow vertex:vert
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
        };

        sampler2D _MainTex;
        half _Glossiness;
        half _Metallic;
        half4 _Color;

        float _Grid[32];

        int GetId(int x, int y, int z) {
            return x * 4 + y * 2 + z;
        }

        float3 GetGridPoint(int x, int y, int z) {
            int id = GetId(x, y, z);
            return float3(_Grid[id * 4], _Grid[id * 4 + 1], _Grid[id * 4 + 2]);
        }

        void vert (inout appdata_full v) {
            float3 posInGrid = v.vertex.xyz + 0.5;
            int3 index = posInGrid;
            float3 weight = frac(posInGrid);

            float3 p00 = lerp(GetGridPoint(index.x, index.y, index.z), GetGridPoint(index.x + 1, index.y, index.z), weight.x);
            float3 p01 = lerp(GetGridPoint(index.x, index.y + 1, index.z), GetGridPoint(index.x + 1, index.y + 1, index.z), weight.x);
            float3 p10 = lerp(GetGridPoint(index.x, index.y, index.z + 1), GetGridPoint(index.x + 1, index.y, index.z + 1), weight.x);
            float3 p11 = lerp(GetGridPoint(index.x, index.y + 1, index.z + 1), GetGridPoint(index.x + 1, index.y + 1, index.z + 1), weight.x);
            float3 p0 = lerp(p00, p01, weight.y);
            float3 p1 = lerp(p10, p11, weight.y);
            float3 p = lerp(p0, p1, weight.z);

            v.vertex.xyz = p;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            half4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
}
