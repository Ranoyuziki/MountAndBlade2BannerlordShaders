
#define DecalDiffuseMap	texture7
#define DecalNormalMap	texture8
#define DecalSpecularMap	texture9

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "shared_vertex_functions.rsh"
#include "gbuffer_functions.rsh"

struct VS_OUTPUT_NOTEXTURE_GBUFFER
{
	float4 position		: RGL_POSITION;
	float4 color		: COLOR0;
	float4 world_space_pos	: TEXCOORD0;
	float3 world_normal	: TEXCOORD1;
};

VS_OUTPUT_NOTEXTURE_GBUFFER main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_NOTEXTURE_GBUFFER Out;

	
	Out.world_space_pos = mul(g_world, float4(In.position, 1.0f));
	Out.position = mul(g_view_proj, Out.world_space_pos);

#if !(VERTEX_DECLARATION == VDECL_DEPTH_ONLY)
	Out.color = get_vertex_color(In.color) * g_mesh_factor_color;
	Out.world_normal = normalize(mul(to_float3x3(g_world), get_in_normal(In, normalize(In.qtangent))));
#endif

	return Out;
}

PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_NOTEXTURE_GBUFFER In)
{
	PS_OUTPUT_GBUFFER Out;

	float4 albedo = In.color;
	#ifdef USE_GAMMA_CORRECTED_GBUFFER_ALBEDO
	OUTPUT_GAMMA(albedo);
	#endif

	float3 norm = normalize(In.world_normal);
	
	set_gbuffer_values(Out, norm, 1, albedo.xyz, float2(0, 0), 1, norm, 0, 0);
	return Out;
}

