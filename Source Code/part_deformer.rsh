#ifndef PART_DEFORMER_RSH
#define PART_DEFORMER_RSH

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"

#ifdef PIXEL_SHADER
void strap_deformer(Pixel_shader_input_type In)
{
	float strap_hidden = g_mesh_vector_argument.x;
	//float strap_hidden = 1.0f;

	if(strap_hidden > 0 && In.vertex_color.g > 0.5)
	{
		clip(-1);
	}
}

void strap_deformer_delegate(inout Pixel_shader_input_type In)
{
	strap_deformer(In);
	float ambient_multiplier = In.vertex_color.r;
	In.vertex_color.rgb = float3(ambient_multiplier,ambient_multiplier,ambient_multiplier);
	In.vertex_color.a = 1;
}
#endif

#endif
