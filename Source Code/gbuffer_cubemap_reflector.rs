
#define DecalDiffuseMap	texture7
#define DecalNormalMap	texture8
#define DecalSpecularMap	texture9

#define Vertex_shader_output_type VS_OUTPUT_REFLECTOR

#include "flagDefs.rsh"
#include "definitions.rsh"
#include "shared_functions.rsh"

#include "gbuffer_functions.rsh"

//======================================================================================
// Vertex Shader
//======================================================================================

struct VS_OUTPUT_REFLECTOR
{
	float4 position					: RGL_POSITION	;	
	float3 object_normal			: TEXCOORD0		;
	
};



#if VERTEX_SHADER
VS_OUTPUT_REFLECTOR main_vs(RGL_VS_INPUT input)
{
    VS_OUTPUT_REFLECTOR output;

	float4 object_position, object_tangent;
	float3 object_normal, prev_object_position, object_color;
	
	rgl_vertex_transform(input, object_position, object_normal, object_tangent, prev_object_position, object_color);

	output.position = mul(g_view_proj, mul(g_world, object_position));	
	output.object_normal = object_normal;

	return output;
}
#endif


//======================================================================================
// Pixel Shader
//======================================================================================

#if PIXEL_SHADER
PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_REFLECTOR input)
{
	PS_OUTPUT_GBUFFER Output = (PS_OUTPUT_GBUFFER)0;

	float3 world_normal = input.object_normal.xyz;
	
	Output.gbuffer_normal_xy_dummy_alpha.xy = encodeNormal(world_normal);
	Output.gbuffer_vertex_normal_xy.xy = Output.gbuffer_normal_xy_dummy_alpha.xy;

	Output.gbuffer_albedo_thickness.xyz = 0;
	Output.gbuffer_spec_gloss_ao_shadow.xyzw = 0;
	
	Output.gbuffer_albedo_thickness.w = 0xFF;
    return Output;
}
#endif
