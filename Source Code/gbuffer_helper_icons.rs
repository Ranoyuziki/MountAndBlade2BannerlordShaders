
#define GBUFFER_PASS

#include "modular_struct_definitions.rsh"

#define Vertex_shader_output_type VS_OUTPUT_HELPERICON
#define Pixel_shader_input_type VS_OUTPUT_HELPERICON

#include "definitions.rsh"
#include "definitions_samplers.rsh"
#include "gbuffer_functions.rsh"

#if VERTEX_SHADER
VS_OUTPUT_HELPERICON main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_HELPERICON Out = (VS_OUTPUT_HELPERICON)0;
	Out.position = float4(In.position, 1.0f);
	Out.vertex_color = In.color;
	Out.tex_coord = In.tex_coord;
	Out.world_position = 0.0f;
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_HELPERICON In)
{
	PS_OUTPUT_GBUFFER Output = (PS_OUTPUT_GBUFFER)0.0;

	float4 albedo = sample_diffuse_texture(linear_sampler, In.tex_coord);
	clip(albedo.a - 0.5);

	set_gbuffer_values(Output, float3(0, 0, 1), 1, albedo.xyz, float2(0, 0), 1, float3(0, 0, 1), 0, 0);
#if  SYSTEM_DRAW_ENTITY_IDS
	Output.entity_id.r = 0x7FFE;//float4(0, 1, 1, 0);
	Output.entity_id.g = 0;
#endif
	return Output;
}
#endif
