Shader "Custom/Screen Space Reflection" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Screen Space Reflection)]
        _MaximumMarchDistance ("Maximum Distance", float) = 100.0
        _MaximumIteration ("Maximum Iteration", Range (1, 256)) = 64
        _Thickness ("Thickness", Range (1, 64)) = 8
    }
    SubShader {
        Tags { "Queue"="Transparent" }

        GrabPass{ }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            #include "../Includes/RayMarch.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 viewPos : TEXCOORD1;
                float3 viewNormal : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _GrabTexture;

            float _MaximumMarchDistance;
            float _MaximumIteration;
            float _Thickness;
            
            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                o.viewNormal = mul((float3x3)UNITY_MATRIX_MV, v.normal);
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target {
                Ray ray;
                ray.origin = i.viewPos;
                if (ray.origin.z < -_MaximumMarchDistance) return 0.0;

                ray.direction = normalize(reflect(ray.origin, normalize(i.viewNormal)));
                // if (ray.direction.z > 0.0) return 0.0;

                Result result = March(ray, _MaximumMarchDistance, _MaximumIteration, _Thickness, 0.0);
                if (result.isHit){
                    half4 col = tex2D(_GrabTexture, result.uv);
                    return col;
                }
                return 0.0;
            }
            ENDCG
        }
    }
}
