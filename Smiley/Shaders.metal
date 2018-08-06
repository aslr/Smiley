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

float dist(float2 point, float2 center, float radius)
{
    return length(point - center) - radius;
}

kernel void compute(texture2d<float,
                    access::write> output [[texture(0)]],
                    uint2 gid [[thread_position_in_grid]])
{
    int width = output.get_width();
    int height = output.get_height();
    float red = float(gid.x) / float(width);
    float green = float(gid.y) / float(height);
    float2 uv = float2(gid) / float2(width, height);
    uv = uv * 2.0 - 1.0;                                // position of the circle
    float distanceToCircle = dist(uv, float2(0), 0.5);  // distance from the circle based on the diameter of it
    bool inside = distanceToCircle < 0;
    output.write(inside ? float4(0) : float4(red, green, 0, 1), gid);
}
