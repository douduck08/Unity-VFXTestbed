#ifndef RAY_MARCH_INCLUDED
#define RAY_MARCH_INCLUDED
// Heavily adapted from McGuire and Mara's original implementation
// http://casual-effects.blogspot.com/2014/08/screen-space-ray-tracing.html

#include "UnityCG.cginc"

// Helper structs
struct Ray {
    float3 origin;
    float3 direction;
};

struct Segment {
    float3 start;
    float3 end;
    float3 direction;
};

struct Result {
    bool isHit;
    float2 uv;
    float3 position;
    int iterationCount;
};

// Uniforms
sampler2D _CameraDepthTexture;
float _MaximumMarchDistance;
float _MaximumIterationCount;

// Helper functions
float GetSquaredDistance (float2 first, float2 second) {
    first -= second;
    return dot(first, first);
}

Result March (Ray ray, float4 screenPos, float stride, float jitter) {
    Result result;
    UNITY_INITIALIZE_OUTPUT(Result, result);

    float magnitude = (ray.origin.z + ray.direction.z * _MaximumMarchDistance > -_ProjectionParams.y) ? 
        (-_ProjectionParams.y - ray.origin.z) / ray.direction.z : _MaximumMarchDistance;

    Segment segment;
    segment.start = ray.origin;
    segment.end = ray.origin + ray.direction * magnitude;

    float4 h0 = mul(UNITY_MATRIX_P, segment.start);
    float4 h1 = mul(UNITY_MATRIX_P, segment.end);
    const float2 homogenizers = rcp(float2(h0.w, h1.w));  // k0 and k1
    segment.start *= homogenizers.x;  // q0
    segment.end *= homogenizers.y;  // q1

    // Screen-space endpoints, p0 and p1
    float4 endPoints = float4(h0.xy, h1.xy) * homogenizers.xxyy; 
    endPoints.zw += step(GetSquaredDistance(endPoints.xy, endPoints.zw), 0.0001) * max(_ProjectionParams.z, _ProjectionParams.w);
    float2 displacement = endPoints.zw - endPoints.xy;

    bool isPermuted = false;
    if (abs(displacement.x) < abs(displacement.y)) {
        isPermuted = true;
        displacement = displacement.yx;
        endPoints.xyzw = endPoints.yxwz;
    }

    float direction = sign(displacement.x);
    float invdx = direction / displacement.x;
    segment.direction = (segment.end - segment.start) * invdx;
    float4 derivatives = float4(float2(direction, displacement.y * invdx), (homogenizers.y - homogenizers.x) * invdx, segment.direction.z); // float2(dp), float(dk), float(z)

    derivatives *= stride;
    segment.direction *= stride;

    float2 z = 0.0;
    float4 tracker = float4(endPoints.xy, homogenizers.x, segment.start.z) + derivatives * jitter; // floa2(p0), 

    for (int i = 0; i < 16; ++i) {
        if (any(result.uv < 0.0) || any(result.uv > 1.0)) {
            result.isHit = false;
            return result;
        }

        tracker += derivatives;

        z.x = z.y;
        z.y = tracker.w + derivatives.w * 0.5;
        z.y /= tracker.z + derivatives.z * 0.5;

#if SSR_KILL_FIREFLIES
        UNITY_FLATTEN
        if (z.y < -_MaximumMarchDistance) {
            result.isHit = false;
            return result;
        }
#endif

        UNITY_FLATTEN
        if (z.y > z.x) {
            float k = z.x;
            z.x = z.y;
            z.y = k;
        }

        float2 uv = tracker.xy;

        UNITY_FLATTEN
        if (isPermuted)
            uv = uv.yx;

        uv *= _ScreenParams.xy;

        float d = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(screenPos));
        float depth = -LinearEyeDepth(d);

        UNITY_FLATTEN
        if (z.y < depth) {
            result.uv = uv;
            result.isHit = true;
            result.iterationCount = i + 1;
            return result;
        }
    }

    return result;
}

#endif // RAY_MARCH_INCLUDED