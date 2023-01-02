
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "modular_struct_definitions.rsh"

#define PIXEL_SHADER 1

#include "shared_functions.rsh"

#include "system_postfx.rs"

#if VERTEX_SHADER
VS_OUT_POSTFX main_vs(RGL_VS_INPUT In)
{
	return main_vs_postfx(In);
}
#endif

#if PIXEL_SHADER
float4 main_ps(VS_OUT_POSTFX In) : RGL_COLOR0
{
#if HALF_RES
	float4 depths = depth_texture.GatherRed(linear_clamp_sampler, In.Tex);

	float2 depth_idx = float2(0, depths.x);
	float2 depth_idy = float2(1, depths.y);
	float2 depth_idz = float2(2, depths.z);
	float2 depth_idw = float2(3, depths.w);

	float2 min_depth = -100;
	if (depth_idx.y > min_depth.y)
		min_depth = depth_idx;

	if (depth_idy.y > min_depth.y)
		min_depth = depth_idy;

	if (depth_idz.y > min_depth.y)
		min_depth = depth_idz;

	if (depth_idw.y > min_depth.y)
		min_depth = depth_idw;


	float2 nearest_pixel_uv = In.Tex.xy;
	switch(min_depth.x)
	{
	case 0:
		nearest_pixel_uv += float2(-g_postfx_viewport_halfpixelsize.x, g_postfx_viewport_halfpixelsize.y);
		break;
	case 1:
		nearest_pixel_uv += float2(g_postfx_viewport_halfpixelsize.xy);
		break;
	case 2:
		nearest_pixel_uv += float2(g_postfx_viewport_halfpixelsize.x, -g_postfx_viewport_halfpixelsize.y);
		break;
	case 3:
		nearest_pixel_uv -= float2(g_postfx_viewport_halfpixelsize.xy);
		break;
	}

	float2 _screen_space_position = nearest_pixel_uv;
	float current_depth = min_depth.y;
#else
	float2 _screen_space_position = In.Tex.xy;
	float current_depth = sample_depth_texture(_screen_space_position).r;
#endif

	float3 world_space_position = get_ws_position_at_gbuffer(current_depth, _screen_space_position / g_rc_scale);

	float2 compressed_normal;
	compressed_normal.x = texture1.GatherRed(point_clamp_sampler, _screen_space_position).w;
	compressed_normal.y = texture1.GatherGreen(point_clamp_sampler, _screen_space_position).w;
	float3 _world_space_normal = get_ws_normal_at_gbuffer(compressed_normal);


	float2 encoded_vertex_normal;
	encoded_vertex_normal.x = texture2.GatherRed(point_clamp_sampler, _screen_space_position).w;
	encoded_vertex_normal.y = texture2.GatherGreen(point_clamp_sampler, _screen_space_position).w;
	float3 _world_space_vertex_normal = get_ws_normal_at_gbuffer(encoded_vertex_normal);
	
	float sky_visibility;
	float4 ambient_result = get_ambient_from_prt_grid( world_space_position , _world_space_normal, _world_space_vertex_normal, sky_visibility);
	
	if(ambient_result.a > 1e-5)
	{
		ambient_result.a = 0.1 + sky_visibility;
	}
	
	ambient_result.rgb = ambient_result.rgb * get_pre_exposure();

	return ambient_result;
}
#endif
