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

// Useful to fine-tune the colors.
// Higher values make the "black" color closer to black - [0, 1] [DEFAULT: 0.95]
#pragma parameter contrast "Contrast" 1.0 0.0 1.0 0.05

// Controls the ambient light of the screen. 
// Lower values darken the screen - [0, 2] [DEFAULT: 1.00]
#pragma parameter screen_light "Ambient Screen Light" 1.75 0.0 2.0 0.05

// Controls the opacity of the dot-matrix pixels. 
// Lower values make pixels more transparent - [0, 1] [DEFAULT: 1.00]
#pragma parameter pixel_opacity "Pixel Opacity" 1.0 0.01 1.0 0.01

// Screen offset - [-infinity, infinity] [DEFAULT: 0]
#pragma parameter screen_offset_x "Screen Offset Horiz" 0.0 -5.0 5.0 0.5

// Screen offset - [-infinity, infinity] [DEFAULT: 0]
#pragma parameter screen_offset_y "Screen Offset Vert" 0.0 -5.0 5.0 0.5   

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
COMPAT_VARYING vec2 texel;

uniform mat4 MVPMatrix;
uniform COMPAT_PRECISION vec2 TextureSize;

#define SourceSize vec4(TextureSize, 1.0 / TextureSize) //either TextureSize or InputSize

void main()
{
    gl_Position = MVPMatrix * VertexCoord;
    TEX0.xy = TexCoord.xy;
    texel = SourceSize.zw;
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

uniform sampler2D Texture;
uniform sampler2D BACKGROUND;
uniform sampler2D COLOR_PALETTE;
COMPAT_VARYING vec4 TEX0;
COMPAT_VARYING vec2 texel;

////////////////////////////////////////////////////////////////////////////////
// Fragment definitions                                                       //
////////////////////////////////////////////////////////////////////////////////
// compatibility #defines
#define Source Texture
#define vTexCoord TEX0.xy

#ifdef PARAMETER_UNIFORM
// All parameter floats need to have COMPAT_PRECISION in front of them
uniform COMPAT_PRECISION float contrast;
uniform COMPAT_PRECISION float screen_light;
uniform COMPAT_PRECISION float pixel_opacity;
uniform COMPAT_PRECISION float screen_offset_x;
uniform COMPAT_PRECISION float screen_offset_y;
#else
#define contrast 0.95
#define screen_light 1.0
#define pixel_opacity 1.0
#define screen_offset_x 0.0
#define screen_offset_y 0.0
#endif

#define bg_color COMPAT_TEXTURE(COLOR_PALETTE, vec2(0.25, 0.5)) 

// Offset for the entire screen
#define screen_offset vec2(screen_offset_x * texel.x, screen_offset_y * texel.y) 

void main()
{
    vec2 tex = vTexCoord.xy;
    
    // Sample all the relevant textures
    vec4 foreground = COMPAT_TEXTURE(Source, tex - screen_offset);
    vec4 background = COMPAT_TEXTURE(BACKGROUND, vTexCoord);
    vec4 background_color = bg_color;
	
    // Allows for highlights,
    // background = bg_color when the background color is 0.5 gray
    background.rgb = clamp(
        vec3( 
            background_color.r + mix(-1.0, 1.0, background.r), 
            background_color.g + mix(-1.0, 1.0, background.g), 
            background_color.b + mix(-1.0, 1.0, background.b)
        ), 
        0.0, 1.0);
	
	
    // Shadows are alpha blended with the background
	vec4 out_color = background;  
	
	// Foreground is alpha blended with the shadowed background
    out_color = foreground.a * (foreground * (1.0 - foreground.a * contrast)) + 
		        (out_color * (screen_light - foreground.a * contrast * pixel_opacity));
	
	
	
	
    FragColor = out_color;
} 
#endif
