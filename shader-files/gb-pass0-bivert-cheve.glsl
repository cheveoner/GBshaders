///////////////////////////////////////////////////////////////////////////
//                                                                       //
// Gameboy Classic Shader v0.2.2                                         //
//                                                                       //
// Copyright (C) 2013 Harlequin : unknown92835@gmail.com                 //
//                                                                       //
// This program is free software: you can redistribute it and/or modify  //
// it under the terms of the GNU General Public License as published by  //
// the Free Software Foundation, either version 3 of the License, or     //
// (at your option) any later version.                                   //
//                                                                       //
// This program is distributed in the hope that it will be useful,       //
// but WITHOUT ANY WARRANTY; without even the implied warranty of        //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         //
// GNU General Public License for more details.                          //
//                                                                       //
// You should have received a copy of the GNU General Public License     //
// along with this program.  If not, see <http://www.gnu.org/licenses/>. //
//                                                                       //
///////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Config                                                                     //
////////////////////////////////////////////////////////////////////////////////

// The alpha value of dots in their "off" state
// Does not affect the border region of the screen - [0, 1]
#pragma parameter baseline_alpha "Baseline Alpha" 0.05 0.0 1.0 0.01

// Fine-tune the balance between the different shades of grey
#pragma parameter grey_balance "Grey Balance" 0.67 0.67 1.33 0.1   // original 2.6 2.0 4.0 0.1 divided by 3

// Simulate response time
// Higher values result in longer color transition periods - [0, 1]
#pragma parameter response_time "LCD Response Time" 0.20 0.0 0.777 0.111

// Set video scale when used in console-border shaders
#pragma parameter video_scale "Video Scale" 3.0 2.0 6.0 1.0 // it must be an integer number

#pragma parameter grid_alpha "Grid Alpha" 1.0 0.0 1.0 0.1

#if defined(VERTEX)
////////////////////////////////////////////////////////////////////////////////
// Vertex shader                                                              //
////////////////////////////////////////////////////////////////////////////////

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
COMPAT_VARYING vec2 dot_size;
COMPAT_VARYING vec2 one_texel;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform COMPAT_PRECISION vec2 InputSize;

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float video_scale;
#else
#define video_scale 3.0
#endif

////////////////////////////////////////////////////////////////////////////////
// Vertex definitions                                                         //
////////////////////////////////////////////////////////////////////////////////

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

// Largest integer scale of input video that will fit in the current output (y axis would typically be limiting on widescreens)
//#define video_scale         floor(outsize.y * SourceSize.w) <- moved to parameter

// Size of the scaled video
//#define scaled_video_out    (SourceSize.xy * vec2(video_scale)) <- moved to parameter 

//it's... half a pixel
#define half_pixel          (vec2(0.5) * outsize.zw)   

void main()
{
	vec2 scaled_video_out = (InputSize.xy * vec2(video_scale));
    // Remaps position to integer scaled output
    gl_Position = MVPMatrix * VertexCoord / vec4( vec2(outsize.xy / scaled_video_out), 1.0, 1.0 );
    TEX0.xy = TexCoord.xy + half_pixel;
    dot_size = SourceSize.zw;
    one_texel = 1.0 / (SourceSize.xy * video_scale);
}

#elif defined(FRAGMENT)
////////////////////////////////////////////////////////////////////////////////
// Fragment shader                                                            //
////////////////////////////////////////////////////////////////////////////////

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

// #define MORE_FRAMES // to use extra frames for ghosting

uniform COMPAT_PRECISION vec2 OutputSize;
uniform COMPAT_PRECISION vec2 TextureSize;
uniform sampler2D Texture;
uniform sampler2D COLOR_PALETTE;
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
COMPAT_VARYING vec2 dot_size;
COMPAT_VARYING vec2 one_texel;

// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize
#define outsize vec4(OutputSize, 1.0 / OutputSize)

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float baseline_alpha;
uniform COMPAT_PRECISION float grey_balance;
uniform COMPAT_PRECISION float response_time;
uniform COMPAT_PRECISION float grid_alpha;
#endif

////////////////////////////////////////////////////////////////////////////////
//fragment definitions                                                        //
////////////////////////////////////////////////////////////////////////////////

//#define DEBUG

#define foreground_color COMPAT_TEXTURE(COLOR_PALETTE, vec2(0.75, 0.5)).rgb                 //hardcoded to look up the foreground color from the right half of the palette image

// Frame sampling definitions
#define curr_rgb  abs(1.0 - COMPAT_TEXTURE(Source,       vTexCoord).rgb)
#define prev0_rgb abs(1.0 - COMPAT_TEXTURE(PrevTexture,  vTexCoord).rgb)
#define prev1_rgb abs(1.0 - COMPAT_TEXTURE(Prev1Texture, vTexCoord).rgb)
#define prev2_rgb abs(1.0 - COMPAT_TEXTURE(Prev2Texture, vTexCoord).rgb)
#ifdef MORE_FRAMES
#define prev3_rgb abs(1.0 - COMPAT_TEXTURE(Prev3Texture, vTexCoord).rgb)
#define prev4_rgb abs(1.0 - COMPAT_TEXTURE(Prev4Texture, vTexCoord).rgb)
#define prev5_rgb abs(1.0 - COMPAT_TEXTURE(Prev5Texture, vTexCoord).rgb)
#define prev6_rgb abs(1.0 - COMPAT_TEXTURE(Prev6Texture, vTexCoord).rgb)
#endif

void main()
{
    // Determine if the corrent texel lies on a dot or in the space between dots
	float is_on_dot = float(mod(vTexCoord.x, dot_size.x) > one_texel.x &&
	                        mod(vTexCoord.y, dot_size.y * 1.0001) > one_texel.y);

    // Sample color from the current and previous frames, apply response time modifier
    // Response time effect implmented through an exponential dropoff algorithm
    float rt  = response_time;
	float rt2 = rt * rt;
	float rt3 = rt * rt2;
	// Cheve: Do not need that many textures for low response times
	//float rt4 = rt * rt3;
	//float rt5 = rt * rt4;
	//float rt6 = rt * rt5;
	//float rt7 = rt * rt6;
	
	vec3 input_rgb = curr_rgb;
    input_rgb += (prev0_rgb - input_rgb) * rt;
    input_rgb += (prev1_rgb - input_rgb) * rt2;
    input_rgb += (prev2_rgb - input_rgb) * rt3;
	// Cheve: Do not need that many textures for low response times
	#ifdef MORE_FRAMES
    input_rgb += (prev3_rgb - input_rgb) * rt4;
    input_rgb += (prev4_rgb - input_rgb) * rt5;
    input_rgb += (prev5_rgb - input_rgb) * rt6;
    input_rgb += (prev6_rgb - input_rgb) * rt7;
	#endif

	float rgb_to_alpha = input_rgb.r/grey_balance + is_on_dot*baseline_alpha;

    // Apply foreground color and assign alpha value
    // Apply the foreground color to all texels -
    // the color will be modified by alpha later - and assign alpha based on rgb input
    vec4 out_color = vec4(foreground_color, rgb_to_alpha);
    
    // Overlay the matrix
    // If the fragment is not on a dot, set its alpha value to 0
	out_color.a = is_on_dot*out_color.a + max(1.0-is_on_dot, 0.0)*grid_alpha;
	
	#ifdef DEBUG
	out_color = vec4(foreground_color * rgb_to_alpha * is_on_dot, 1.0);
	#endif

    FragColor = out_color;
} 
#endif
