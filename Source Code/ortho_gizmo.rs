#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_FONT, Out);

	float2 scale_factor = 48 / g_application_viewport_size.xy;
	float2 aspect = float2(g_application_viewport_size.x / g_application_viewport_size.y, 1.0);
	aspect = aspect;
	float4x4 ortho_mat = float4x4(
		1.0f/(2*aspect.x), 0, 0, 0,
		0, 1.0f/(2*aspect.y), 0, 0,
		0, 0, 0.5, 1,
		0, 0, 0, 1);

	In.position *= 0.16;
	//In.position += -get_row(g_view, 2) * 10;

	float3x3 _TBN = create_float3x3(get_row(to_float3x3(g_view), 0), get_row(to_float3x3(g_view), 1), get_row(to_float3x3(g_view), 2));
	
	Out.Pos = float4(mul(_TBN, In.position.xyz), 0);
	Out.Pos = mul(ortho_mat, float4(Out.Pos.xyz, 1));
	//Out.Pos = mul(g_proj, float4(Out.Pos.xyz, 1));

	Out.Pos.xy -= (1 - (48 * g_application_halfpixel_viewport_size_inv.zw * 2));
	Out.Pos.z = 0;

	Out.Tex0 = In.tex_coord;
	Out.Color = get_vertex_color(In.color) * g_mesh_factor_color;
	return Out;
}

PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	PS_OUTPUT Output;
	Output.RGBColor = In.Color;
	return Output;// main_ps_no_shadow(In);
}
