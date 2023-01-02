#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

#define c_view_proj g_custom_matrix
#define envmap_face g_custom_vec0.x

VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_FONT result;
	In.position.z = 0.0f;

	result.Pos = mul(c_view_proj, float4(In.position.xyz, 1));
	result.Color = In.color;
	result.Tex0 = 2*In.tex_coord-1;

	return result;
}

PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	PS_OUTPUT Output;
	float array_id = envmap_face;
	if (envmap_face == 0)
	{
		Output.RGBColor.rgba = sample_cube_texture_array(float3(1 , In.Tex0.x, -In.Tex0.y),0,array_id);
	}
	else if (envmap_face == 1)
	{
		Output.RGBColor.rgba = sample_cube_texture_array(float3(-1 , -In.Tex0.x, -In.Tex0.y),0,array_id);
	}
	else if (envmap_face == 2)
	{
		Output.RGBColor.rgba = sample_cube_texture_array(float3(-In.Tex0.x, In.Tex0.y ,1),0,array_id);
	}
	else if (envmap_face == 3)
	{
		Output.RGBColor.rgba = sample_cube_texture_array(float3(-In.Tex0.x, -In.Tex0.y, -1),0,array_id);
	}
	else if (envmap_face == 4)
	{
		Output.RGBColor.rgba = sample_cube_texture_array(float3(-In.Tex0.x, 1, -In.Tex0.y),0,array_id);
	}
	else if (envmap_face == 5)
	{
		Output.RGBColor.rgba = sample_cube_texture_array(float3(In.Tex0.x, -1, -In.Tex0.y),0,array_id);
	}


	Output.RGBColor = Output.RGBColor * In.Color;

	return Output;
}

