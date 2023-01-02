#ifndef BLOB_SHADOW_SHADER_RSH
#define BLOB_SHADOW_SHADER_RSH

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "gbuffer_functions.rsh"
#include "shared_functions.rsh"

#if VERTEX_SHADER
VS_OUTPUT_DEFERRED_LIGHT blob_shadow_shader_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_DEFERRED_LIGHT Out;

	float4 object_position = float4(In.position, 1.0f);
	
	
	Out.WorldSpacePos =  mul(g_world, object_position);
	Out.Pos = mul(g_view_proj, Out.WorldSpacePos);
	Out.ClipSpacePos = Out.Pos;

	//Out.WorldSpaceCamDir.xyz = normalize(Out.WorldSpacePos.xyz - g_camera_position.xyz);
	//Out.WorldSpaceCamDir.w = 1;
	
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT blob_shadow_shader_ps(VS_OUTPUT_DEFERRED_LIGHT In, const bool is_volumetric_light)
{ 
	PS_OUTPUT Output;

	float2 _screen_space_position;
	{
		_screen_space_position = In.ClipSpacePos.xy / In.ClipSpacePos.w;
		_screen_space_position.x = _screen_space_position.x * 0.5f + 0.5f; 
		_screen_space_position.y = _screen_space_position.y * -0.5f + 0.5f; 
	}

	float _pixel_hw_depth = sample_texture_level(depth_texture, linear_sampler, _screen_space_position.xy, 0).x;
	float3 _pixel_world_position = get_ws_position_at_gbuffer(_pixel_hw_depth, _screen_space_position);
	
	float4 pixel_os =  mul(g_world_inverse, float4(_pixel_world_position, 1));
	pixel_os.xyz /= pixel_os.w;

	float3 distance_vector = abs(pixel_os.xyz);
	if (!(distance_vector.x < 1 && distance_vector.y < 1 && distance_vector.z < 1))
	{
		clip(-1);
	}

	float2 decal_tex_coord = (pixel_os.xy + 1.0) * 0.5;

	float coef = 0.05;
	float attenuation = (length(pixel_os.xy) - coef) / (1.0 - coef);

//	attenuation *= attenuation;
	
	float diffuse = attenuation;
	float ambient = attenuation;

//	color value is constant(0,0,0)
//	g_mesh_factor_color.a :starting alpha
//	g_mesh_vector_argument: inner cube dimensions

	Output.RGBColor = saturate(float4(diffuse.rrr, ambient));
	//Output.RGBColor = float4(0,0,0, frac(pixel_os.x));
//	Output.RGBColor = float4(pixel_wsp.rgb, normalized_intensity);
	return Output;
}

#endif

#endif
