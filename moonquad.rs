
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
struct VS_OUTPUT_MOONQUAD
{
	float4	Position		:	RGL_POSITION;
	float2	Tex0			:	TEXCOORD0;
};

VS_OUTPUT_MOONQUAD main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_MOONQUAD Out;
	
	Out.Tex0 = In.tex_coord;
	
	float4 in_position = float4(In.position.xyz,1); //float4(g_camera_position.rgb - g_sun_direction.rgb, 1.0);
	
	Out.Position = mul(g_view_proj, mul(g_world, in_position));
	Out.Position.z = Out.Position.w - 0.001f;

	return Out;
}

PS_OUTPUT main_ps(VS_OUTPUT_MOONQUAD In)//TODO_BURAK5: moon should not use this..
{
	PS_OUTPUT Output;
	
	float4 tex_col = sample_diffuse_texture(linear_sampler, In.Tex0);
	//INPUT_TEX_GAMMA(tex_col.rgb);
	
	Output.RGBColor = tex_col * g_mesh_factor_color;// * g_sun_color.rgb;
	//Output.RGBColor.a = tex_col.a;
	
	//float4 world_position = float4(g_camera_position.rgb - g_sun_direction.rgb * 2000, 1.0); //wrong..
	
	//Output.RGBColor = float4(1,0,0,1);
	//Output.RGBColor.a = tex_col.a;

	Output.RGBColor.a = tex_col.a;

	//TODO_BURAK: sun and moon should use different shaders, adding fog to additive sun texture distorts blending..
	//apply_advanced_fog(Output.RGBColor.rgb, -g_sun_direction.rgb, -g_sun_direction.z * 30.0, g_sun_direction.xyz, 200);	
	
	//Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	//clip(-1);
	return Output;
}
