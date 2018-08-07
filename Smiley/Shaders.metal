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

using namespace metal;

// macro for smoothstep
#define S(a,b,t) smoothstep(a,b,t)
#define sat(x) clamp(x, 0., 1.)

float remap01(float a, float b, float t)
{
    return sat((t-a)/(b-a));
}

float remap(float a, float b, float c, float d, float t)
{
    return ((t-a)/(b-a) * (d-c) + c);
}

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
    // make an orange background
    float4 col = float4(.9, .65, .1, 1);
    
    // mask the orange color into a circle
    float d = length(uv);
    col.a = S(.5, .49, d);
   
    // edgeshade with a non-linear falloff
    float edgeShade = remap01(.35, .5, d);
    edgeShade *= edgeShade;
    col.rgb *= 1 - edgeShade * .5;
    
    // outline the smiley with a darker orange
    col.rbg = mix(col.rbg, float3(.6,.1,.3), S(.47, .48, d));
    return col;
}

float4 Smiley(float2 uv)
{
    float4 col = float4(0.);
    float4 head = Head(uv);
    col = mix(col, head, head.a);
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
