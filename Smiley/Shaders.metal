//
//  Shaders.metal
//  Smiley
//
//  Created by João Varela on 05/08/2018.
//  Copyright © 2018 João Varela. All rights reserved.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

// macro for smoothstep
#define S(a,b,t) smoothstep(a,b,t)

using namespace metal;

float4 Eye(float2 uv)
{
    float4 col = float4(0.);
    return col;
}

float4 Mouth(float2 uv)
{
    float4 col = float4(0.);
    return col;
}

float4 Head(float2 uv)
{
    float4 col = float4(.9, .65, .1, 1);
    float d = length(uv);
    col.x = S(.5, .49, d);
    return col;
}

float4 Smiley(float2 uv)
{
    float4 col = float4(0.);
    float4 head = Head(uv);
    col = mix(col, head, head.x);
    return col;
}

kernel void compute(texture2d<float,access::write> output [[texture(0)]],
                    constant float4 &time [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
    // get the width and height of the screen texture
    int width = output.get_width();
    int height = output.get_height();
    
    // set its resolution
    float2 iResolution = float2(width, height);  // 0 <> 1
    
    // compute the texture coordinates with the y-coordinate flipped
    // because the origin of Shadertoy's and Metal's y-coordinates differ
    float2 uv = float2(gid.x,height - gid.y) / iResolution;
    uv -= 0.5;  // -0.5 <> 0.5
    uv.x *= iResolution.x/iResolution.y;
    
    // make a black screen with a skeleton smiley function
    float4 col = Smiley(uv);
    output.write(col, gid);
}
