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
// void mainImage( out vec4 fragColor, in vec2 fragCoord )
// {
//     vec2 uv = fragCoord.xy / iResoltution.xy
//     fragColor = vec4(uv, 0.5+0.5*sin(iGlobaltime),1.0)
// }

using namespace metal;

kernel void compute(texture2d<float,access::write> output [[texture(0)]],
                    constant float4 &time [[buffer(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
    // get the width and height of the screen texture
    int width = output.get_width();
    int height = output.get_height();
    
    // set its resolution
    float2 iResolution = float2(width, height);
    
    // compute the texture coordinates with the y-coordinate flipped
    // because the origin of Shadertoy's and Metal's y-coordinates differ
    float2 uv = float2(gid.x,height - gid.y) / iResolution;
    
    // return the "fragColor" by using the w element of the float4 used for time
    output.write(float4(uv,0.5+0.5*sin(time.w), 1.0), gid);
}
