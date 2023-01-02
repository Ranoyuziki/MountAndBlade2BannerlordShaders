
#include "../shader_configuration.h"


#include "definitions.rsh"
#include "flora.rsh"

VS_OUTPUT_FLORA main_vs(RGL_VS_INPUT input)
{
#if ALIGNMENT_DEFORMATION
	deform_palm_leaf(input.position.xyz, get_vertex_color(input.color));
#else
	deform_tree_leaf(input, input.position.xyz, get_vertex_color(input.color));
#endif
	return vs_flora_gbuffer(input);
}

PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_FLORA input)
{
	return ps_flora_gbuffer(input);
}

