
#include "../shader_configuration.h"


#include "definitions.rsh"
#include "shared_functions.rsh"
#include "flora.rsh"

VS_OUTPUT_FLORA main_vs(RGL_VS_INPUT input)
{
	deform_tree_bark(input.position.xyz,get_vertex_color(input.color));
	
	return vs_flora_gbuffer(input);
}

PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_FLORA input)
{
	return ps_flora_gbuffer(input);
}


