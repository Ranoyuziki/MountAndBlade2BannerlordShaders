
#include "../shader_configuration.h"

#include "definitions.rsh"

struct VS_OUTPUT_FLORA_INSTANCED
{
	float4 Pos				: RGL_POSITION;
	
	float4 Color			: COLOR0;
	float2 Tex0				: TEXCOORD0;
	float4 SunLight			: TEXCOORD1;
	float4 shadow_tex_coord	: TEXCOORD2;
};

VS_OUTPUT_FLORA_INSTANCED vs_flora_Instanced(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_FLORA_INSTANCED, Out);

	float4x4 worldOfInstance = build_instance_frame_matrix(In.instance_data_0, In.instance_data_1, In.instance_data_2, In.instance_data_3);

	float4 world_position = mul(worldOfInstance, float4(In.position));
	Out.Pos = mul(g_view_proj, world_position);

	Out.Tex0 = In.tex_coord;
	//   Out.Color = vColor * g_mesh_factor_color;
	Out.Color = get_vertex_color(In.color) * (g_ambient_color + g_sun_color * 0.06f); //add some sun color to simulate sun passing through leaves.
	Out.Color.a *= g_mesh_factor_color.a;

	//   Out.Color = vColor * g_mesh_factor_color * (g_ambient_color + g_sun_color * 0.15f);
	//shadow mapping variables
	Out.SunLight = (g_sun_color * 0.34f)* g_mesh_factor_color * In.color;

	float4 ShadowPos = mul(g_sun_view_proj, world_position);
	Out.shadow_tex_coord = ShadowPos;
	Out.shadow_tex_coord.z /= ShadowPos.w;

	Out.shadow_tex_coord.w = length(g_camera_position.xyz - world_position.xyz);

	return Out;
}

PS_OUTPUT ps_flora(VS_OUTPUT_FLORA_INSTANCED In) 
{ 
	PS_OUTPUT Output;
	float4 tex_col = sample_diffuse_texture(linear_sampler, In.Tex0);
	clip(tex_col.a - 0.05f);
	
	INPUT_TEX_GAMMA(tex_col.rgb);


	float sun_amount = sample_static_shadow(In.shadow_tex_coord, false, false);
	Output.RGBColor =  tex_col * ((In.Color + In.SunLight * sun_amount));

	apply_simple_fog(Output.RGBColor.rgb, In.shadow_tex_coord.w);

	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	
	
	return Output;
}

// DEFINE_TECHNIQUES(flora_Instanced, vs_flora_Instanced, ps_flora)

VS_OUTPUT_FLORA_INSTANCED main_vs(RGL_VS_INPUT In)
{
	return vs_flora_Instanced(In);
}

PS_OUTPUT main_ps(VS_OUTPUT_FLORA_INSTANCED In)
{
	return ps_flora(In);
}
