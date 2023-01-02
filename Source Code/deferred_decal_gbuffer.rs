#define my_material_id GBUFFER_MATERIAL_NONE

#define Vertex_shader_output_type VS_OUTPUT_DEFERRED_DECAL

#define Pixel_shader_input_type VS_OUTPUT_DEFERRED_DECAL

#include "shared_functions.rsh"
#include "deferred_decal.rsh"



VS_OUTPUT_DEFERRED_DECAL main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_DEFERRED_DECAL output = (VS_OUTPUT_DEFERRED_DECAL)0;
	return output;//deferred_decal_vs(In); 
}

PS_OUTPUT_DECAL main_ps(VS_OUTPUT_DEFERRED_DECAL In)
{	
	PS_OUTPUT_DECAL output = (PS_OUTPUT_DECAL)0;
	return output;//deferred_decal_gbuffer_ps(In);
}
