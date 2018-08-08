//
//  Shaders.metal
//  Smiley
//
//  Created by João Varela on 05/08/2018.
//
//  "Smiley Tutorial" by Martijn Steinrucken aka BigWings - Copyright, 2017-2018
//  License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unsupported License.
//  Email:countfrolic@gmail.com Twitter:@The_ArtOfCode
//
//  Adapted to Metal shader language by J. Varela
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"

using namespace metal;

// macros
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

float4 Brow(float2 uv)
{
    // save the original y-coordinate for later
    float y = uv.y;
    // skew the brows down
    uv.y += uv.x*.8-.3;
    // pull the brows apart
    uv.x -= .1;
    uv -= .5;
    
    float4 col = float4(0.);
    float blur = .1;
    
    // make the brows out of two circles
    // circle #1
    float d1 = length(uv);
    float s1 = S(.45, .45-blur, d1);
    // circle #2 which is offset from circle #1
    float d2 = length(uv-float2(.1, -.2)*.7);
    float s2 = S(.5,.5-blur,d2);
    // subtract circle #2 from circle #1
    float browMask = sat(s1-s2);
    
    float colMask = remap01(.7, .8, y)*.75;
    // remove the top highlight from the gradient below
    colMask *= S(.6,.9, browMask);
    // make a brown gradient
    float4 browCol = mix(float4(.4,.2,.2,1.), float4(1.,.75, .5, 1.), colMask);
    
    // make shadows beneath the brows
    // move the shadows up
    uv.y += .15;
    // add blur to the shadows
    blur += .1;
    // circle #1
    d1 = length(uv);
    s1 = S(.45, .45-blur, d1);
    // circle #2 which is offset from circle #1
    d2 = length(uv-float2(.1,-.2)*.7);
    s2 = S(.5,.5-blur, d2);
    // subtract circle #2 from circle #1
    float shadowMask = sat(s1-s2);
    // blend
    col = mix(col, float4(0.,0.,0.,1.), S(.0,1.,shadowMask)*.5);
    col = mix(col, browCol, S(.2,.4, browMask));
    return col;
}

float4 Eye(float2 uv, float side, float2 m)
{
    // remap the coordinates to center at 0.
    uv -= .5;
    
    // calculate the distance without the mouse input before
    // the unmirroring of the coordinates to prevent a tear
    float d = length(uv);
    
    // prevent mirroring of the eyes
    uv.x *= side;
    
    // set the iris color (baby blue)
    float4 irisCol = float4(.3,.5,1.,1.);
    // blend the white and the iris colors and attenuate the latter by half
    float4 col = mix(float4(1.), irisCol, S(.1,.7,d)*.5);
    col.a = S(.5, .48, d);
    // shadow, attenuated, and only at the inner bottom
    // sat() avoids negative highlight colors
    col.rgb *= 1. - S(.45, .5, d) * .5 * sat(-uv.y-uv.x*side);
    // calculate the distance with the mouse coordinates
    d = length(uv-m*.5);
    // make the outline of the iris
    col.rgb = mix(col.rgb, float3(0.), S(.3, .28, d));
    // make the iris color less flat
    irisCol.rgb *= 1. + S(.3,.05, d);
    // make the iris, making a slightly smaller circle
    float irisMask = S(.28, .25, d);
    col.rgb = mix(col.rgb, irisCol.rgb, irisMask);
    // make the pupil, giving it a slightly higher freedom to move
    // to give the eye a more 3D look
    d = length(uv-m*.6);
    col.rgb = mix(col.rgb, float3(.0), S(.16, .14, d));
    // highlight mask
    float highlight = S(.1, .09, length(uv-float2(-.15,.15)));
    highlight += S(.07, .05, length(uv+float2(-.08,.08)));
    // blend the highlight using white
    col.rgb = mix(col.rgb, float3(1.), highlight);
    return col;
}

float4 Mouth(float2 uv)
{
    // normalize coordinates
    uv -= .5;
    // dark red color for the mouth
    float4 col = float4(.5, .18, .05, 1.);
    // scale the mouth down
    uv.y *= 1.5;
    // pull the mouth corners up
    uv.y -= uv.x * uv.x * 2;
    // blur the edge of the mouth
    float d = length(uv);
    col.a = S(.5, .48, d);
    // teeth
    float td = length(uv-float2(0., .6));
    // blend with white and add drop shadow
    float3 toothCol = float3(1.)*S(.6, .35, d);
    col.rgb = mix(col.rgb, toothCol, S(.4,.37,td));
    // make tongue
    td = length(uv+float2(0., .5));
    // blend with tongue color and carve it out with smoothstep
    col.rgb = mix(col.rgb, float3(1., .5, .5), S(.5, .2, td));
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
    // use the highlight to show the eye sockets
    highlight *= S(.18, .19, length(uv-float2(.21, .08)));
    // blend with the white color of the highlight
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

float4 Smiley(float2 uv, float2 m)
{
    float4 col = float4(0.);
    
    // use side to prevent the mirroring of the eyes
    float side = sign(uv.x);
    // mirror the left with the right side for the rest
    uv.x = abs(uv.x);
    float4 head = Head(uv);
    
    // make and place the eyes
    float4 eye = Eye(within(uv, float4(.03, -.1, .37, .25)), side, m);
    // make and place the mouth (use the rect (float4) to make it oval)
    float4 mouth = Mouth(within(uv, float4(-.3, -.4, .3, -.1)));
    // make the brows
    float4 brow = Brow(within(uv, float4(.03, .2, .4, .45)));
    
    // blend everything
    col = mix(col, head, head.a);
    col = mix(col, eye, eye.a);
    col = mix(col, mouth, mouth.a);
    col = mix(col, brow, brow.a);
    return col;
}

kernel void compute(texture2d<float,access::write> output [[texture(0)]],
                    constant float4 &input [[buffer(0)]],
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
    uv -= 0.5;  // -0.5 <> 0.5
    uv.x *= iResolution.x/iResolution.y;
    
    // normalized mouse input
    float2 m = input.xy / iResolution;
    // normalize the mouse input
    m -= .5;
    
    // apply the smiley onto the screen texture
    float4 col = Smiley(uv, m);
    output.write(col, gid);
}
