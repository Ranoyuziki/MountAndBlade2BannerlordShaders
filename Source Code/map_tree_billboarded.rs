
#include "../shader_configuration.h"

// #define VERTEX_DECLARATION VDECL_REGULAR

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "map_tree_billboarded.rsh"


VS_OUTPUT_STANDART main_vs(RGL_VS_INPUT In)
{
	return vs_map_tree(In);
}
	
PS_OUTPUT main_ps(VS_OUTPUT_STANDART In)
{
	return ps_map_tree(In);
}
