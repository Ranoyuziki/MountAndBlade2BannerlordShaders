#ifndef AMBIENT_FUNCTIONS_RSH
#define AMBIENT_FUNCTIONS_RSH

#include "shared_pixel_functions.rsh"
#include "prt_functions.rsh"
#include "system_postfx.rsh"

void extract_env_map_inverse_matrix(float4x4 mat, out float4x4 out_mat, out float atten, out float ambient_multiplier)
{
	atten = mat._41;
	ambient_multiplier = mat._42;
	out_mat = mat;
	out_mat._41 = 0;
	out_mat._42 = 0;
}

void ssr_ray_cast(Texture2D depth_tex, float scene_depth, float3 ray_origin, float3 ray_dir, const int num_steps, out float4 result)
{
	float4 ray_origin_view = mul(g_view_proj, float4(ray_origin, 1));
	float4 ray_dir_view = mul(g_view_proj, float4(ray_dir * scene_depth, 0));
	float4 ray_end_view = ray_origin_view + ray_dir_view;
	ray_origin_view.xyz /= ray_origin_view.w;
	ray_end_view.xyz /= ray_end_view.w;

	float3 ray_step = (ray_end_view - ray_origin_view).xyz;

	const float ray_step_inv = 0.5 * length(ray_step.xy);
	const float2 abs_ray_step = abs(ray_step.xy);
	const float2 s = (abs_ray_step - max(abs(ray_step.xy + ray_step.xy * ray_step_inv) - ray_step_inv, 0.0f)) / abs_ray_step;
	const float ray_step_fac = min(s.x, s.y) / ray_step_inv;

	ray_step *= ray_step_fac;

	const float3 ray_start_uv = float3((ray_origin_view.xy * float2(0.5, -0.5) + 0.5), ray_origin_view.z);

	const float3 ray_step_uv = float3((ray_step.xy * float2(0.5, -0.5)), ray_step.z);

	float4 ray_depth = ray_origin_view + mul(g_view_proj, float4(0, 0, scene_depth, 0));
	ray_depth.xyz /= ray_depth.w;

	const float step = 1.0 / num_steps;
	const float tolerance = abs(ray_depth.z - ray_start_uv.z) * step * 4;

	float min_hit_depth = 100;
	float last_diff = 0;

	float cur_sample = step / 4.0;
	float min_level = 8;
	[unroll]
	for (int i = 0; i < num_steps * 2; ++i)
	{
		float level = 0;// (i * 1 / num_steps);
		const float3 sample_uv = ray_start_uv + ray_step_uv * cur_sample;
		const float sample_depth = depth_tex.SampleLevel(linear_clamp_sampler, sample_uv.xy, 0).r;

		const float depth_diff = sample_uv.z - sample_depth;
		const bool hit = abs(depth_diff + tolerance) < tolerance;

		const float alpha = saturate(last_diff / (last_diff - depth_diff));
		const float intersect = cur_sample + alpha * step - step;
		const float hit_depth = hit ? intersect : 100;
		const float hit_level = hit ? (i * 4.0 / num_steps) : 8;
		min_hit_depth = min(min_hit_depth, hit_depth);
		min_level = min(min_level, hit_level);

		last_diff = depth_diff;
		cur_sample += step;
	}

	float3 hit_uv = ray_start_uv + ray_step_uv * min_hit_depth;
	result = float4(hit_uv, min_hit_depth);
}


void get_blended_env_map_multiple_sample(float3 sample_dir_1, float mip_level_1, float3 sample_dir_2, float mip_level_2, float3 world_pos, float2 ss_pos,
	out float3 out_sample_1, out float3 out_sample_2, float3 pixel_normal, out float sky_visibility)
{
#if !SYSTEM_LOW_QUALITY_SHADERS
	out_sample_1 = 0;
	out_sample_2 = 0;
	float total_weight = 0;
	if (g_use_tiled_envmaps > 0.0)
	{
		ss_pos = saturate(ss_pos);
		int2 tile_counts = (int2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		int2 tile_index = (int2)((ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE);
		tile_index = min(max(int2(0, 0), tile_index), tile_counts - int2(1, 1));
		uint start_index = MAX_ENVMAP_PROBE_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint probe_index = visible_env_map_probes[start_index];

		while (probe_index != 0xff)
		{
			float4x4 inverse_matrix;
			float atten_coef;
			float ambient_multiplier;
			extract_env_map_inverse_matrix(visible_env_map_probes_inv_frames[probe_index].inverse_frame, inverse_matrix, atten_coef, ambient_multiplier);
			float3 pos_in_obj_space = mul(inverse_matrix, float4(world_pos, 1)).xyz;
			float3 position_in_box = saturate(abs(pos_in_obj_space));
			float min_axis = max(max(position_in_box.x, position_in_box.y), position_in_box.z) + 0.001;
			float3 point_on_box = position_in_box / min_axis;
			float atten = saturate(length(position_in_box) / length(point_on_box));
			atten = 1.0 - pow(atten, atten_coef);
			float3 corrected_ray_dir = sample_dir_1;
			float4 position = visible_env_map_probes_inv_frames[probe_index].position;
			if (position.w > 0.5) // If parallax correction enabled (position.w == 1.0)
			{
				const float3 ray_dir = mul(inverse_matrix, float4(sample_dir_1, 0.0)).xyz;
				const float3 ray_dir_inv = 1.0 / ray_dir;
				const float3 s = float3((ray_dir.x < 0.0) ? 1.0 : -1.0, (ray_dir.y < 0.0) ? 1.0 : -1.0, (ray_dir.z < 0.0) ? 1.0 : -1.0);
				const float3 intersect_max_point_planes = (-pos_in_obj_space + s) * ray_dir_inv;
				const float3 intersect_min_point_planes = (-pos_in_obj_space - s) * ray_dir_inv;
				const float3 largest_ray_params = max(intersect_max_point_planes, intersect_min_point_planes);
				const float dist_to_intersect = min(min(largest_ray_params.x, largest_ray_params.y), largest_ray_params.z);
				const float3 intersect_point_ws = world_pos + sample_dir_1 * dist_to_intersect;
				corrected_ray_dir = intersect_point_ws - position.xyz;
			}
			out_sample_1 += sample_cube_texture_array(corrected_ray_dir, mip_level_1, probe_index).rgb * atten * ambient_multiplier / g_target_exposure;
			out_sample_2 += sample_cube_texture_array(sample_dir_2, mip_level_2, probe_index).rgb * atten * ambient_multiplier / g_target_exposure;
			total_weight += atten;

			start_index++;
			probe_index = visible_env_map_probes[start_index];
		}

		out_sample_1 /= total_weight + 0.0001;
		out_sample_2 /= total_weight + 0.0001;
	}
	
	
#if defined(WATER_RENDERING) && GLOBAL_WATER_REFLECTION
	if (total_weight < 1.0)
	{
		const uint probe_index = (uint)g_water_probe_index;
		float3 global_envmap = sample_cube_texture_array(sample_dir_1, mip_level_1, probe_index).rgb / g_target_exposure;
		out_sample_1 = lerp(out_sample_1, global_envmap.rgb, 1.0 - total_weight);
		global_envmap = sample_cube_texture_array(sample_dir_2, mip_level_2, probe_index).rgb / g_target_exposure;
		out_sample_2 = lerp(out_sample_2, global_envmap.rgb, 1.0 - total_weight);
	}
#else
	if (total_weight < 1.0)
	{
		float3 global_envmap = sample_cube_texture_array(sample_dir_1, mip_level_1, 0).rgb / g_target_exposure;
		out_sample_1 = lerp(out_sample_1, global_envmap.rgb, 1.0 - total_weight);
		global_envmap = sample_cube_texture_array(sample_dir_2, mip_level_2, 0).rgb / g_target_exposure;
		out_sample_2 = lerp(out_sample_2, global_envmap.rgb, 1.0 - total_weight);
	}
#endif

#else
#if defined(WATER_RENDERING) && GLOBAL_WATER_REFLECTION
	const uint probe_index = g_water_probe_index;
	out_sample_1 = sample_cube_texture_array(sample_dir_1, mip_level_1, probe_index).rgb / g_target_exposure;
	out_sample_2 = sample_cube_texture_array(sample_dir_2, mip_level_2, probe_index).rgb / g_target_exposure;
#else
	out_sample_1 = sample_cube_texture_array(sample_dir_1, mip_level_1, 0).rgb / g_target_exposure;
	out_sample_2 = sample_cube_texture_array(sample_dir_2, mip_level_2, 0).rgb / g_target_exposure;
#endif
#endif

	sky_visibility = 1.0f;

#if SYSTEM_USE_PRT && !defined(WATER_RENDERING)

#if (my_material_id == MATERIAL_ID_DEFERRED || defined(STANDART_FOR_HORSE) || defined(USE_ANISO_SPECULAR)) && !defined(PARTICLE_ATLAS_GENERATION_CS)
	float4 prt_grid_amb = float4(0,0,0,0);
	sample_prt_from_offscreen_texture(ss_pos, prt_grid_amb, sky_visibility);
			
	prt_grid_amb.rgb = prt_grid_amb.rgb / get_pre_exposure();
#else
	
	float4 prt_grid_amb = get_ambient_from_prt_grid(world_pos, pixel_normal, pixel_normal, sky_visibility 
		#ifdef PARTICLE_ATLAS_GENERATION_CS
			, true
#endif
	);
#endif
	if (prt_grid_amb.a > 1e-3)
	{
		out_sample_1 *= (length(prt_grid_amb.rgb) / length(out_sample_2.rgb + 0.0001f));

		out_sample_2 = prt_grid_amb.rgb;
	}
#endif

#if (WATER_RENDERING && DYNAMIC_WATER_REFLECTIONS && GLOBAL_WATER_REFLECTION && USE_SSR) || (!WATER_RENDERING && USE_SSR)
	float exposure = get_pre_exposure();
	float ssr_mip = min(mip_level_1, 5);
	ss_pos.xy += pixel_normal.xy * 0.01 * g_rc_scale;
	float4 ssr_tex = sample_texture_level(ssr_texture, linear_clamp_sampler, ss_pos.xy, ssr_mip);
	ssr_tex.xyz = ssr_tex.xyz / exposure;
	ssr_tex.w = saturate(ssr_tex.w);
	out_sample_1 = lerp(out_sample_1, ssr_tex.xyz, ssr_tex.w > 0.1 ? ssr_tex.w : 0);
#endif
}

float3 get_blended_env_map(float3 sample_dir, float mip_level, float3 world_pos, float2 ss_pos)
{
#if !SYSTEM_LOW_QUALITY_SHADERS
	float total_weight = 0;
	float3 total_color = 0;

	if (g_use_tiled_envmaps > 0.0)
	{
		ss_pos = saturate(ss_pos);
		uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		uint2 tile_index = (uint2)((ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE);
		uint start_index = MAX_ENVMAP_PROBE_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint probe_index = visible_env_map_probes[start_index];

		while (probe_index != 0xff)
		{
			float4x4 inverse_matrix;
			float atten_coef;
			float ambient_multiplier;
			extract_env_map_inverse_matrix(visible_env_map_probes_inv_frames[probe_index].inverse_frame, inverse_matrix, atten_coef, ambient_multiplier);
			float3 position_in_box = saturate(abs(mul(inverse_matrix, float4(world_pos, 1)).xyz));
			float min_axis = max(max(position_in_box.x, position_in_box.y), position_in_box.z) + 0.001;
			float3 point_on_box = position_in_box / min_axis;
			float atten = saturate(length(position_in_box) / length(point_on_box));
			atten = 1.0 - pow(atten, atten_coef);
			total_color += sample_cube_texture_array(sample_dir, mip_level, probe_index).rgb * atten * ambient_multiplier / g_target_exposure;
			total_weight += atten;

			start_index++;
			probe_index = visible_env_map_probes[start_index];
		}
		total_color /= total_weight + 0.0001;
	}
	
	if (total_weight < 1.0)
	{
		float4 global_envmap_tex = sample_cube_texture_array(sample_dir, mip_level, 0) / g_target_exposure;
		total_color = lerp(total_color, global_envmap_tex.rgb, 1.0 - total_weight);
	}

	return total_color;
#else
	return sample_cube_texture_array(sample_dir, mip_level, 0).rgb / g_target_exposure;
#endif
}


float3 get_ambient_term_with_skyaccess(float3 world_pos, float3 normal, float2 ss_pos, out float sky_visibility)	
{
	float3 ambientTerm = get_blended_env_map(normal, ENVMAP_LEVEL - 2, world_pos, ss_pos);

	sky_visibility = 1.0f;
	
	#if SYSTEM_USE_PRT
		#if (my_material_id == MATERIAL_ID_DEFERRED)
			float4 prt_grid_amb = float4(0,0,0,0);
			sample_prt_from_offscreen_texture(ss_pos, prt_grid_amb, sky_visibility);
		#else
			float4 prt_grid_amb = get_ambient_from_prt_grid(world_pos, normal, normal, sky_visibility);
		#endif
		if(prt_grid_amb.a > 1e-3)
		{
			ambientTerm = prt_grid_amb.rgb;
		}
	#endif

	float L = dot(LUMINANCE_WEIGHTS, ambientTerm);
	ambientTerm /= L;
	ambientTerm *= max(L, g_minimum_ambient);
	return ambientTerm;
}

void get_ambient_terms(float3 world_pos, float3 reflection_normal, float3 ambient_normal, float2 ss_pos, float3 view_direction, float2 specularity_info, float3 albedo_color,
	float sun_amount, out float3 out_specular_ambient, out float3 out_diffuse_ambient, out float sky_visibility)
{
	float3 diffuse_ambient_term = float3(1.0, 0.0, 0.0);
	float3 specular_ambient_term = float3(0.0, 0.0, 0.0);

	float VdotN = saturate(dot(view_direction, reflection_normal));
	float roughness = (1.0f - specularity_info.y);
	float envmap_sample_level = (ENVMAP_LEVEL - 1) * roughness;
	roughness = saturate(roughness);

	sky_visibility = 1.0f;

	float3 reconstructed_pixel_specular_color = construct_specular_color(specularity_info, albedo_color);

		float ao_factor = 1.0;
		float4 view_reflect;
		float3 env_color;

		float NoV = saturate(dot(view_direction.xyz, reflection_normal.xyz));
		//TODO invert texture
		view_reflect.w = roughness * 8;

		view_reflect.xyz = reflect(-view_direction, reflection_normal);
		view_reflect.w = envmap_sample_level;

		get_blended_env_map_multiple_sample(view_reflect.xyz, view_reflect.w, ambient_normal, ENVMAP_LEVEL, world_pos, ss_pos, env_color, 
			diffuse_ambient_term, reflection_normal, sky_visibility);
			
		const bool use_real_time_filtering = false;
		if (use_real_time_filtering)
		{
			specular_ambient_term = ImportanceSample(reconstructed_pixel_specular_color, roughness, reflection_normal, view_direction);
		}
		else
		{
			float2 env_brdf = sample_texture_level(brdf_texture, linear_clamp_sampler, float2(roughness, NoV), 0).xy;
			specular_ambient_term = env_color.rgb * (reconstructed_pixel_specular_color * env_brdf.x + env_brdf.y) * ao_factor;
		}

	out_specular_ambient = specular_ambient_term;
	
	out_specular_ambient *= max(0.1, saturate(specularity_info.y * 10));

	out_diffuse_ambient = diffuse_ambient_term;
	float L = dot(LUMINANCE_WEIGHTS, out_diffuse_ambient);
	out_diffuse_ambient /= L;
	out_diffuse_ambient *= max(L, g_minimum_ambient);
	out_diffuse_ambient = max(out_diffuse_ambient, 0);


}

#endif
