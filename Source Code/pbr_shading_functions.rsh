#ifndef PBR_SHADING_FUNCTIONS_RSH
#define PBR_SHADING_FUNCTIONS_RSH

#ifdef STANDART_FOR_HORSE
#include "horse_shading_functions.rsh"
#endif

#include "shared_decal_functions.rsh"

#if PIXEL_SHADER
#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)

float3 compute_direct_lighting(direct_lighting_info l_info, float2 specularity_info, float3 albedo_color,
	float3 world_space_normal, float3 view_direction, float3 world_space_position,
	float2 screen_space_position, float diffuse_ao_factor)
{
	return compute_lighting(specularity_info, albedo_color,
		l_info.light_color, l_info.light_amount, world_space_normal, view_direction, l_info.light_direction, diffuse_ao_factor);
}

void calculate_weather_effects(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static,
	inout Per_pixel_modifiable_variables pp_modifiable, float2 world_to_uv, float4 world_to_uv_dxdy)
{
#if SYSTEM_RAIN_LAYER || SYSTEM_SNOW_LAYER
	const bool dont_use_weather = get_material_id_raw(pp_static.screen_space_position.xy, true) & 0x40; // 0x40 not_affected_by_season flag
	[branch]
	if (dont_use_weather)
	{
		return;
	}

	float2 uv = pp_static.world_space_position.xy * g_terrain_size_inv;
	uv.y = 1 - uv.y;

	float glob_noise = global_random_texture.SampleGrad(linear_sampler, world_to_uv * 0.1, world_to_uv_dxdy.xy, world_to_uv_dxdy.zw).r;
	float depthsamp = (1 - topdown_depth_texture.SampleLevel(linear_sampler, uv, 0).r) * 800 - 400;

	float mask = (smoothstep(depthsamp - glob_noise * 10, depthsamp, pp_static.world_space_position.z));

	mask *= saturate(pp_static.world_space_position.z - g_water_level);
	float dist = 1 - saturate(distance(g_camera_position.xyz, pp_static.world_space_position.xyz) / 10.0f);
#endif

#if SYSTEM_SNOW_LAYER
#if !IS_TERRAIN && !IS_GRASS
	float snow_val = smoothstep(lerp(0.75, 0.2, g_rain_density), 1.0, pp_modifiable.world_space_normal.z) * mask;

	float3 sample_loc = (pp_static.world_space_position.xyz * 0.25);
	float4 snow_layer_diffuse = sample_snow_diffuse_texture(world_to_uv);
	INPUT_TEX_GAMMA(snow_layer_diffuse);
	pp_modifiable.albedo_color.rgb = lerp(pp_modifiable.albedo_color.rgb, snow_layer_diffuse.rgb, snow_val);

	float3 snow_layer_normal = float3(snow_normal_texture.SampleGrad(linear_sampler, world_to_uv, world_to_uv_dxdy.xy, world_to_uv_dxdy.zw).xy * 2 - 1, 1);
	snow_layer_normal.z = sqrt(1.0f - saturate(dot(snow_layer_normal.xy, snow_layer_normal.xy)));
	snow_layer_normal = normalize(snow_layer_normal);
	pp_modifiable.world_space_normal.xyz = lerp(pp_modifiable.world_space_normal.xyz, normalize(float3(pp_modifiable.world_space_normal.xy + snow_layer_normal.xy, snow_layer_normal.z)), snow_val);

	float3 snow_layer_specular = snow_specular_texture.SampleGrad(linear_sampler, world_to_uv, world_to_uv_dxdy.xy, world_to_uv_dxdy.zw).rgb;
	pp_modifiable.specularity.xy = lerp(pp_modifiable.specularity.xy, snow_layer_specular.xy, snow_val);
#endif
#elif SYSTEM_RAIN_LAYER
	const float rain_density = saturate(pp_modifiable.world_space_normal.z) * g_rain_density * mask;
	float wetness = rain_density * (1 - max(pp_modifiable.specularity.x, pp_modifiable.specularity.y));

	[branch]
	if (dist > 0.0f)
	{
		float3 rain_drops = raindrop_texture.SampleGrad(point_sampler, world_to_uv, world_to_uv_dxdy.xy, world_to_uv_dxdy.zw).xyz;
		rain_drops.z = dist * (step(0.001, rain_drops.z) * frac(rain_drops.z - g_time_var * g_rain_density)) * rain_density;
		const float3 rain_drops_normal = normalize(float3(rain_drops.xy * 2 - 1, 0.75f));
		pp_modifiable.world_space_normal = lerp(pp_modifiable.world_space_normal, rain_drops_normal, rain_drops.z);
		pp_modifiable.world_space_normal = normalize(pp_modifiable.world_space_normal);

		float additive_wetness = rain_drops.z;
		wetness = saturate(wetness + additive_wetness);

		pp_modifiable.albedo_color *= lerp(1.0, 0.05, additive_wetness);
	}

	//pp_modifiable.albedo_color.rgb = float3(1,0,1);

#if IS_GRASS
	//pp_modifiable.specularity.x = 0.0;
	pp_modifiable.specularity.y = lerp(pp_modifiable.specularity.y, 0.5, lerp(wetness, 1.0, wetness));
#else
	//pp_modifiable.specularity.x = 0.1;
	pp_modifiable.specularity.y = lerp(pp_modifiable.specularity.y, 0.8, lerp(wetness, 1.0, wetness));
#endif
#endif

}

#ifndef WATER_RENDERING
void calculate_add_decal_deferred(in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, Pixel_shader_input_type In, out float3 emission_ambient, float3 PositionWS_DX, float3 PositionWS_DY)
{
	emission_ambient = 0;

	float3 positionNeighborX = pp_static.world_space_position.xyz + PositionWS_DX;
	float3 positionNeighborY = pp_static.world_space_position.xyz + PositionWS_DY;

	[branch]
	if (g_use_tiled_decal_rendering)
	{
#ifdef SYSTEM_SHOW_TILED_DECAL_OVERDRAW
		float decal_tile_heatmap_weight = 0;
#endif 
		float decal_accumulation_alpha = 0;
		float2 ss_pos = saturate(pp_static.screen_space_position);
		uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		uint2 tile_index = (ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE;
		uint start_index = MAX_DECALS_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint2 probe_index = visible_decals[start_index];

		float pixel_depth = mul(g_view_proj, float4(pp_static.world_space_position.xyz, 1)).w;

#ifdef USE_25D_TILED_CULLING
		uint pp_tiling_z = (uint)floor(32 * log2(pixel_depth / 1) / log2(MAX_DISTANCE_DECAL_TILE / 1));
		pp_tiling_z = 1 << pp_tiling_z;
#endif // USE_25D_TILED_CULLING

		float dist_fade_out_val = smoothstep(0, 1, (MAX_DISTANCE_DECAL_TILE - pixel_depth) * 0.01); //magic number can be adjusted for smoother transition

		[loop]
		while (probe_index.x != 0xFFFF)
		{
#ifdef USE_25D_TILED_CULLING
			uint depthmask_index = probe_index.y;
#endif // USE_25D_TILED_CULLING

			DecalParams decal_render_params = visible_decal_render_params[probe_index.x];

#ifdef SYSTEM_SHOW_TILED_DECAL_OVERDRAW
			decal_tile_heatmap_weight += 1 / g_tiled_decals_overdraw_visualize_limit;
#endif 

			[branch]
			if (
#if IS_TERRAIN
				decal_render_params.decal_flags & rgl_decal_flag_render_on_terrain
#elif IS_GRASS
				decal_render_params.decal_flags & rgl_decal_flag_render_on_grass
#else
				decal_render_params.decal_flags & rgl_decal_flag_render_on_objects
#endif
#ifdef GBUFFER_DECALS_ENABLED
				&& !(decal_render_params.decal_flags & rgl_decal_flag_height_masked)
#endif
#ifdef USE_25D_TILED_CULLING
				&& (depthmask_index & pp_tiling_z) == pp_tiling_z
#endif
				)
			{//render decal
				float4 decal_d = 0;
				float3 decal_n, decal_s;

				float4x4 d_data_frame_inv = decal_render_params.frame_inv;
				float4x4 d_data_frame = decal_render_params.frame;

				float4 pixel_pos_in_os = mul(d_data_frame_inv, float4(pp_static.world_space_position, 1));
				pixel_pos_in_os.xyz /= pixel_pos_in_os.w;;

				float4 decalPosNeighborX = mul(d_data_frame_inv, float4(positionNeighborX, 1));
				float4 decalPosNeighborY = mul(d_data_frame_inv, float4(positionNeighborY, 1));

				float3 cur_p_fwd = float3(0, 0, 0);
				bool is_in_quad = true;
				float road_fadeout_val = 1;
				if (decal_render_params.decal_flags & rgl_decal_flag_is_road && decal_render_params.path_p0.x != 0)
				{
					is_in_quad = is_pixel_in_road_boundaries(decal_render_params, pp_static.world_space_position.xy);
					if (is_in_quad)
					{
						decalPosNeighborX.xy = get_uv_for_road(positionNeighborX, decal_render_params, cur_p_fwd, road_fadeout_val);
						decalPosNeighborY.xy = get_uv_for_road(positionNeighborY, decal_render_params, cur_p_fwd, road_fadeout_val);
						pixel_pos_in_os.xy = get_uv_for_road(pp_static.world_space_position.xyz, decal_render_params, cur_p_fwd, road_fadeout_val);

						decalPosNeighborX.x *= (pixel_pos_in_os.x * decalPosNeighborX.x < 0) ? -1 : 1;
						decalPosNeighborX.y *= (pixel_pos_in_os.y * decalPosNeighborX.y < 0) ? -1 : 1;
						decalPosNeighborY.x *= (pixel_pos_in_os.x * decalPosNeighborY.x < 0) ? -1 : 1;
						decalPosNeighborY.y *= (pixel_pos_in_os.y * decalPosNeighborY.y < 0) ? -1 : 1;
					}
				}

				if (is_in_quad)
				{
					float2 tc_init = (pixel_pos_in_os.xy + 1.0) * 0.5;
					float2 tc_d = get_atlassed_decal_texture_tc(tc_init, decal_render_params.d_atlas_uv_d, decal_render_params.atlas_uv);
					float2 tc_n = get_atlassed_decal_texture_tc(tc_init, decal_render_params.d_atlas_uv_n, decal_render_params.atlas_uv);
					float2 tc_s = get_atlassed_decal_texture_tc(tc_init, decal_render_params.d_atlas_uv_s, decal_render_params.atlas_uv);

					//according to frame
					const float3 world_matrix_s = normalize(get_column(d_data_frame, 0).xyz);
					const float3 world_matrix_n = normalize(get_column(d_data_frame, 2).xyz);

					float3x3 TBN;
					if (decal_render_params.decal_flags & rgl_decal_flag_is_road)
					{
						TBN[0] = normalize(-cur_p_fwd);
						TBN[2] = normalize(pp_modifiable.vertex_normal);
						TBN[1] = safe_normalize(cross(TBN[2], TBN[0]));
						TBN[0] = safe_normalize(cross(TBN[2], TBN[1]));
					}
					else
					{
						TBN[2] = world_matrix_n;
						TBN[0] = world_matrix_s;
						TBN[1] = safe_normalize(cross(TBN[2], TBN[0]));
						TBN[2] = safe_normalize(cross(TBN[0], TBN[1]));
					}

					// Calculate decal UV gradients

					float2 tc_d_x = get_atlassed_decal_texture_tc(float2((decalPosNeighborX.xy + 1.0) * 0.5), decal_render_params.d_atlas_uv_d, decal_render_params.atlas_uv);
					float2 tc_d_y = get_atlassed_decal_texture_tc(float2((decalPosNeighborY.xy + 1.0) * 0.5), decal_render_params.d_atlas_uv_d, decal_render_params.atlas_uv);

					float2 dfx_tc = tc_d_x - tc_d;
					float2 dfy_tc = tc_d_y - tc_d;

					if (decal_render_params.decal_flags & rgl_decal_flag_is_road)
					{
						float angle = dot(pp_static.view_vector, pp_modifiable.vertex_normal) / (distance(pp_static.view_vector, float3(0, 0, 0)) * distance(pp_modifiable.vertex_normal, float3(0, 0, 0)));
						angle *= decal_render_params.mip_multiplier;
						dfx_tc /= angle;
						dfy_tc /= angle;
					}

					float parallax_shadow = 1.0;
					[branch]
					if (decal_render_params.decal_flags & rgl_decal_flag_use_parallax)
					{
						float2 parallax_tc_n = tc_n;
						float4 parallax_dfx = float4(dfx_tc * g_decal_atlas_texture_dim, dfx_tc);
						float4 parallax_dfy = float4(dfy_tc * g_decal_atlas_texture_dim, dfy_tc);

						float parallax_amount_dummy;
						parallax_shadow = apply_parallax_w_atlassed_texture(In, decal_atlas_texture, parallax_tc_n, pp_static.view_vector_unorm, TBN, pp_modifiable.world_space_normal, parallax_amount_dummy, pp_modifiable, g_decal_atlas_texture_dim, decal_render_params, parallax_dfx, parallax_dfy);

						float2 parallax_offset = parallax_tc_n - tc_n;

						tc_d = clamp(tc_d + parallax_offset, decal_render_params.d_atlas_uv_d.zw, decal_render_params.d_atlas_uv_d.zw + decal_render_params.d_atlas_uv_d.xy);
						tc_s = clamp(tc_s + parallax_offset, decal_render_params.d_atlas_uv_s.zw, decal_render_params.d_atlas_uv_s.zw + decal_render_params.d_atlas_uv_s.xy);
						tc_n += parallax_offset;
					}

					float4 pixel_pos_in_os2 = mul(d_data_frame_inv, float4(pp_static.world_space_position, 1));
					pixel_pos_in_os2.xyz /= pixel_pos_in_os2.w;

					float3 clipSpacePos = float3(pixel_pos_in_os.xy, pixel_pos_in_os2.z);
					float3 uvw = clipSpacePos.xyz*float3(0.5f, -0.5f, 0.5f) + 0.5f;

					// discard outside of the frame
					[branch]
					if (!any(uvw - saturate(uvw)))
					{
						// angle rejecting
						float threshold_angle_cos = 0.4;
						float edgeBlend = 1 - pow(saturate(abs(clipSpacePos.z)), 8);
#ifndef SHADOWMAP_PASS
						if (!(decal_render_params.decal_flags & rgl_decal_flag_hardlight_blend))
						{
							edgeBlend *= saturate((dot(pp_modifiable.world_space_normal, world_matrix_n) - threshold_angle_cos) * 3.5);
						}
#endif
						sample_tiled_decal(decal_d, decal_n, decal_s, decal_render_params, tc_d, tc_n, tc_s, In.position.xy, dfx_tc, dfy_tc);

						decal_d *= decal_render_params.factor_color_1;
						decal_n.xy *= decal_render_params.normalmap_power;
						if (!(decal_render_params.decal_flags & rgl_decal_flag_is_road))
						{
							decal_d.a *= edgeBlend;

							if (!(decal_render_params.decal_flags & rgl_decal_flag_override_visibility_checks))
							{
								decal_d.a *= dist_fade_out_val;
							}
						}
						else
						{
							decal_d.a *= road_fadeout_val;
						}
						emission_ambient += max(0, decal_d.rgb * decal_render_params.emission_amount * decal_d.a);

						decal_n = normalize(mul(decal_n, TBN));

#if IS_GRASS
						decal_d.a = lerp(decal_d.a, 0, step(decal_d.a, 0.7) * (decal_d.a / 0.7));
#endif

						//blend
						decal_s.xyz *= float3(decal_render_params.specular_coef, decal_render_params.gloss_coef, parallax_shadow);
						decal_accumulation_alpha += decal_d.a;

						decal_blending(pp_modifiable.albedo_color.rgb, pp_modifiable.world_space_normal.xyz, pp_modifiable.specularity.rg, pp_modifiable.ambient_ao_factor, decal_d, decal_n, decal_s, decal_render_params.decal_flags);

						pp_modifiable.albedo_color.rgb = lerp(pp_modifiable.albedo_color.rgb, decal_render_params.contour_color.xyz, step(decal_d.a, 0.7) * (decal_d.a / 0.7 * decal_render_params.contour_color.a));
						pp_modifiable.albedo_color.rgb = lerp(pp_modifiable.albedo_color.rgb, decal_render_params.contour_color.xyz, decal_d.a * 0.2 * decal_render_params.contour_color.a);

						// main map makes use of several decals placed on top of each other in cities
						//if (decal_accumulation_alpha > 1.0)
						//{
						//	break;
						//}
					}
				}
			}//render decal
			probe_index = visible_decals[++start_index];
		}

#ifdef SYSTEM_SHOW_TILED_DECAL_OVERDRAW
		pp_modifiable.albedo_color.rgb += heat_map(decal_tile_heatmap_weight);
#endif 
	}
}
#endif

//final pbr function
void calculate_final_pbr(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
#if !(BAKE_TERRAIN_COLOR) && !(BAKE_TERRAIN_HEIGHT)
	float3 decal_emission_ambient_term = 0;
#if !defined(WATER_RENDERING) && !defined(STANDART_FOR_HORSE) && !defined(STANDART_FOR_EYE) && !defined(STANDART_FOR_CROWD)
	float3 PositionWS_DX = ddx_fine(pp_static.world_space_position.xyz);
	float3 PositionWS_DY = ddy_fine(pp_static.world_space_position.xyz);

	float2 world_to_uv = pp_static.world_space_position.xy * 0.24f;
	float4 world_to_uv_dxdy = float4(ddx(world_to_uv), ddy(world_to_uv));
#if (!(IS_TERRAIN || IS_GRASS) && (MATERIAL_ID_DEFERRED == my_material_id))
	[branch]
	if ((get_material_id_raw(pp_static.screen_space_position, true) & 0x80)) // 0x80 is_stationary
#endif
	{
#if !IS_GRASS
		float distance_factor = 1 - saturate(pp_static.view_length / 64.0f);
		pp_modifiable.world_space_normal = lerp(pp_modifiable.world_space_normal, float3(0, 0, 1), (1 - smoothstep(g_water_level, g_water_level + 0.1, pp_static.world_space_position.z)) * distance_factor);
		pp_modifiable.albedo_color.xyz = lerp(pp_modifiable.albedo_color.xyz * 0.5, pp_modifiable.albedo_color.xyz, smoothstep(g_water_level, g_water_level + 0.1, pp_static.world_space_position.z));
#endif
		calculate_add_decal_deferred(pp_static, pp_modifiable, In, decal_emission_ambient_term, PositionWS_DX, PositionWS_DY);
		calculate_weather_effects(In, pp_static, pp_modifiable, world_to_uv, world_to_uv_dxdy);
	}
#endif

	direct_lighting_info l_info = get_lighting_info(pp_static.world_space_position, pp_static.screen_space_position);

#if defined(NO_SHADOWS)
	l_info.light_amount = 1;
#endif

	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	float sky_visibility;

	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy,
		pp_static.view_vector, pp_modifiable.specularity.xy, pp_modifiable.albedo_color, l_info.light_amount,
		specular_ambient_term, diffuse_ambient_term, sky_visibility);

	float3 ambient_light = pp_modifiable.albedo_color.rgb * diffuse_ambient_term;
	ambient_light *= 1.0 - pp_modifiable.specularity.x;
	ambient_light += specular_ambient_term;
	float3 final_color = ambient_light * pp_modifiable.ambient_ao_factor;
	float3 sun_lighting = 0;

	{
#ifdef STANDART_FOR_HORSE
		sun_lighting = compute_direct_horse_lighting(l_info, pp_modifiable.specularity, pp_modifiable.albedo_color.rgb,
			pp_modifiable.world_space_normal, pp_static.view_vector, pp_static.world_space_position,
			pp_static.screen_space_position, pp_modifiable.ambient_ao_factor);

		sun_lighting += compute_anisotropic_specular(In, pp_static, pp_modifiable, l_info.light_direction) * l_info.light_color * l_info.light_amount;
		sun_lighting += compute_secondary_anisotropic_specular(In, pp_static, pp_modifiable, l_info.light_direction) * l_info.light_color * l_info.light_amount;

#else
		sun_lighting = compute_direct_lighting(l_info, pp_modifiable.specularity, pp_modifiable.albedo_color.rgb,
			pp_modifiable.world_space_normal, pp_static.view_vector, pp_static.world_space_position,
			pp_static.screen_space_position, pp_modifiable.ambient_ao_factor);
#endif

#ifdef WATER_RENDERING
		final_color += sun_lighting;
#else
		final_color += sun_lighting * pp_modifiable.diffuse_ao_factor;
#endif

	}

#if VDECL_HAS_DOUBLEUV
#ifdef ADDITIVE_LIGHTMAP
	float3 light_map_lighting = sample_detail_normal_texture(In.tex_coord.zw) * g_mesh_vector_argument.www;
	INPUT_TEX_GAMMA(light_map_lighting.rgb);
	final_color += light_map_lighting * pp_modifiable.albedo_color.rgb;
#endif
#endif

#if SELF_ILLUMINATION
	float3 color_factor = float3(1, 1, 1);
	float2 tex_coord = 0;
#if USE_VERTEX_COLORS
	color_factor = In.vertex_color.rgb;
#endif
	tex_coord = In.tex_coord.xy;

	float3 illumination_color = g_mesh_factor_color.rgb * color_factor;
	apply_self_illumination(In, pp_modifiable, final_color.rgb, tex_coord.xy, pp_modifiable.world_space_normal, pp_static.world_space_position, illumination_color);
#endif

	final_color.rgb += decal_emission_ambient_term;

#ifdef USE_POINT_LIGHTS
	[branch]
	if (g_use_tiled_rendering) // == 1
	{
#ifdef SYSTEM_SHOW_TILED_LIGHT_OVERDRAW
		float light_tile_heatmap_weight = 0;
#endif 
		float3 total_color = 0;
		float2 ss_pos = saturate(pp_static.screen_space_position);
		uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		uint2 tile_index = (ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE;
		uint start_index = MAX_LIGHT_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint probe_index = visible_lights_wDepth[start_index];

		float total_weight = 0;

		float4 occ_vec = sample_ssao_texture(pp_static.screen_space_position);

		while (probe_index != 0xFFFF)
		{
#ifdef SYSTEM_SHOW_TILED_LIGHT_OVERDRAW
			light_tile_heatmap_weight += 1 / g_tiled_lights_overdraw_visualize_limit;
#endif 
			total_color += compute_point_light_contribution_standard(probe_index, pp_modifiable.specularity, pp_modifiable.albedo_color, pp_modifiable.world_space_normal,
				pp_static.view_vector, pp_static.world_space_position, pp_static.screen_space_position, occ_vec, pp_modifiable.vertex_normal);
			probe_index = visible_lights_wDepth[++start_index];
		}

#ifdef SYSTEM_SHOW_TILED_LIGHT_OVERDRAW
		final_color.rgb += heat_map(light_tile_heatmap_weight);
#endif 

		final_color.rgb += (total_color);
	}
#endif

	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);
	//apply_new_fog(final_color.rgb, pp_static.world_space_position);

	if (bool(USE_SHADOW_DEBUGGING))
	{
		int index = compute_shadow_index(pp_static.world_space_position);

		if (index == 4)
		{
			final_color.rgb *= float3(1, 1, 1);
		}
		else if (index == 3)
		{
			final_color.rgb *= float3(1, 0, 1);
		}
		else if (index == 2)
		{
			final_color.rgb *= float3(0, 0, 1);
		}
		else if (index == 1)
		{
			final_color.rgb *= float3(0, 1, 0);
		}
		else
		{
			final_color.rgb *= float3(1, 0, 0);
		}
	}

#if IS_GRASS
	//float3 view_dir = normalize(pp_static.world_space_position - g_camera_position.xyz);
	float NdotL = saturate(dot(g_sun_direction_inv, pp_modifiable.world_space_normal * float3(-1, -1, 1)));
	float3 translucency_light = pp_modifiable.albedo_color.rgb * sun_lighting;
	final_color.rgb += saturate(translucency_light * NdotL);
#endif

#if USE_EXPOSURE_COMPENSATION
	float pre_exposure_value = get_pre_exposure();
	final_color.rgb = (pp_modifiable.albedo_color.rgb / pre_exposure_value) * g_material_exposure_compensation;
#endif

	Output.RGBColor.rgb = output_color(final_color.rgb);
	Output.RGBColor.a = pp_modifiable.early_alpha_value;
#ifdef MATTE_SHADOW
	Output.RGBColor.a = saturate(1.0f - l_info.light_amount) * (g_mesh_vector_argument.x / 255.0f);
#endif
#endif
}


void accumulate_light_contributions_face(Pixel_shader_input_type In, Per_pixel_static_variables pp_static, Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	return;
}

void accumulate_light_contributions_hair_aniso(Pixel_shader_input_type In, Per_pixel_static_variables pp_static, Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	return;
}

void accumulate_light_contributions_eye(Pixel_shader_input_type In, Per_pixel_static_variables pp_static, Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	return;
}

#endif
#endif
#endif


