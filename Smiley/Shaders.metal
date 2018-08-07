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

float Circle(float2 uv, float2 p, float r, float blur)
{
    float d = length(uv - p);
    float c = smoothstep(r, r - blur, d);
    return c;
}

float Smiley(float2 uv, float2 p, float size)
{
    // remap the coordinates to move smiley around
    uv -= p;
    
    // scale the smiley by resizing the coordinate system
    uv /= size;
    
    // make the smiley shape
    float mask = Circle(uv, float2(0.), .4, .05);
    
    // make the eyes (holes)
    mask -= Circle(uv, float2(-.13,.2),.07, .01);
    mask -= Circle(uv, float2(.13,.2),.07, .01);
    
    // make the mouth
    float mouth = Circle(uv, float2(0.,0.), .3, .02);
    mouth -= Circle(uv, float2(0.,.1), .3, .02);
    
    // use max to avoid negative colors and remove the weird effect
    // near the eyes (thanks to ocdy1001)
    mask -= max(mouth,0.);
    return mask;
}

 float Band(float t, float start, float end, float blur)
 {
     float step1 = smoothstep(start-blur, start+blur, t);
     float step2 = smoothstep(end+blur, end-blur, t);
     return step1 * step2;
 }

 float Rect(float2 uv, float left, float right, float bottom, float top, float blur)
 {
     float band1 = Band(uv.x, left, right, blur);
     float band2 = Band(uv.y, bottom, top, blur);
     return band1 * band2;
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
    
    // don't make a smiley
    // float mask = Smiley(uv, float2(0.,0.), .5);
    // instead make a wave
    float x = uv.x;
    float m = (x-.5)*(x+.5);
    float y = uv.y+m;
    // tapered at the top
    
    float mask = Rect(float2(x,y), -.5, .5, -.1, .1, .01);
    
    // return the "fragColor" by multiplying white by the gradient mask
    float3 col = float3(1.,1.,1.) * mask;
    output.write(float4(col, 1), gid);
}
