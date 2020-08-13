float3 VAT_RotateVector (float3 v, float4 q) {
    return v + cross(2 * q.xyz, cross(q.xyz, v) + q.w * v);
}

float3 VAT_UnpackAlpha (float a) {
    float a_hi = floor(a * 32);
    float a_lo = a * 32 * 32 - a_hi * 32;

    float2 n2 = float2(a_hi, a_lo) / 31.5 * 4 - 2;
    float n2_n2 = dot(n2, n2);
    float3 n3 = float3(sqrt(1 - n2_n2 / 4) * n2, 1 - n2_n2 / 2);

    return clamp(n3, -1, 1);
}

float3 VAT_ConvertSpace (float3 v) {
    return v.xzy * float3(-1, 1, 1);
}

float4 GetSampleUV (float4 texelSize, float2 uv, float currentFrame, float totalFrame) {
    float frame = (int)(clamp(currentFrame, 0, totalFrame - 1));
    float stride = texelSize.w / totalFrame;
    float offset = frame * stride * abs(texelSize.y);
    return float4(uv.x, uv.y - offset, 0, 0);
}

void SoftVAT (
float3 position,
float2 uv1,
sampler2D positionMap,
sampler2D normalMap,
float4 texelSize,
float2 bounds,
float totalFrame,
float currentFrame,
out float3 outPosition,
out float3 outNormal
) {
    float4 sampleUV = GetSampleUV(texelSize, uv1, currentFrame, totalFrame);
    float4 p = tex2Dlod(positionMap, sampleUV);

    outPosition = VAT_ConvertSpace(lerp(bounds.x, bounds.y, p.xyz));

#ifdef _PACKED_NORMAL_ON
    // Alpha-packed normal
    outNormal = VAT_ConvertSpace(VAT_UnpackAlpha(p.w));
#else
    // Normal vector from normal map
    outNormal = VAT_ConvertSpace(tex2Dlod(normalMap, sampleUV).xyz);
#endif
}

void FluidVAT (
float3 position,
float2 uv0,
sampler2D positionMap,
sampler2D normalMap,
float4 texelSize,
float2 bounds,
float totalFrame,
float currentFrame,
out float3 outPosition,
out float3 outNormal
) {
    float4 sampleUV = GetSampleUV(texelSize, uv0, currentFrame, totalFrame);
    float4 p = tex2Dlod(positionMap, sampleUV);

    outPosition = VAT_ConvertSpace(lerp(bounds.x, bounds.y, p.xyz));

#ifdef _PACKED_NORMAL_ON
    // Alpha-packed normal
    outNormal = VAT_ConvertSpace(VAT_UnpackAlpha(p.w));
#else
    // Normal vector from normal map
    outNormal = VAT_ConvertSpace(tex2Dlod(normalMap, sampleUV).xyz);
#endif
}

void RigidVAT (
float3 position,
float3 normal,
float3 color,
float2 uv1,
sampler2D positionMap,
sampler2D rotationMap,
float4 texelSize,
float4 bounds,
float totalFrame,
float currentFrame,
out float3 outPosition,
out float3 outNormal
) {
    float4 sampleUV = GetSampleUV(texelSize, uv1, currentFrame, totalFrame);
    float4 p = tex2Dlod(positionMap, sampleUV);
    float4 r = tex2Dlod(rotationMap, sampleUV);

    float3 offset = lerp(bounds.x, bounds.y, p.xyz);
    // float3 pivot = lerp(bounds.z, bounds.w, color);
    float4 rot = (r * 2 - 1);

    // outPosition = VAT_RotateVector(position - pivot, rot) + pivot + offset;
    outPosition = offset;
    outNormal = VAT_RotateVector(normal, rot);
}

// ----------------
// dithering cutoff
// ----------------
inline half Bayer8x8 (int x, int y) {
    const half bayer8x8[64] = {
        0, 32, 8, 40, 2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26 ,
        12, 44, 4, 36, 14, 46, 6, 38 ,
        60, 28, 52, 20, 62, 30, 54, 22,
        3, 35, 11, 43, 1, 33, 9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47, 7, 39, 13, 45, 5, 37,
        63, 31, 55, 23, 61, 29, 53, 21
    };
    int idx = y * 8 + x;
    return (bayer8x8[idx] + 1) / 65;
}

inline void Dither8x8Clip (float4 screenPos, half alpha) {
    float2 screenPixel = (screenPos.xy / screenPos.w) * _ScreenParams.xy;
    half dither = Bayer8x8(fmod(screenPixel.x, 8), fmod(screenPixel.y, 8));
    clip(alpha - dither);
}