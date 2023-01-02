#ifndef DEFERRED_LIGHTING_RSH
#define DEFERRED_LIGHTING_RSH

#include "../shader_configuration.h"

#include "face.rsh"

#define g_deferred_light_color (g_mesh_vector_argument.xyz)
#define g_deferred_light_radius (1.0f / g_mesh_vector_argument.w)
#define g_deferred_light_inv_radius (g_mesh_vector_argument.w)

#define g_deferred_light_ambient_coefficient (g_mesh_vector_argument_2.x)
#define g_deferred_light_attenuation_coefficient (g_mesh_vector_argument_2.y)

VS_OUTPUT_DEFERRED_LIGHT deferred_light_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_DEFERRED_LIGHT Out;

	float4 object_position = float4(In.position, 1.0f);
	
	
	Out.ClipSpacePos = Out.Pos;
	Out.WorldSpacePos =  mul(g_world, object_position);
	Out.Pos = mul(g_view_proj, Out.WorldSpacePos);

	//Out.WorldSpaceCamDir.xyz = normalize(Out.WorldSpacePos.xyz - g_camera_position.xyz);
	//Out.WorldSpaceCamDir.w = 1;
	
	return Out;
}

PS_OUTPUT deferred_light_ps(VS_OUTPUT_DEFERRED_LIGHT In, const bool is_volumetric_light, const bool is_using_mask)
{ 
	PS_OUTPUT Output;

	float2 _screen_space_position;
	{
		_screen_space_position = In.ClipSpacePos.xy / In.ClipSpacePos.w;
		_screen_space_position.x = _screen_space_position.x * 0.5f + 0.5f; 
		_screen_space_position.y = _screen_space_position.y * -0.5f + 0.5f; 
	}

	//add volumetricity to all lights according to scene fog amount..
	float volumetricity_factor = is_volumetric_light ? (1.0f) : 0.0f;//saturate((g_fog_density-2.0)*0.1f);
	float has_volumetricity = is_volumetric_light || (volumetricity_factor != 0.0);

	//float4 pixel_gbuffer = sample_normal_texture(tc);
	float4 _pixel_gbuffer = sample_texture_level(gbuffer__normal, linear_sampler, _screen_space_position.xy, 0);
	float _pixel_hw_depth = sample_texture_level(depth_texture, point_sampler, _screen_space_position.xy, 0).x;
	float3 _pixel_world_position = get_ws_position_at_gbuffer(_pixel_hw_depth, _screen_space_position);
	float4 _pixel_specularity = sample_texture_level(gbuffer_2_texture, linear_sampler, _screen_space_position.xy, 0);
	float4 pixel_mixed_values = sample_texture_level(gbuffer_3_texture, linear_sampler, _screen_space_position.xy, 0);
	float _pixel_depth = length(g_camera_position - _pixel_world_position);
	if(!has_volumetricity && _pixel_depth >= g_far_clip-1)
	{
		//sky
		clip(-1);
	}

	float3 _view_direction = normalize(In.WorldSpacePos.xyz - g_camera_position.xyz);
	
	float3 light_center_position = g_world._m03_m13_m23;
	
	float3 world_point_to_light 	= (light_center_position - _pixel_world_position.xyz);
	float world_point_to_light_len	= length(world_point_to_light);
	
	float dist_to_light_n = world_point_to_light_len * g_deferred_light_inv_radius;
	
	if(!has_volumetricity && dist_to_light_n > 1.0f)
	{
		//Out of radius
		clip(-1);
	}
	
	float3 world_point_to_light_norm = world_point_to_light / world_point_to_light_len;

	float3 pixel_normal_in_ws = get_ws_normal_at_gbuffer(_pixel_gbuffer);
	
	float3 to_light_n = world_point_to_light * g_deferred_light_inv_radius;	


	float ambient_occlusion_factor = 1.0;
	float diffuse_occlusion_factor = 1.0;
	
	float _light_attenuation;
	{
		float atten_factor = dist_to_light_n;
		atten_factor *= atten_factor;
		atten_factor *= atten_factor;
	
		float atten_d2 = saturate(1.0f - atten_factor);
		atten_d2 *= atten_d2;

		float deferred_light_attenuation_coefficient = g_deferred_light_attenuation_coefficient;
		float attenuation_due_to_distance = max(1.0f, deferred_light_attenuation_coefficient) / (deferred_light_attenuation_coefficient + world_point_to_light_len*world_point_to_light_len);

		_light_attenuation = atten_d2 * attenuation_due_to_distance;

		//g_spotlight_hotspot_angle is greater than zero only for spotlights
		#if SPOTLIGHT
		{
			float3 light_dir = normalize(g_world._m02_m12_m22);
			float spotlight_atten = saturate(dot(world_point_to_light_norm, light_dir));		
			spotlight_atten = saturate((spotlight_atten - g_spotlight_hotspot_angle) / (g_spotlight_falloff_angle - g_spotlight_hotspot_angle + 0.001));
			_light_attenuation *= spotlight_atten;
		}
		#endif
	}

	if(!has_volumetricity && _light_attenuation == 0.0f)
	{
		clip(-1);
	}

	#if SPOTLIGHT
		float _light_amount = calculate_spot_light_shadow(_pixel_world_position);
	#else
		float _light_amount = calculate_point_light_shadow(-world_point_to_light, _pixel_world_position, 0);
	#endif

	float4 _pixel_albedo = sample_texture_level(gbuffer_1_texture, linear_sampler, _screen_space_position.xy, 0);
	#ifdef USE_GAMMA_CORRECTED_GBUFFER_ALBEDO
		INPUT_TEX_GAMMA(_pixel_albedo.rgb);
	#endif


	if(!has_volumetricity)
	{
		_light_amount = saturate( _light_amount + g_deferred_light_ambient_coefficient );
	}


    //ambient_occlusion_factor = (ambient_occlusion_factor * 0.2 + 0.8);

	bool is_skin = false;
	float3 cur_color;
	if (false)
	{
			float3 wsn = normalize(pixel_normal_in_ws.xyz);
			float3 wsnR = wsn;//normalize(float3(pixel_normal_in_ws.xy * g_debug_vector.x, pixel_normal_in_ws.z));
			float3 wsnB = wsn;//normalize(float3(pixel_normal_in_ws.xy * g_debug_vector.x, pixel_normal_in_ws.z));
			float3 wsnG = wsn;//normalize(float3(pixel_normal_in_ws.xy * g_debug_vector.x, pixel_normal_in_ws.z));

			float wrap_offset = 0.35;
			float ndotl_hard = wrapped_ndotl(wsn.xyz, world_point_to_light_norm.xyz, 0.01);

			float ndotlR = wrapped_ndotl(wsnR.xyz, world_point_to_light_norm.xyz, (5.5 + wrap_offset) * 0.035);
			float ndotlG = wrapped_ndotl(wsnB.xyz, world_point_to_light_norm.xyz, (5.5) * 0.035);
			float ndotlB = wrapped_ndotl(wsnG.xyz, world_point_to_light_norm.xyz, (5.5 - wrap_offset) * 0.035);
			float3 ndotl = float3(ndotlR, ndotlB, ndotlG);

			float3 result_color = 0;
			float3 specular_light = 0;
			float3 point_ligthing = 0;

			float3 hard_diffuse = compute_diffuse_face_lighting(_pixel_albedo.rgb, g_deferred_light_color.rgb, _light_amount, ambient_occlusion_factor, ndotl_hard.rrr);
			float3 smooth_diffuse = compute_diffuse_face_lighting(_pixel_albedo.rgb, g_deferred_light_color.rgb, _light_amount, ambient_occlusion_factor, ndotl);

			float3 young_lerp_values = float3(0.8, 0.61, 0.41);
			float3 old_lerp_values = float3(0.2, 0.1, 0.05);
			float lerp_values = lerp(young_lerp_values, old_lerp_values, 0.5);
			float3 averaged_diffuse = lerp(hard_diffuse, smooth_diffuse, lerp_values);

			point_ligthing += averaged_diffuse;
			point_ligthing += compute_specular_face_lighting(_pixel_specularity.xy, g_deferred_light_color.rgb, _light_amount, 
				wsn, -_view_direction, world_point_to_light_norm.xyz, _pixel_world_position, ambient_occlusion_factor);

			cur_color = point_ligthing;
// 		float3 diffuse_ndotl = wrapped_ndotl(ws_normal.xyz, world_point_to_light_norm.xyz);
// 		cur_color = compute_face_lighting(_pixel_specularity.xy, _pixel_albedo.rgb, 
// 			g_deferred_light_color, _light_amount, pixel_normal_in_ws, -_view_direction, world_point_to_light_norm.xyz, _pixel_world_position, ambient_occlusion_factor, diffuse_ndotl);	
	}
	else
	{
		cur_color = compute_lighting(_pixel_specularity.xy, _pixel_albedo.rgb, 
			g_deferred_light_color, _light_amount, pixel_normal_in_ws, -_view_direction, 
			world_point_to_light_norm.xyz, ambient_occlusion_factor, false);
	}
	
	 
	Output.RGBColor.rgb =  cur_color * _light_attenuation * diffuse_occlusion_factor;
	Output.RGBColor.a = 0.0f;

	if(is_using_mask)
	{
		float4 shadow_map_coord = mul(g_world_inverse, float4(_pixel_world_position,1.0f));
		shadow_map_coord.x /= shadow_map_coord.w;
		shadow_map_coord.y /= shadow_map_coord.w;
		
		shadow_map_coord.xy = (shadow_map_coord.xy * 0.5 + 0.5);
		shadow_map_coord.y = 1.0 - shadow_map_coord.y;
		Output.RGBColor.rgb *= sample_diffuse2_texture(shadow_map_coord.xy).rgb;
	}
	

	if(has_volumetricity)
	{
		float3 cam_to_pixel = (_pixel_world_position.xyz - g_camera_position.xyz);
		float3 cam_to_light = (light_center_position.xyz - g_camera_position.xyz);
		float radius2 = g_deferred_light_radius * g_deferred_light_radius;
		
		float a = dot(cam_to_light, normalize(cam_to_pixel));
		float b = length(cam_to_light);
		
		float sigsq = ((b * b) - (a * a));
		float end;
		if(sigsq <= radius2){
			float mid = sqrt(radius2 - sigsq);
			float3 ray_pos;
			if(b < g_deferred_light_radius) {
				ray_pos = g_camera_position;
				end = (mid + a);
				a = 0;
			}
			else{
				a = (a - mid);
				ray_pos = g_camera_position + normalize(cam_to_pixel) * a;
				end = (mid * 2);
			}
			
			//end -= a;
			int ray_count = g_deferred_light_radius * 2.5;	// OPTIMIZE HERE
			ray_count = max(ray_count, 32);
			const float len_ray_dir = ((end) / ray_count) + (rand_1_05(_pixel_world_position.xy) * 0.08);
			float3 ray_dir = normalize(cam_to_pixel) * len_ray_dir;
			float color = 0;
			float travel_len = a;
			float totalRayLen = length(cam_to_pixel);
			int i = 1;
			for(; i < ray_count; ++i) {	
				color += calculate_point_light_shadow((ray_pos - light_center_position), ray_pos, 0);
				ray_pos = ray_pos + ray_dir;
				travel_len += len_ray_dir;
				if(travel_len > totalRayLen)
					break;
			}
			
			color = (color / i) * max(1-(sqrt(sigsq) / g_deferred_light_radius), 0);
			float3 to_view_n = (g_camera_position.xyz - _pixel_world_position.xyz) * g_deferred_light_inv_radius;
			float k_coeff = saturate(dot(to_light_n, to_view_n) / dot(to_view_n, to_view_n));
			float3 pl = k_coeff * to_view_n - to_light_n;
		
			float vol_atten = saturate(length(pl) * 1.2);

			//float volume_param = (1.0 - dist_to_light_n);
			//STR: we can add some parameters to light for better volumetric control, volumetric lighting should decrease diffuse lighting
			float3 volumetric_light_params = float3(0.48 * volumetricity_factor, 1.0, 0.5 + 0.1 * volumetricity_factor);

			float3 light_color_in = g_deferred_light_color * volumetric_light_params.x;
			float3 light_color_out = light_color_in * volumetric_light_params.y;
			//float volume_param = volumetricity_factor * volumetric_light_params.z;

			float3 out_c = saturate(light_color_in / (volumetric_light_params.z + vol_atten*vol_atten) - light_color_out);
			out_c *= out_c;

			if(g_spotlight_hotspot_angle > 0.0f)
			{
				//STR: volumetric spotlights?
			}
			//dist_to_light_n
			float vol_fac =  pow(color, 3) * (pow(1-vol_atten, 2));
			//float vol_fac =;
			Output.RGBColor.rgb += float3(vol_fac,vol_fac,vol_fac) *  0.3 * g_deferred_light_color ;//out_c;
		}
	}

	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);

	return Output;
}

#endif
