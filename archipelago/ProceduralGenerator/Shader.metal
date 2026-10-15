#include <metal_stdlib>
using namespace metal;

struct HexInstance {
    float2 centerPosition;
    float4 color;
    float  distanceFromCenter;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut hexagonVertex(uint vertexID [[vertex_id]],
                               uint instanceID [[instance_id]],
                               constant HexInstance* instances [[buffer(0)]],
                               constant float &hexRadius [[buffer(1)]],
                               constant float2 &viewSize [[buffer(2)]]) {
    HexInstance inst = instances[instanceID];

    int triangleIndex = vertexID / 3;
    int pointInTriangle = vertexID % 3;
    
    float angle1 = float(triangleIndex) * (M_PI_F / 3.0f) - (M_PI_F / 6.0f);
    float angle2 = float(triangleIndex + 1) * (M_PI_F / 3.0f) - (M_PI_F / 6.0f);
    
    float2 localOffset = float2(0.0);
    if (pointInTriangle == 1) {
        localOffset = float2(cos(angle1), sin(angle1)) * (hexRadius);
    } else if (pointInTriangle == 2) {
        localOffset = float2(cos(angle2), sin(angle2)) * (hexRadius);
    }
    
    float2 worldPos = inst.centerPosition + localOffset;
    
    float ndcX = (worldPos.x / viewSize.x) * 2.0f - 1.0f;
    float ndcY = 1.0f - (worldPos.y / viewSize.y) * 2.0f;
    
    VertexOut out;
    out.position = float4(ndcX, ndcY, 0.0f, 1.0f);
    out.color = inst.color;
    return out;
}

fragment float4 hexagonFragment(VertexOut in [[stage_in]]) {
    return in.color;
}
