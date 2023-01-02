
#include "../shader_configuration.h"

#define STANDART_FOR_OUTER_MESH	
#define USE_GAMMA_CORRECTED_TERRAIN_COLORMAPS
#define USE_TERRAIN_GET_HEIGHT_FOR_PARALLAX

#include "definitions.rsh"

#include "terrain_header_data.rsh"

#include "terrain_vertex_functions.rsh"
#include "terrain_pixel_functions.rsh"
#include "standart.rsh"
#include "outer_mesh.rsh"


VS_OUTPUT_STANDART main_vs(RGL_VS_INPUT In)
{
	return main_vs_outer_mesh(In);
}

DEFINE_STANDART_DISPLACEMENT_SHADERS

PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_STANDART In)
{
	return ps_outer_mesh_gbuffer(In);
}
