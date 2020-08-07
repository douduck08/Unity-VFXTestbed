float3 VAT_RotateVector(float3 v, float4 q) {
    return v + cross(2 * q.xyz, cross(q.xyz, v) + q.w * v);
}

float4 GetSampleUV (float4 texelSize, float uv1, float currentFrame, float totalFrame) {
    float frame = floor(clamp(currentFrame, 0, totalFrame - 1));
    float v = 1.0 - (frame + 0.5) * abs(texelSize.y);
    return float4(uv1.x, v, 0, 0);
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
    float3 pivot = lerp(bounds.z, bounds.w, color);
    float4 rot = (r * 2 - 1);

    // outPosition = VAT_RotateVector(position - pivot, rot) + pivot + offset;
    outPosition = offset;
    outNormal = VAT_RotateVector(normal, rot);
}