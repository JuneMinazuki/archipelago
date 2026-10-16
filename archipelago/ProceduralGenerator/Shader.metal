#include <metal_stdlib>
using namespace metal;

struct HexInstance {
    float2 centerPosition;
    float  elevation;
    float  distanceFromCenter;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

float4 colorForElevation(float elevation) {
    if (elevation < 0.25f) {
        return float4(0.08f, 0.25f, 0.55f, 1.0f); // Deep Water
    } else if (elevation < 0.35f) {
        return float4(0.15f, 0.45f, 0.75f, 1.0f); // Shallow Water
    } else if (elevation < 0.41f) {
        return float4(0.82f, 0.76f, 0.55f, 1.0f); // Sand
    } else if (elevation < 0.55f) {
        return float4(0.22f, 0.55f, 0.28f, 1.0f); // Grass
    } else if (elevation < 0.68f) {
        return float4(0.12f, 0.38f, 0.20f, 1.0f); // Forest
    } else if (elevation < 0.85f) {
        return float4(0.40f, 0.40f, 0.42f, 1.0f); // Mountain Rock
    } else {
        return float4(0.95f, 0.95f, 0.98f, 1.0f); // Snow Peak
    }
}

vertex VertexOut hexagonVertex(uint vertexID [[vertex_id]],
                               uint instanceID [[instance_id]],
                               constant HexInstance* instances [[buffer(0)]],
                               constant float &hexRadius [[buffer(1)]],
                               constant float2 &viewSize [[buffer(2)]],
                               constant float &maxDistanceSq [[buffer(3)]],
                               constant float &animationProgress [[buffer(4)]]) {
    HexInstance inst = instances[instanceID];

    float safeMaxDist = max(maxDistanceSq, 1.0f);
    float distanceRatio = sqrt(inst.distanceFromCenter / safeMaxDist);
    
    float transitionWidth = 0.15f;
    float adjustedProgress = animationProgress * (1.0f + transitionWidth);
    float localProgress = clamp((adjustedProgress - distanceRatio) / transitionWidth, 0.0f, 1.0f);
    
    VertexOut out;
    
    if (localProgress <= 0.0f) {
        out.position = float4(0.0f, 0.0f, 0.0f, -1.0f);
        out.color = float4(0.0f);
        return out;
    }

    float scale = sin(localProgress * (M_PI_F / 2.0f));

    int triangleIndex = vertexID / 3;
    int pointInTriangle = vertexID % 3;
    
    float angle1 = float(triangleIndex) * (M_PI_F / 3.0f) - (M_PI_F / 6.0f);
    float angle2 = float(triangleIndex + 1) * (M_PI_F / 3.0f) - (M_PI_F / 6.0f);
    
    float2 localOffset = float2(0.0);
    if (pointInTriangle == 1) {
        localOffset = float2(cos(angle1), sin(angle1)) * hexRadius * scale;
    } else if (pointInTriangle == 2) {
        localOffset = float2(cos(angle2), sin(angle2)) * hexRadius * scale;
    }
    
    float2 worldPos = inst.centerPosition + localOffset;
    
    float ndcX = (worldPos.x / viewSize.x) * 2.0f - 1.0f;
    float ndcY = 1.0f - (worldPos.y / viewSize.y) * 2.0f;
    
    out.position = float4(ndcX, ndcY, 0.0f, 1.0f);
    out.color = colorForElevation(inst.elevation);
    
    return out;
}

fragment float4 hexagonFragment(VertexOut in [[stage_in]]) {
    float darkFilter = 0.5f;
    return float4(in.color.rgb * darkFilter, in.color.a);
}
