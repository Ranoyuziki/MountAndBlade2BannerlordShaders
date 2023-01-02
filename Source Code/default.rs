
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "default.rsh"

#if VERTEX_SHADER

VS_OUTPUT_STANDART main_vs(RGL_VS_INPUT input)
{
    return default_vs(input);
}

#endif	

#if PIXEL_SHADER

float4 main_ps(VS_OUTPUT_STANDART input) : RGL_COLOR0
{
    return default_ps(input);
}

#endif		
