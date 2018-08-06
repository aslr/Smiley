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

// Original Shadertoy shader code
// float Circle(vec2 uv, float r, float blur
// {
//     float d = length(uv9;
//     float c = smoothstep(r, r-blur, d);
//     return c;
// }
//
// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {
//     vec2 uv = fragCoord.xy / iResoltution.xy;
//     uv -= .5;
//     uv.x *= iResolution.x/iResolution.y;
//     float c = Circle(uv, .4, .05);
//     fragColor = vec4(vec3(c),1.0);
// }

using namespace metal;

float Circle(float2 uv, float r, float blur)
{
    float d = length(uv);
    float c = smoothstep(r, r - blur, d);
    return c;
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
    
    // make a circle with smoothstep
    float c = Circle(uv, .4, .05);
    
    // return the "fragColor" by using the w element of the float4 used for time
    output.write(float4(float3(c), 1), gid);
}
