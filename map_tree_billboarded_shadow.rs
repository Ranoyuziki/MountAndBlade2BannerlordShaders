
#include "../shader_configuration.h"

// #define VERTEX_DECLARATION VDECL_REGULAR

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "shadow.rsh"
#include "map_tree_billboarded.rsh"


VS_OUTPUT_SHADOWMAP main_vs(RGL_VS_INPUT In)
{
	return vs_grass_shadow(In);
}
	
PS_OUTPUT main_ps(VS_OUTPUT_SHADOWMAP In)
{
	return main_ps_shadow(In);
}
