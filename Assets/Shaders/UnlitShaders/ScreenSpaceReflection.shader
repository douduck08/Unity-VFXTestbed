Shader "Custom/Screen Space Reflection" {
    Properties {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Screen Space Reflection and Refraction)]
        [Toggle(ENABLE_REFLECTION)] _EnableReflection ("Enable Reflection", Float) = 0
        [Toggle(ENABLE_REFRACTION)] _EnableRefraction ("Enable Refraction", Float) = 0
        _Intensity ("Intensity", Range (0, 1)) = 0.5
        _RimPower ("Fresnel Angle", Range(1, 20) ) = 5
        _RefractionRatio ("Refraction Ratio", Range (0, 1)) = 0.75

        [Header(Ray Marching)]
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
            #pragma multi_compile _ ENABLE_REFLECTION
            #pragma multi_compile _ ENABLE_REFRACTION

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

            float4 _Color;
            float _Intensity;
            float _RimPower;
            float _RefractionRatio;

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
                Result result;
                float4 reflectColor = 0;
                float4 refractColor = 0;

                ray.origin = i.viewPos;
                float3 viewNormal = normalize(i.viewNormal);
                if (ray.origin.z > -_MaximumMarchDistance) {
                    #if ENABLE_REFLECTION
                        ray.direction = normalize(reflect(ray.origin, viewNormal));
                        result = March(ray, _MaximumMarchDistance, _MaximumIteration, _Thickness, 0.0);
                        if (result.isHit){
                            reflectColor = tex2D(_GrabTexture, result.uv);
                        }
                    #endif

                    #if ENABLE_REFRACTION
                        ray.direction = normalize(refract(ray.origin, viewNormal, _RefractionRatio));
                        result = March(ray, _MaximumMarchDistance, _MaximumIteration, _Thickness, 0.0);
                        if (result.isHit){
                            refractColor = tex2D(_GrabTexture, result.uv);
                        }
                    #endif
                }

                float NdotV = dot(viewNormal, normalize(-i.viewPos));
                float fresnel = pow(NdotV, _RimPower);
                float4 mixColor = lerp(refractColor, reflectColor, fresnel);

                float4 color = tex2D(_MainTex, i.uv) * _Color;
                return lerp(color, mixColor, _Intensity);
            }
            ENDCG
        }
    }
}
