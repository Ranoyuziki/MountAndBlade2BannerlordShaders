#ifndef FORWARD_FACE_FUNCTIONS_RSH
#define FORWARD_FACE_FUNCTIONS_RSH

#include "face.rsh"

#if PIXEL_SHADER
//delegates for generation
#if (VERTEX_DECLARATION != VDECL_POSTFX)
void calculate_alpha_face(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
		float lod_level = diffuse_texture.CalculateLevelOfDetailUnclamped(anisotropic_sampler, In.tex_coord.xy);
		pp_aux.tex_col = pp_modifiable.diffuse_sample;// sample_diffuse_texture_level(anisotropic_sampler, float4(saturate(In.tex_coord.xy), 0, lod_level));
		//INPUT_TEX_GAMMA(pp_aux.tex_col.rgb);

#if USE_SMOOTH_FADE_OUT
		dithered_fade_out(pp_static.screen_space_position, g_mesh_factor_color.a);
#endif
	
	float early_alpha_value = 1.0;
	if (!HAS_MATERIAL_FLAG(g_mf_do_not_use_alpha))
	{
		early_alpha_value = pp_aux.tex_col.a;
	}
	
	pp_modifiable.early_alpha_value = early_alpha_value;
	
}
void calculate_normal_face(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if !defined(SHADOWMAP_PASS)
#if SYSTEM_BLOOD_LAYER
	compute_blood_amount(In, pp_aux.decal_albedo_alpha, pp_aux.decal_normal, pp_aux.decal_specularity, In.local_position.xyz, In.local_normal);
#endif

	float3 _world_space_normal;
		#if USE_OBJECT_SPACE_TANGENT
			float3 world_binormal = cross(In.world_normal.xyz, normalize(In.world_tangent.xyz)) * In.world_tangent.w;
			float3x3 TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
		#else
			float3x3 TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord.xy);
		#endif	
		float3 normalTS = pp_modifiable.normal_sample;
		float3 normalTS_old = pp_modifiable.normal2_sample;

		// 			normalTS.y = 1.0 - normalTS.y;
		// 			normalTS_old.y = 1.0 - normalTS_old.y;
		float oldness = saturate(1.0f - g_mesh_factor2_color.a);
		normalTS = lerp(normalTS, normalTS_old, oldness);

	if (g_mesh_vector_argument_2.y > 0.5f)
		{
			float3 normalTS2;
			normalTS2.xy = (2.0f * sample_texture(TattooNormalMap, linear_sampler, In.tex_coord.xy).rg - 1.0);
			normalTS2.xy *= g_normalmap_power;
			normalTS2.z = sqrt(1.0f - saturate(dot(normalTS2.xy, normalTS2.xy)));
			float alpha = sample_texture(TattooDiffuseMap, anisotropic_sampler, In.tex_coord.xy).a;
			normalTS.xyz = lerp(normalTS.xyz, float3(normalTS.xy * 0.5 + normalTS2.xy, normalTS.z), alpha);
		}

#if !SYSTEM_DXT5_NORMALMAP && !SYSTEM_BC5_NORMALMAP
		if (g_normalmap_power != 1.0f)
		{
			normalTS.xy *= g_normalmap_power;
			normalTS = normalize(normalTS);
		}
#endif


#if SYSTEM_BLOOD_LAYER
		{
			if (pp_aux.decal_albedo_alpha.a > 0.0)
			{
				normalTS.xyz = normalize(normalTS.xyz);
				pp_aux.decal_normal.xyz = normalize(pp_aux.decal_normal.xyz);
				normalTS.xyz = normalize(float3(normalTS.xy + pp_aux.decal_normal.xy, normalTS.z));
			}
		}
#endif

#if VDECL_HAS_TANGENT_DATA
	{
		_world_space_normal = mul(normalize(normalTS), TBN);
	}
#else // VDECL_HAS_TANGENT_DATA
	{
#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS)
		_world_space_normal = normalize(In.world_normal.xyz);
#endif
	}
#endif // VDECL_HAS_TANGENT_DATA

	pp_modifiable.world_space_normal = _world_space_normal;
	pp_modifiable.vertex_normal = In.world_normal.xyz;
#endif

}

void calculate_albedo_face(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 tattoo_col = float4(0, 0, 0, 0);

	#ifndef DEFERRED_LIGHTING
		#if TATTOOED_FACE
			tattoo_col = sample_texture(TattooDiffuseMap, anisotropic_sampler, In.tex_coord.xy);
	if (g_mesh_vector_argument_2.y > 0.5f)
			{
			INPUT_TEX_GAMMA(tattoo_col.rgb);
			tattoo_col.rgb *= g_mesh_factor_color.rgb;
			}
		#endif
	#endif
	
	float4 tex_col = pp_aux.tex_col;

	float oldness = saturate(1.0f - g_mesh_factor2_color.a);
	float3 old_albedo = pp_modifiable.diffuse2_sample.rgb;
	INPUT_TEX_GAMMA(old_albedo);
	tex_col.rgb = lerp(tex_col.rgb, old_albedo, oldness);
	tex_col.rgb *= g_mesh_factor_color.rgb;
	
	//Face color adjustment according to hair color.
	float3 eyebrow_col = g_mesh_factor2_color.rgb;
	
	#if SYSTEM_BLOOD_LAYER
		{
			tex_col.rgb = lerp(tex_col.xyz, blend_hardlight(tex_col.xyz, pp_aux.decal_albedo_alpha.xyz * 0.75), pp_aux.decal_albedo_alpha.a);
		}
	#endif
	

	if (g_mesh_vector_argument_2.x > 0.5f)
	{
		if (g_mesh_vector_argument_2.y < 0.5f)
		{
				//we are always using 2 team colors on meshes
				float colormap_r = tattoo_col.r;
				float colormap_g = tattoo_col.g;

				float3 real_g_mesh_factor2_color = saturate(g_mesh_vector_argument.rgb);
				INPUT_TEX_GAMMA(real_g_mesh_factor2_color.rgb);
				float3 tatto_ble = tattoo_col.bbb;

					tattoo_col.rgb = lerp(0, tatto_ble, colormap_g);
					tattoo_col.rgb = lerp(tattoo_col.rgb, tatto_ble * real_g_mesh_factor2_color.rgb, colormap_r);
				}

		tex_col.rgb = lerp(tex_col.rgb, tattoo_col.rgb, tattoo_col.a);
	}

	if (bool(SYSTEM_RAIN_LAYER))
	{
		tex_col.rgb *= lerp(1.0, 0.3, g_rain_density);    
	}

// 	#if TATTOOED_FACE
// 		if(bool(HAS_DIRT))	//dirt
// 		{
// 			float dirt_amount = sample_diffuse_texture(linear_sampler, (In.tex_coord.zw)).a * g_mesh_vector_argument.w;
// 			tex_col.rgb = lerp(tex_col.rgb, tex_col.rgb * float3(0.76f, 0.52f, 0.4f), dirt_amount);
// 		}
// 	#endif


#ifdef SYSTEM_TEXTURE_DENSITY
	tex_col.rgb = checkerboard(tex_col, In.tex_coord.xy, diffuse_texture, false, In.world_position.xyz);
#endif

	pp_modifiable.albedo_color = tex_col.rgb;
}
void calculate_specular_face(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.specularity = pp_modifiable.specular_sample.xy;// sample_specular_texture(In.tex_coord.xy).rg;
	pp_modifiable.specularity.x *= g_specular_coef;
	pp_modifiable.specularity.y *= g_gloss_coef;

#if SYSTEM_BLOOD_LAYER
	pp_modifiable.specularity.x = lerp(pp_modifiable.specularity.x, 1, smoothstep(0.0, 1.0, pp_aux.decal_albedo_alpha.a));	
	pp_modifiable.specularity.y = lerp(pp_modifiable.specularity.y, 0.75, smoothstep(0.0, 1.0, pp_aux.decal_albedo_alpha.a));
#else
	pp_modifiable.specularity.x = saturate(pp_modifiable.specularity.x);
	pp_modifiable.specularity.y = saturate(pp_modifiable.specularity.y);
#endif
}

void calculate_ao_face_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
	pp_modifiable.ambient_ao_factor = pp_modifiable.specular_sample.z;// sample_specular_texture(In.tex_coord.xy).b;
	}
	else
	{
	pp_modifiable.ambient_ao_factor = 1;
	}
	pp_modifiable.diffuse_ao_factor = 1.0f;
}

void calculate_ao_face_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float occ = pp_modifiable.specular_sample.z;// sample_specular_texture(In.tex_coord.xy).b;

	float ao_factor = 1.0;
	float diffuse_occlusion_factor = 1.0;
	float ambient_occlusion_factor = 1.0;

	ambient_occlusion_factor = diffuse_occlusion_factor = sample_ssao_texture(pp_static.screen_space_position).r;

	ambient_occlusion_factor = max(ambient_occlusion_factor, 0.05);

	pp_modifiable.ambient_ao_factor = ambient_occlusion_factor * occ;
	pp_modifiable.diffuse_ao_factor = diffuse_occlusion_factor;
	pp_modifiable.occ = occ;
}
#endif

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)

float3 compute_transmittance(float depth1, float depth2, float far_plane, float3 light_vector, float3 normal_vector)
{
	float3 transmittance = 0;

	float scale = 8.25 * saturate(1.0 - 8.5 * 0.1) / (0.016 * 0.2);

	float dd1 = (depth1	* far_plane);
	float dd2 = (depth2	* far_plane);
	float d = scale * abs(dd1 - dd2);// abs(d1 - d2);

	float dd = -d * d;
	float3 profile = float3(0.233, 0.455, 0.649) * exp(dd / 0.0064) +
		float3(0.1, 0.336, 0.344) * exp(dd / 0.0484) +
		float3(0.118, 0.198, 0.0)   * exp(dd / 0.187) +
		float3(0.113, 0.007, 0.007) * exp(dd / 0.567) +
		float3(0.358, 0.004, 0.0)   * exp(dd / 1.99) +
		float3(0.078, 0.0, 0.0)   * exp(dd / 7.41);

	transmittance = profile * saturate(0.3 + dot(light_vector, -normal_vector));

	return transmittance;
	}


float3 compute_transmittance_spot_light(float depth1, float depth2, float proj22, float proj32, float3 light_vector, float3 normal_vector)
{
	float3 transmittance = 0;

	float scale = 8.25 * saturate(1.0 - 8.5 * 0.1) / (0.016 * 0.3);

	float dd1 = proj32 / (depth1 + proj22);
	float dd2 = proj32 / (depth2 + proj22);
	float d = scale * abs(dd1 - dd2);// abs(d1 - d2);

	float dd = -d * d;
	float3 profile = float3(0.233, 0.455, 0.649) * exp(dd / 0.0064) +
		float3(0.1, 0.336, 0.344) * exp(dd / 0.0484) +
		float3(0.118, 0.198, 0.0)   * exp(dd / 0.187) +
		float3(0.113, 0.007, 0.007) * exp(dd / 0.567) +
		float3(0.358, 0.004, 0.0)   * exp(dd / 1.99) +
		float3(0.078, 0.0, 0.0)   * exp(dd / 7.41);

	transmittance = profile * saturate(0.3 + dot(light_vector, -normal_vector));

	return transmittance;
}


float3 compute_point_light_contribution_face(inout Pixel_shader_input_type In, int light_id, float2 specularity_info, float3 albedo_color,
	float3 world_space_normal, float3 view_direction,
	float3 world_space_position, float2 screen_space_position, float4 occ_vec, bool use_specular)
{
	bool is_spotlight = visible_lights_params[light_id].spotlight_and_direction.x;

	float3 world_point_to_light = visible_lights_params[light_id].position.xyz - world_space_position;
	float world_point_to_light_len = length(world_point_to_light);

	float radius = visible_lights_params[light_id].color.w;
	float dist_to_light_n = world_point_to_light_len / radius;

	bool is_volumetric = visible_lights_params[light_id].spotlight_hotspot_angle_and_falloff_angle_and_clip_plane_and_volumetric.w;

	if (!is_volumetric && dist_to_light_n > 1.0f)
	{
		return float3(0, 0, 0);
	}

	float ambient_occlusion_factor = 1.0f;
	float diffuse_occlusion_factor = 1.0f;

	float3 light_color = visible_lights_params[light_id].color.rgb;
#ifdef TRANSLUCENT
	float4 shadow_sample_pos = float4(world_space_position.xyz + 0.16 * 0.005 * 2.0 * normalize(In.world_normal.xyz), 1.0);
#else
	float4 shadow_sample_pos = float4(world_space_position.xyz, 1.0);
#endif

	float _light_attenuation;
	float light_amount;
	[branch]
	if (is_spotlight)
	{
		_light_attenuation = compute_light_attenuation_spot(light_id, world_point_to_light, radius);
		light_amount = calculate_spot_light_shadow(-world_point_to_light, shadow_sample_pos.xyz, light_id);
	}
	else
	{
		_light_attenuation = compute_light_attenuation_point(light_id, world_point_to_light, radius);
		light_amount = calculate_point_light_shadow(-world_point_to_light, shadow_sample_pos.xyz, light_id);
	}

	float3 light_direction = world_point_to_light / world_point_to_light_len;

	float NdotL = saturate(dot(light_direction, world_space_normal.xyz));
	float3 diffuse_lighting = compute_diffuse_face_lighting(albedo_color.rgb, light_color, light_amount, ambient_occlusion_factor, NdotL);
	float3 final_diffuse_lighting = (diffuse_lighting)* _light_attenuation * diffuse_occlusion_factor;

	if (use_specular)
	{
		final_diffuse_lighting *= albedo_color;
		float3 specular_lighting = compute_specular_face_lighting(In, specularity_info, light_color, light_amount,
			world_space_normal, view_direction, light_direction, world_space_position, ambient_occlusion_factor);


		final_diffuse_lighting += (specular_lighting)* _light_attenuation * diffuse_occlusion_factor;
	}

#ifdef TRANSLUCENT
	float4 shrinkedPos = float4(world_space_position.xyz - 0.0005 * 3.0 * normalize(In.world_normal.xyz), 1.0);
	int shadow_index = visible_lights_params[light_id].shadow_params_index;

	float3 transmittance = 0;
	[branch]
	if (is_spotlight && visible_lights_params[light_id].shadowradius_and_attenuation_and_invsize_and_shadowed.w > 0.0)
	{
		float4 shadow_tc = mul(visible_light_shadow_params[light_id].shadow_view_proj[0], float4(shrinkedPos.xyz, 1));
		shadow_tc.xyz = shadow_tc.xyz / shadow_tc.w;

		shadow_tc.x = shadow_tc.x / 2 + 0.5;
		shadow_tc.y = shadow_tc.y / 2 + 0.5;
		shadow_tc.y = 1.0 - shadow_tc.y;

		shadow_tc.xy *= visible_light_shadow_params[light_id].shadow_offset_and_bias[0].zw;
		shadow_tc.xy += visible_light_shadow_params[light_id].shadow_offset_and_bias[0].xy;

		float d1 = lights_shadow_texture.SampleLevel(linear_sampler, shadow_tc.xy, 0).r;

		transmittance = compute_transmittance_spot_light(d1, shadow_tc.z, visible_lights_params[light_id].spotlight_proj22_and_proj32.x, 
										visible_lights_params[light_id].spotlight_proj22_and_proj32.y, light_direction, In.world_normal.xyz);
	}

	final_diffuse_lighting += transmittance * albedo_color.rgb * light_color.rgb * _light_attenuation * diffuse_occlusion_factor;
#endif

	return final_diffuse_lighting;
}


float3 compute_point_light_contribution_face_specular(inout Pixel_shader_input_type In, int light_id, float2 specularity_info, float3 albedo_color,
	float3 world_space_normal, float3 view_direction,
	float3 world_space_position, float2 screen_space_position, float4 occ_vec)
{
	bool is_spotlight = visible_lights_params[light_id].spotlight_and_direction.x;

	float3 world_point_to_light = visible_lights_params[light_id].position.xyz - world_space_position;
	float world_point_to_light_len = length(world_point_to_light);

	float radius = visible_lights_params[light_id].color.w;
	float dist_to_light_n = world_point_to_light_len / radius;

	if (dist_to_light_n > 1.0f)
	{
		return float3(0, 0, 0);
	}

	float3 light_direction = world_point_to_light / world_point_to_light_len;

	float NdotL = saturate(dot(world_space_normal.xyz, light_direction));

	//add specular terms 
	float3 result_color = 0;
	float3 specular_light = 0;
	float3 sun_lighting = 0;


	float ambient_occlusion_factor = 1.0f;
	float diffuse_occlusion_factor = 1.0f;


	float3 light_color = visible_lights_params[light_id].color.rgb;

	float _light_attenuation;
	float light_amount;
	float4 outward = float4(world_space_position.xyz + 0.16 * 0.005 * 2.0 * normalize(world_space_normal.xyz), 1.0);
	[branch]
	if (is_spotlight)
	{
		_light_attenuation = compute_light_attenuation_spot(light_id, world_point_to_light, radius);
		light_amount = calculate_spot_light_shadow(-world_point_to_light, outward.xyz, light_id);
	}
	else
	{
		_light_attenuation = compute_light_attenuation_point(light_id, world_point_to_light, radius);
		light_amount = calculate_point_light_shadow(-world_point_to_light, outward.xyz, light_id);
	}


	float3 specular_lighting = compute_specular_face_lighting(In, specularity_info, light_color, light_amount,
		world_space_normal, view_direction, light_direction, world_space_position, ambient_occlusion_factor);


	return (specular_lighting)* _light_attenuation * diffuse_occlusion_factor;
}


void calculate_final_color_face(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output, bool use_specular)
{
	float sun_amount = 1;

#ifdef TRANSLUCENT
	float4 outward = float4(pp_static.world_space_position.xyz + 0.16 * 0.005 * 2.0 * normalize(In.world_normal.xyz), 1.0);
	direct_lighting_info l_info = get_lighting_info(outward.xyz, pp_static.screen_space_position);

	float d1 = 0;
	float4 tex_coord = 0;

	float4 shrinkedPos = float4(pp_static.world_space_position.xyz - 0.16 * 0.005 * 3.0 * normalize(In.world_normal.xyz), 1.0);

			tex_coord = float4(mul(g_dynamic_sun_view_proj_arr[0], float4(shrinkedPos.xyz, 1)).xyz, 0);
			d1 = character_shadow_texture.SampleLevel(linear_sampler, float3(tex_coord.xy, 0), 0).r;

	float3 transmittance = compute_transmittance(d1, tex_coord.z, g_shadow_cascade_0_far, g_sun_direction_inv, In.world_normal.xyz);
#else
	direct_lighting_info l_info = get_lighting_info(pp_static.world_space_position.xyz, pp_static.screen_space_position);
#endif

#ifdef OUTER_MESH_RENDERING
	l_info.light_amount = 1;
#endif
	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	float sky_visibility;

	//*0 spec and *0.25 gloss is need for consistensy between ggx ambient, and skin direct specular
	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy,
		pp_static.view_vector, float2(0, pp_modifiable.specularity.y * 0.25), pp_modifiable.albedo_color, l_info.light_amount,
		specular_ambient_term, diffuse_ambient_term, sky_visibility);
	
	float3 ambient_light = diffuse_ambient_term;
	if (use_specular)
	{
		ambient_light *= pp_modifiable.albedo_color;
		ambient_light += specular_ambient_term;
	}
	float3 final_color = ambient_light * pp_modifiable.ambient_ao_factor;

	float NdotL = 0;
	{
		float3 wsn = normalize(pp_modifiable.world_space_normal.xyz);
		NdotL = saturate(dot(wsn.xyz, g_sun_direction_inv));

		float3 diffuse_light = compute_diffuse_face_lighting(pp_modifiable.albedo_color.rgb, g_sun_color.rgb, l_info.light_amount, pp_modifiable.diffuse_ao_factor, NdotL);

		if (use_specular)
		{
			final_color += diffuse_light * pp_modifiable.albedo_color;
			float3 specular_light = compute_specular_face_lighting(In, pp_modifiable.specularity, g_sun_color.rgb, l_info.light_amount,
				pp_modifiable.world_space_normal, pp_static.view_vector, g_sun_direction_inv, pp_static.world_space_position, pp_modifiable.diffuse_ao_factor);

			final_color += specular_light;
		}
		else
		{
			final_color += diffuse_light;
		}

#ifdef USE_POINT_LIGHTS
		//final_color = 0;
		//compute point lights
		[branch]
		if (g_use_tiled_rendering > 0.0)
		{
			float3 total_color = 0;
			float2 ss_pos = saturate(pp_static.screen_space_position);
			uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
			uint2 tile_index = (ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE;
			uint start_index = MAX_LIGHT_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
			uint probe_index = visible_lights_wDepth[start_index];

			float total_weight = 0;

			float4 occ_vec = sample_ssao_texture(pp_static.screen_space_position);

			[loop]
			while (probe_index != 0xFFFF)
			{
				total_color += compute_point_light_contribution_face(In, probe_index, pp_modifiable.specularity, pp_modifiable.albedo_color, wsn,
					pp_static.view_vector, pp_static.world_space_position, pp_static.screen_space_position, occ_vec, use_specular);

		
				// 				total_color += compute_point_light_contribution_standard(probe_index, pp_modifiable.specularity, pp_modifiable.albedo_color, pp_modifiable.world_space_normal,
				// 					pp_static.view_vector, pp_static.world_space_position, pp_static.screen_space_position, occ_vec);
		
				start_index++;
				probe_index = visible_lights_wDepth[start_index];
			}

			final_color.rgb += total_color;
		}
#endif
	}

#ifdef TRANSLUCENT
	final_color.rgb += transmittance * g_sun_color.rgb * pp_modifiable.albedo_color.rgb * pp_modifiable.diffuse_ao_factor;
#endif // TRANSLUCENT

	if (bool(USE_SHADOW_DEBUGGING))
	{
		int index = compute_shadow_index(pp_static.world_space_position);

		if (index == 4)
		{
			Output.RGBColor.rgb = float3(1, 1, 1);
		}
		else if (index == 3)
		{
			Output.RGBColor.rgb = float3(1, 0, 1);
		}
		else if (index == 2)
		{
			Output.RGBColor.rgb = float3(0, 0, 1);
		}
		else if (index == 1)
		{
			Output.RGBColor.rgb = float3(0, 1, 0);
		}
		else
		{
			Output.RGBColor.rgb = float3(1, 0, 0);
		}
	}

	if (use_specular)
	{
		apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);
		Output.RGBColor.rgb = output_color(final_color.rgb);
	}
	else
	{
		Output.RGBColor.rgb = output_color(final_color.rgb);
	}

	//Output.RGBColor.rgb = g_sun_color * saturate(pp_modifiable.world_space_normal.x);
	Output.RGBColor.a = pp_modifiable.early_alpha_value;
}

void calculate_final_color_face_wo_specular(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	calculate_final_color_face(In, pp_static, pp_modifiable, Output, false);
}

void calculate_final_color_face_specular(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float4 outward = float4(pp_static.world_space_position.xyz + 0.16 * 0.005 * 2.0 * normalize(pp_modifiable.world_space_normal.xyz), 1.0);
	direct_lighting_info l_info = get_lighting_info(outward.xyz, pp_static.screen_space_position);

#ifdef OUTER_MESH_RENDERING
	l_info.light_amount = 1;
#endif

	float3 final_color = 0;
	final_color = pp_modifiable.albedo_color.rgb * sample_texture(texture8, point_clamp_sampler, pp_static.screen_space_position.xy).rgb;
	final_color.rgb = final_color.rgb / get_pre_exposure();
	
	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	float sky_visibility;

	//*0 spec and *0.25 gloss is need for consistensy between ggx ambient, and skin direct specular
	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy,
		pp_static.view_vector, float2(0, pp_modifiable.specularity.y * 0.25), pp_modifiable.albedo_color, l_info.light_amount,
		specular_ambient_term, diffuse_ambient_term, sky_visibility);

	final_color += specular_ambient_term * pp_modifiable.ambient_ao_factor;

	{
		float3 wsn = normalize(pp_modifiable.world_space_normal.xyz);
		float NdotL = saturate(dot(wsn.xyz, g_sun_direction_inv));

		float3 specular_light = compute_specular_face_lighting(In, pp_modifiable.specularity, g_sun_color.rgb, l_info.light_amount,
			pp_modifiable.world_space_normal, pp_static.view_vector, g_sun_direction_inv, pp_static.world_space_position, pp_modifiable.diffuse_ao_factor);

		final_color += specular_light;

#ifdef USE_POINT_LIGHTS
		//compute point lights
		[branch]
		if (g_use_tiled_rendering > 0.0)
		{
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
				total_color += compute_point_light_contribution_face_specular(In, probe_index, pp_modifiable.specularity, pp_modifiable.albedo_color, wsn,
					pp_static.view_vector, pp_static.world_space_position, pp_static.screen_space_position, occ_vec);


				// 				total_color += compute_point_liwwwwght_contribution_standard(probe_index, pp_modifiable.specularity, pp_modifiable.albedo_color, pp_modifiable.world_space_normal,
				// 					pp_static.view_vector, pp_static.world_space_position, pp_static.screen_space_position, occ_vec);

				start_index++;
				probe_index = visible_lights_wDepth[start_index];
			}

			final_color.rgb += total_color;

		}
#endif

	}


	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);

	if (bool(USE_SHADOW_DEBUGGING))
	{
		int index = compute_shadow_index(pp_static.world_space_position);

		if (index == 4)
		{
			Output.RGBColor.rgb = float3(1, 1, 1);
		}
		else if (index == 3)
		{
			Output.RGBColor.rgb = float3(1, 0, 1);
		}
		else if (index == 2)
		{
			Output.RGBColor.rgb = float3(0, 0, 1);
		}
		else if (index == 1)
		{
			Output.RGBColor.rgb = float3(0, 1, 0);
		}
		else
		{
			Output.RGBColor.rgb = float3(1, 0, 0);
		}
	}

	Output.RGBColor.rgb = output_color(final_color.rgb);
	//Output.RGBColor.rgb = g_sun_color * saturate(pp_modifiable.world_space_normal.x);
	Output.RGBColor.a = pp_modifiable.early_alpha_value;
}

#endif


#endif

#endif
