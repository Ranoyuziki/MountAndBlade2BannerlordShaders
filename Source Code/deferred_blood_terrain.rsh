#ifndef DEFERRED_BLOOD_TERRAIN_RSH
#define DEFERRED_BLOOD_TERRAIN_RSH

#include "../shader_configuration.h"

#include "definitions.rsh"

#include "shared_functions.rsh"
#include "standart.rsh"

float3 compute_albedo_color_for_decal(inout float4 diffuse_texture_color, TEXCOORD_FORMAT texcoord, float4 vertex_color, bool left_handed, float blood_amount, float wetness_amount, float3 normal)
{
	//return 0;
	float3 albedo_color = diffuse_texture_color.xyz;

	albedo_color.rgb *= g_mesh_factor_color.rgb;

	if(USE_VERTEX_COLORS)
	{
		albedo_color.rgb *= vertex_color.rgb;
	}

#if SYSTEM_SNOW_LAYER
	float snow_randomization = 1;
	albedo_color.rgb = lerp(albedo_color.rgb,float3(0.58,0.68,0.98), saturate(3.1f * normal.z  + saturate(snow_randomization * 0.4)));
#endif

#if SYSTEM_RAIN_LAYER
	albedo_color.rgb *= lerp(1.0, 0.4, wetness_amount);                   // Attenuate diffuse
#endif

	return albedo_color;
}


VS_OUTPUT_DEFERRED_DECAL deferred_blood_terrain_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_DEFERRED_DECAL Out;

	float4 object_position = float4(In.position, 1.0f);
	
	
	Out.ClipSpacePos = Out.Pos;
	float4 world_position = mul(g_world, object_position);
	Out.Pos = mul(g_view_proj, world_position);

	Out.WorldSpacePos = world_position;
	
	//Out.WorldSpaceCamDir.xyz = normalize(Out.WorldSpacePos.xyz - g_camera_position.xyz);
	//Out.WorldSpaceCamDir.w = 1;
	
	return Out;
}

PS_OUTPUT deferred_blood_terrain_ps(VS_OUTPUT_DEFERRED_DECAL In)
{ 
	PS_OUTPUT Output;
	In.ClipSpacePos.xy /= In.ClipSpacePos.w;

	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f; 
	tc.y = tc.y * -0.5f + 0.5f; 

	//DEBUG_OUTPUT(1,0,1,1);

	float hw_depth = sample_depth_texture(tc * g_rc_scale).r;
	float4 pixel_mixed_values = sample_screen_texture(tc);
	float4 pixel_pos_in_ws = float4(get_ws_position_at_gbuffer(hw_depth, tc), 1);
	float4 pixel_pos_in_os =  mul(g_world_inverse, pixel_pos_in_ws);
	float2 decal_tex_coord = (pixel_pos_in_os.xy + 1.0) * 0.5;

	bool is_terrain = false;
	bool is_skinned = false;
	bool is_face = false;

	float3 pixel_normal_in_ws;

	float3 distance_vector2 = abs(pixel_pos_in_os.xyz);
	if( distance_vector2.x < 1 && distance_vector2.y < 1 && distance_vector2.z < 1)
	{
		//is_in_range
	}
	else
	{
		clip(-1);
	}

	float uv_scale_x = g_mesh_vector_argument.x; 
	float uv_scale_y = g_mesh_vector_argument.y; 
	float uv_offset_x = g_mesh_vector_argument.z;
	float uv_offset_y = g_mesh_vector_argument.w;
	float2 atlassed_texture_coord = float2(decal_tex_coord.x * uv_scale_x + uv_offset_x, decal_tex_coord.y * uv_scale_y + uv_offset_y);

#if USE_TEXTURE_SWEEP
	atlassed_texture_coord.xy += g_mesh_vector_argument_2.xy * g_time_var * 0.1;
#endif

	float tex_mask = 1;
	if(bool(USE_AREAMAP))
	{
		tex_mask = sample_diffuse2_texture(decal_tex_coord).a;
		clip(tex_mask - 0.001f);
	}

	float4 diffuse_texture_color = float4(0,0,0,1);
	diffuse_texture_color = sample_diffuse_texture(MeshTextureSampler, atlassed_texture_coord.xy).rgba;

	float early_alpha_value = 1.0f;
	early_alpha_value *= diffuse_texture_color.a;

	apply_alpha_test(early_alpha_value);

	float3 _world_space_position = pixel_pos_in_ws.xyz;
	float3 _world_space_normal = get_column(g_world, 2).xyz;
	float2 _screen_space_position = tc.xy * g_application_halfpixel_viewport_size_inv.zw;

	float3 _view_vector_unorm = (g_camera_position.xyz - _world_space_position.xyz);
	float _view_length = length(_view_vector_unorm);
	float3 _view_vector = _view_vector_unorm / _view_length;

	float _blood_amount = 0.0;
	float _wetness_amount = 0.0;
	
#if SYSTEM_RAIN_LAYER
	_wetness_amount = saturate(g_rain_density);
#endif

	//////////////////////////////////////////////////////////////////////////
	bool left_handed = false;
	if(bool(USE_DETAILNORMALMAP))
	{
		const float3 world_matrix_s = get_column(g_world, 0).xyz;
		float3x3 TBN; 

		TBN[2] = _world_space_normal;

		TBN[0] = normalize(world_matrix_s);
		TBN[1] = safe_normalize(cross(TBN[2], TBN[0]));
		TBN[2] = safe_normalize(cross(TBN[0], TBN[1]));

		float3 normalTS;
#if SYSTEM_DXT5_DETAIL_NORMALMAP
		normalTS.xy = (2.0f * sample_detail_normal_texture(atlassed_texture_coord.xy).ag - 1.0f);
		normalTS.z = sqrt(1.0f - dot(normalTS.xy, normalTS.xy));
#elif SYSTEM_BC5_DETAIL_NORMALMAP
		normalTS.xy = (2.0f * sample_detail_normal_texture(atlassed_texture_coord.xy).rg - 1.0f);
		normalTS.z = sqrt(1.0f - dot(normalTS.xy, normalTS.xy));
#else
		normalTS = (2.0f * sample_detail_normal_texture(atlassed_texture_coord.xy).rgb - 1.0f);
#endif

		_world_space_normal = normalize(mul(normalTS, TBN));

		if(bool(USE_PARALLAXMAPPING))
		{
			float3 view_direction_ts = mul(TBN, _view_vector_unorm);
			float2 plxCoeffs = float2(0.04, -0.02) * 2.2f;

			float height;
			if(HAS_MATERIAL_FLAG(g_mf_separate_displacement_map))
			{
				height = sample_displacement_map_texture(atlassed_texture_coord.xy);
			}
			else
			{
				height = sample_detail_normal_texture(atlassed_texture_coord.xy).a;
			}
			
			float offset = height * plxCoeffs.x + plxCoeffs.y;
			atlassed_texture_coord.xy += offset * normalize(view_direction_ts).xy; //view_direction.xy;

			diffuse_texture_color = sample_diffuse_texture(MeshTextureSampler, atlassed_texture_coord.xy).rgba;
		}
	}

	//DEBUG_OUTPUT3(_world_space_normal.xyz * 0.5 + 0.5);

	INPUT_TEX_GAMMA(diffuse_texture_color.rgb);

	float3 _albedo_color = compute_albedo_color_for_decal(diffuse_texture_color, atlassed_texture_coord, float4(1,1,1,1), left_handed, _blood_amount, _wetness_amount, _world_space_normal);
	//DEBUG_OUTPUT3(_albedo_color);
	//////////////////////////////////////////////////////////////////////////

	float diffuse_occlusion_factor, ambient_occlusion_factor;
	compute_occlusion_factors_forward_pass( diffuse_occlusion_factor, pp_modifiable, ambient_occlusion_factor,
		_world_space_normal, _world_space_position.xyz, _screen_space_position, atlassed_texture_coord,float4(1,1,1,1) );

	float2 _specularity_info = compute_specularity(atlassed_texture_coord, pp_modifiable, _world_space_position.xyz, _world_space_normal.xyz, float4(1,1,1,1), _blood_amount, _wetness_amount, _albedo_color, _albedo_color);
	float3 specular_color = construct_specular_color(_specularity_info, diffuse_texture_color.rgb);

	float _sun_amount = 1;
	{
		_sun_amount = compute_sun_amount(_world_space_position, _screen_space_position);
	}

	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	float sky_visibility;

	get_ambient_terms(_world_space_position, _world_space_normal, _world_space_normal, _screen_space_position.xy, 
		_view_vector, _specularity_info, _albedo_color, _sun_amount, specular_ambient_term, diffuse_ambient_term, sky_visibility);

	float3 ambient_light = _albedo_color.rgb * saturate(1.0 - 1.5f * _specularity_info.x) * diffuse_ambient_term;
	ambient_light += specular_ambient_term;
	float3 final_color = ambient_light * ambient_occlusion_factor;
	//DEBUG_OUTPUT3(sample_specular_texture(atlassed_texture_coord.xy).rgb);
	//DEBUG_OUTPUT3(final_color);
	{
		float3 aniso_direction = float3(0,0,1);
		float3 sun_lighting = compute_lighting(_specularity_info, _albedo_color.rgb, g_sun_color.rgb, _sun_amount, 
			_world_space_normal, _view_vector, g_sun_direction_inv, diffuse_occlusion_factor);

		final_color += sun_lighting;
	}

	apply_advanced_fog(final_color.rgb, _view_vector, _view_vector_unorm.z, _view_length, 1.0f);	

	//set color
	Output.RGBColor.rgb = final_color;
	Output.RGBColor.a = early_alpha_value * tex_mask;
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);

	return Output;
}

#endif
