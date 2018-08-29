Shader "Custom/Surface Cover" {
    Properties {
        _Color ("Texture", Color) = (1,1,1,1)
        _Edge ("Edge", Float) = 1
    }

    SubShader {
        Pass {
            Stencil {
                Ref 1
                WriteMask 1
                Comp Always
                Pass Zero
                ZFail Replace
            }

            ColorMask A
            ZWrite off
            ZTest LEqual
            Cull Back

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_deferred
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityDeferredLibrary.cginc"

            half _Edge;

            half4 frag (unity_v2f_deferred i) : SV_Target {
                half depth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.uv)));
                return saturate (_Edge * (depth - i.pos.w));
            }
            ENDCG
        }

        Pass {
            Stencil {
                Ref 1
                ReadMask 1
                Comp NotEqual
            }

            Blend DstAlpha Zero
            ColorMask A
            ZWrite Off
            ZTest Greater
            Cull Front

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_deferred
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityDeferredLibrary.cginc"

            half _Edge;

            half4 frag (unity_v2f_deferred i) : SV_Target {
                half depth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.uv)));
                return saturate (_Edge * (i.pos.w- depth));
            }
            ENDCG
        }

        Pass {
            Stencil {
                Ref 1
                ReadMask 1
                Comp NotEqual
            }

            Blend DstAlpha OneMinusDstAlpha
            ZWrite Off
            ZTest Greater
            Cull Front

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert_deferred
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityDeferredLibrary.cginc"

            half4 _Color;
            half _Edge;

            half4 frag (unity_v2f_deferred i) : SV_Target {
                half depth = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.uv)));
                return _Color;
            }
            ENDCG
        }
    }
}
