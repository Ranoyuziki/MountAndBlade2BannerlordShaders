#ifndef DEFERRED_NEGATIVE_LIGHTING_RSH
#define DEFERRED_NEGATIVE_LIGHTING_RSH

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "modular_struct_definitions.rsh"

#if VERTEX_SHADER
VS_OUTPUT_DEFERRED_LIGHT deferred_negative_light_vs(RGL_VS_INPUT In)
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

float2 pack_depth(float d)
{
	float key = clamp(d * (1.0 / -300), 0, 1);

	// Round to the nearest 1/256.0
	float temp = floor(key * 256.0);

	return float2(temp * (1.0 / 256.0), key * 256.0 - temp);
}

#if PIXEL_SHADER
PS_OUTPUT deferred_negative_light_ps(VS_OUTPUT_DEFERRED_LIGHT In, const bool is_volumetric_light)
{ 
	PS_OUTPUT Output = (PS_OUTPUT)0;

	float2 _screen_space_position;
	{
		_screen_space_position = In.ClipSpacePos.xy / In.ClipSpacePos.w;
		_screen_space_position.x = _screen_space_position.x * 0.5f + 0.5f; 
		_screen_space_position.y = _screen_space_position.y * -0.5f + 0.5f; 
	}

	const float2 scaled_screen_uv = _screen_space_position * g_rc_scale;
	const float2 screen_uv = _screen_space_position;

	float _pixel_hw_depth = sample_texture_level(depth_texture, linear_sampler, scaled_screen_uv, 0).x;

	float3 _pixel_world_position = get_ws_position_at_gbuffer(_pixel_hw_depth, screen_uv);
	
	float4 pixel_os =  mul(g_world_inverse, float4(_pixel_world_position, 1));
	pixel_os.xyz /= pixel_os.w;

	float3 distance_vector = clamp(abs(pixel_os.xyz) - g_mesh_vector_argument.xyz , 0, 1) / (float3(1.0001, 1.0001, 1.0001) - g_mesh_vector_argument.xyz);
	
	float attenuation = clamp(length(distance_vector), 0, 1);
	
//	attenuation *= attenuation;
	
#if 1
	float ambient = (1.0 - attenuation) * g_mesh_vector_argument.w;
	bool is_dark_light = g_mesh_vector_argument_2.x > 0.0f;
	float diffuse;
	if(is_dark_light)
		diffuse = (1.0 - attenuation) * g_mesh_vector_argument.w;
	else
		diffuse = 0;
#else
	float diffuse = attenuation;
	float ambient = attenuation;
#endif
//	color value is constant(0,0,0)
//	g_mesh_factor_color.a :starting alpha
//	g_mesh_vector_argument: inner cube dimensions
	float linear_depth = hw_depth_to_linear_depth(_pixel_hw_depth);
	float2 packed_depth = pack_depth(linear_depth);
	Output.RGBColor = float4(0, 1, packed_depth.x, ambient);// float4(diffuse.rrr, ambient);
	//Output.RGBColor = float4(0,0,0, frac(pixel_os.x));
//	Output.RGBColor = float4(pixel_wsp.rgb, normalized_intensity);

	return Output;
}

#endif

#endif
