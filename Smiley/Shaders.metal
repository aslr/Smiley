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
    return sat(((t-a)/(b-a) * (d-c) + c));
}

// remap in 2D
float2 within(float2 uv, float4 rect)
{
    return (uv-rect.xy)/(rect.zw-rect.xy);
}

float4 Eye(float2 uv)
{
    // remap the coordinates to center at 0.
    uv -= .5;
    float d = length(uv);
    // set the white color of the eyes
    float4 white = float4(1.);
    // set the iris color (baby blue)
    float4 irisCol = float4(.3,.5,1.,1.);
    // blend the white and the iris colors and attenuate the latter by half
    float4 col = mix(white, irisCol, S(.1,.7,d)*.5);
    // shadow, attenuated, and only at the inner bottom 
    // sat() avoids negative highlight colors
    col.rgb *= 1. - S(.45, .5, d) * .5*sat(-uv.y-uv.x);
    // make the outline of the iris
    col.rgb = mix(col.rgb, float3(0.), S(.3, .28, d));
    // make the iris color less flat
    irisCol.rgb *= 1. + S(.3,.05, d);
    // make the iris, making a slightly smaller circle
    col.rgb = mix(col.rgb, irisCol.rgb, S(.28, .25, d));
    // make the pupil
    col.rgb = mix(col.rgb, float3(.0), S(.16, .14, d));
    // make the white of the eye
    col.a = S(.5, .48, d);
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
    
    // make highlight
    float highlight = S(.41, .405, d);
    
    // start at the top (.41) and end at past the middle (-.1)
    // make brightness = 0.75 at the top and 0. at -.1
    // use uv.y because the gradient is across the y-coordinate
    highlight *= remap(.41, -.1, .75, .0, uv.y);
    col.rgb = mix(col.rgb, float3(1.), highlight);
    
    // position of one cheek
    d = length(uv-float2(.25,-.2));
    // make it into a circle and attenuate it by 60%
    // and make the edge softer
    float cheek = S(.2,.01, d) * .4;
    
    // make the edge sharper
    cheek *= S(.17, .16, d);
    
    // blend the background with a reddish color
    col.rgb = mix(col.rgb, float3(1., .1, .1), cheek);
    return col;
}

float4 Smiley(float2 uv)
{
    float4 col = float4(0.);
    
    // mirror the left with the right side, so that the cheeks are mirrored
    uv.x = abs(uv.x);
    float4 head = Head(uv);
    
    // make and place the eyes
    float4 eye = Eye(within(uv, float4(.03, -.1, .37, .25)));
    
    // blend everything
    col = mix(col, head, head.a);
    col = mix(col, eye, eye.a);
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
