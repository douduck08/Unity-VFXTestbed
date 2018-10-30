#ifndef RAY_MARCH_INCLUDED
#define RAY_MARCH_INCLUDED
// http://casual-effects.blogspot.com/2014/08/screen-space-ray-tracing.html

#include "UnityCG.cginc"

sampler2D _CameraDepthTexture;
float4 _CameraDepthTexture_TexelSize;

// Helper structs
struct Ray {
    float3 origin;
    float3 direction;
};

struct Result {
    bool isHit;
    float2 uv;
    float3 position;
    int iterationCount;
};

// Helper functions
float GetSquaredDistance (float2 first, float2 second) {
    first -= second;
    return dot(first, first);
}

float2 GetScreenPos(float2 uv) {
    float2 o = uv * 0.5f;
    o.xy = float2(o.x, o.y * _ProjectionParams.x) + 0.5f;
    return o;
}

Result March (Ray ray, float maximumMarchDistance, float maximumIteration, float stride, float jitter) {
    Result result;
    UNITY_INITIALIZE_OUTPUT(Result, result);

    float rayLength = (ray.origin.z + ray.direction.z * maximumMarchDistance > -_ProjectionParams.y) ? 
        (-_ProjectionParams.y - ray.origin.z) / ray.direction.z : maximumMarchDistance;
    float3 rayEnd = ray.origin + ray.direction * rayLength;

    float4 h0 = mul(UNITY_MATRIX_P, ray.origin);
    float4 h1 = mul(UNITY_MATRIX_P, rayEnd);
    const float2 k01 = rcp(float2(h0.w, h1.w));  // k0 and k1

    float3 q0 = ray.origin * k01.x;
    float3 q1 = rayEnd * k01.y;
    float2 p0 = h0.xy * k01.x;
    float2 p1 = h1.xy * k01.y;

    p1 += step(GetSquaredDistance(p0, p1), 0.0001) * max(_ProjectionParams.z, _ProjectionParams.w);
    float2 delta = p1 - p0;

    bool isPermuted = false;
    if (abs(delta.x) < abs(delta.y)) {
        isPermuted = true;
        delta = delta.yx;
        p0 = p0.yx;
        p1 = p1.yx;
        stride /= _ScreenParams.y;
    } else {
        stride /= _ScreenParams.x;
    }

    float stepDir = sign(delta.x);
    float invdx = stepDir / delta.x;

    float2 dP = float2(stepDir, delta.y * invdx);
    float3 dQ = (q1 - q0) * invdx;
    float  dk = (k01.y - k01.x) * invdx;

    float4 derivatives = float4(dP, dQ.z, dk) * stride;
    float4 tracker = float4(p0, q0.z, k01.x) + derivatives * jitter;
    float z = 0.0;
    float end = p1.x * stepDir;

    [loop]
    for (int stepCount = 0; stepCount < maximumIteration; ++stepCount) {
        tracker += derivatives;
        result.uv = isPermuted ? tracker.yx : tracker.xy;
        result.uv = GetScreenPos(result.uv);
        if (any(result.uv < 0.0) || any(result.uv > 1.0)) {
            return result;
        }

        z = (tracker.z + derivatives.z * 0.5) / (tracker.w + derivatives.w * 0.5);
        float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, result.uv);
        float depth = -LinearEyeDepth(d);
        if (z < depth) {
            result.isHit = true;
            result.position.z = z;
            result.iterationCount = stepCount + 1;
            return result;
        }
    }
    return result;
}

#endif // RAY_MARCH_INCLUDED