
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "definitions_samplers.rsh"

#include "modular_struct_definitions.rsh"
#include "definitions_texture_sample_helpers.rsh"

#define GBUFFER_PASS
#define Vertex_shader_output_type VS_OUT_GBUFFER_SKYBOX
#define Pixel_shader_input_type VS_OUT_GBUFFER_SKYBOX

#include "gbuffer_functions.rsh"
#include "motion_vector.rsh"

VS_OUTPUT_STANDART main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_STANDART, result);

	result.position = float4(In.position,1.0f);
	result.vertex_color = In.color;
	result.tex_coord = In.tex_coord;
	return result;
}

PS_OUTPUT main_ps(VS_OUTPUT_STANDART In)
{
	PS_OUTPUT Output;
	Output.RGBColor = sample_diffuse_texture(anisotropic_sampler, In.tex_coord) * In.vertex_color;
	return Output;
}

