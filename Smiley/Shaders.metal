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

// Original ShaderToy shader code
// float Circle(vec2 uv, vec2 p, float r, float blur
// {
//     float d = length(uv-p;
//     float c = smoothstep(r, r-blur, d);
//     return c;
// }
//
// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {
//     vec2 uv = fragCoord.xy / iResoltution.xy;
//     uv -= .5;
//     uv.x *= iResolution.x/iResolution.y;
//     vec3 col = vec3(0.);
//     float mask = Circle(uv, vec2(0), .4, .05);
//     mask -= Circle(uv, vec2(-.13,.2),.07, .01);
//     mask -= Circle(uv, vec2(.13,.2),.07, .01);
//     float mouth = Circle(uv, vec2(0.,0.), .3, .02);
//     mouth -= Circle(uv, vec2(0.,.1), .3, .02);
//     mask -= mouth;
//     col = vec3(1.,1.,0)*mask;
//     fragColor = vec4(vec3(c),1.0);
// }

using namespace metal;

float Circle(float2 uv, float2 p, float r, float blur)
{
    float d = length(uv - p);
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
    
    // make a yellow circle with two holes (eyes)
    float3 col = float3(0.);
    float mask = Circle(uv, float2(0), .4, .05);
    mask -= Circle(uv, float2(-.13,.2),.07, .01);
    mask -= Circle(uv, float2(.13,.2),.07, .01);
    
    // subtract the mouth from the mask
    float mouth = Circle(uv, float2(0.,0.), .3, .02);
    mouth -= Circle(uv, float2(0.,.1), .3, .02);
    
    // use max to avoid negative colors and remove the weird effect
    // near the eyes (thanks to ocdy1001)
    mask -= max(mouth,0.);
    
    // return the "fragColor" by multiplying yellow by the circle mask
    col = float3(1.,1.,0.) * mask;
    output.write(float4(col, 1), gid);
}
