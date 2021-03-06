/*
    Response Time
    Based on the response time function from Harlequin's Game Boy and LCD shaders
 
    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
*/

#pragma parameter response_time "LCD Response Time" 0.333 0.0 0.777 0.111

#if defined(VERTEX)

#if __VERSION__ >= 130
#define COMPAT_VARYING out
#define COMPAT_ATTRIBUTE in
#define COMPAT_TEXTURE texture
#else
#define COMPAT_VARYING varying 
#define COMPAT_ATTRIBUTE attribute 
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

COMPAT_ATTRIBUTE vec4 VertexCoord;
COMPAT_ATTRIBUTE vec4 TexCoord;
COMPAT_VARYING vec4 TEX0;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;

// compatibility #defines
#define vTexCoord TEX0.xy
#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

// Vertex Shader

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
}

#elif defined(FRAGMENT)

#if __VERSION__ >= 130
#define COMPAT_VARYING in
#define COMPAT_TEXTURE texture
out vec4 FragColor;
#else
#define COMPAT_VARYING varying
#define FragColor gl_FragColor
#define COMPAT_TEXTURE texture2D
#endif

#ifdef GL_ES
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif
#define COMPAT_PRECISION mediump
#else
#define COMPAT_PRECISION
#endif

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform sampler2D Texture;
uniform sampler2D PrevTexture;
uniform sampler2D Prev1Texture;
uniform sampler2D Prev2Texture;
#ifdef MORE_FRAMES
uniform sampler2D Prev3Texture;
uniform sampler2D Prev4Texture;
uniform sampler2D Prev5Texture;
uniform sampler2D Prev6Texture;
#endif
COMPAT_VARYING vec4 TEX0;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define OutSize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float response_time;
#else
#define response_time 0.333   //simulate response time, higher values result in longer color transition periods - [0, 1]
#endif

// Frame sampling definitions
#define curr_rgb  COMPAT_TEXTURE(Source,       vTexCoord).rgb
#define prev0_rgb COMPAT_TEXTURE(PrevTexture,  vTexCoord).rgb
#define prev1_rgb COMPAT_TEXTURE(Prev1Texture, vTexCoord).rgb
#define prev2_rgb COMPAT_TEXTURE(Prev2Texture, vTexCoord).rgb
#ifdef MORE_FRAMES
#define prev3_rgb COMPAT_TEXTURE(Prev3Texture, vTexCoord).rgb
#define prev4_rgb COMPAT_TEXTURE(Prev4Texture, vTexCoord).rgb
#define prev5_rgb COMPAT_TEXTURE(Prev5Texture, vTexCoord).rgb
#define prev6_rgb COMPAT_TEXTURE(Prev6Texture, vTexCoord).rgb
#endif


// Fragment Shader

void main()
{
    // Sample color from the current and previous frames, apply response time modifier
    // Response time effect implemented through an exponential dropoff algorithm
    vec3 input_rgb = curr_rgb;
	
	float rt = response_time;
	float rt2 = rt * rt;
	float rt3 = rt * rt2;
    input_rgb += (prev0_rgb - input_rgb) * rt;
    input_rgb += (prev1_rgb - input_rgb) * rt2;
    input_rgb += (prev2_rgb - input_rgb) * rt3;
	
	#ifdef MORE_FRAMES
	float rt4 = rt * rt3;
	float rt5 = rt * rt4;
	float rt6 = rt * rt5;
	float rt7 = rt * rt6;
    input_rgb += (prev3_rgb - input_rgb) * rt4;
    input_rgb += (prev4_rgb - input_rgb) * rt5;
    input_rgb += (prev5_rgb - input_rgb) * rt6;
    input_rgb += (prev6_rgb - input_rgb) * rt7;
	#endif

    FragColor = vec4(input_rgb, 0.0);
} 
#endif
