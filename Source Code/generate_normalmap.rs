
#include "../shader_configuration.h"

#include "definitions.rsh"

VS_OUTPUT_FULLSCREEN_QUAD main_vs(RGL_VS_INPUT In)
{
	return main_vs_fullscreen_quad(In, false);
}

float4 main_ps(VS_OUTPUT_FULLSCREEN_QUAD input) : RGL_COLOR0
{
	float3 pos_here = sample_depth_texture(input.tex_coord).rgb;
	bool inverted = false;

	float3 cloth_size = float3(1.0f, 1.0f, 1.0f / 256.0f);
	
	float3 pos_near, pos_up;

	if(input.tex_coord.x > (1.0f - cloth_size.z))
	{
		pos_near = sample_depth_texture((input.tex_coord - float2(cloth_size.z, 0.0f)) * g_rc_scale).rgb;

		if (input.tex_coord.y > (1.0f - cloth_size.z))
		{
			pos_up = sample_depth_texture((input.tex_coord - float2(0.0f, cloth_size.z)) * g_rc_scale).rgb;
		}
		else
		{
			pos_up = sample_depth_texture((input.tex_coord + float2(0.0f, cloth_size.z)) * g_rc_scale).rgb;
			inverted = true;
		}
	}
	else if(input.tex_coord.y > (1.0f - cloth_size.z))
	{
		pos_near = sample_depth_texture((input.tex_coord + float2(cloth_size.z, 0.0f)) * g_rc_scale).rgb;
		pos_up   = sample_depth_texture((input.tex_coord - float2(0.0f, cloth_size.z)) * g_rc_scale).rgb;
		inverted = true;
	}
	else
	{
		pos_near = sample_depth_texture((input.tex_coord + float2(cloth_size.z, 0.0f)) * g_rc_scale).rgb;
		pos_up   = sample_depth_texture((input.tex_coord + float2(0.0f, cloth_size.z)) * g_rc_scale).rgb;
	}
		
	float3 dir1 = (pos_near - pos_here); 
	float3 dir2 = (pos_here - pos_up);
		
	float3 cross_result = cross(dir1, dir2);
	float3 normal_here = normalize(cross_result);

	if(inverted) 
		normal_here = -normal_here;
	
	normal_here = (normal_here * 0.5f) + 0.5f;
	
	return float4(normal_here, 1.0f);
}
