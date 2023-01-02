
#define USE_ADVANCED_FLORA_SHADING

#include "../shader_configuration.h"


#include "definitions.rsh"
#include "grass.rsh"

VS_OUT_FLORA_GBUFFER main_vs(RGL_VS_INPUT input)
{
	return vs_grass_gbuffer(input);
}

PS_OUTPUT_GBUFFER main_ps(VS_OUT_FLORA_GBUFFER input)
{
	return ps_grass_gbuffer(input);
}

