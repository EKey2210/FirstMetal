//
//  Shader.metal
//  FirstMetal
//

#include <metal_stdlib>
using namespace metal;

// 構造体を定義
struct MyVertex {
    // 座標
    float4 position [[position]];
    // 色
    float4 color;
};

// 頂点シェーダー
vertex MyVertex myVertexShader(device float4 *position [[ buffer(0) ]],
                               uint vid [[vertex_id]]) {
    MyVertex v;
    // 0番目のバッファーから頂点座標を設定
    v.position = position[vid];
    return v;
}

// フラグメントシェーダー
fragment float4 myFragmentShader(float4 pixPos [[position]],
                                 constant float2& resolution [[buffer(0)]],
                                 constant float&  time [[buffer(1)]]) {
    
    float3 color = float3(0.0);
    
    float2 uv = (pixPos.xy*2.0 - resolution)/min(resolution.x,resolution.y);
    uv.y *= -1.0;
    color.xy = float2(uv.x*sin(time),uv.y*cos(time));
    color.z  = 1.0;
    return float4(color,1.0);
//    return step(length(uv),0.5+0.5*sin(time));
}
