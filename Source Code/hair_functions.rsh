#ifndef HAIR_FUNCTIONS_RSH
#define HAIR_FUNCTIONS_RSH

#define DiffuseMap					texture0	
#define	HairShiftandNoiseMap 		texture1		 

#if VERTEX_SHADER
//main vertex shader functions for aniso hair
void calculate_object_space_values_hair_aniso(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	
	#if !defined(SHADOWMAP_PASS)
		#if SYSTEM_BLOOD_LAYER
			float4 qtangent = float4(0, 0, 0, 1);
			#if !VDECL_HAS_SKIN_DATA
				qtangent = In.qtangent;
			#endif
			output.local_position = In.position.xyz;
			output.local_normal = get_in_normal(In, normalize(qtangent));
		#endif
	#endif

	float4 object_position;
	float4 object_tangent;
	float3 object_binormal, object_normal, prev_object_position, object_color;

	rgl_vertex_transform_with_binormal(In, object_position, object_normal, object_tangent, object_binormal, prev_object_position, object_color);

	output.position = mul(g_view_proj, mul(g_world, object_position));
	
	pv_modifiable.object_position = object_position;
	pv_modifiable.object_normal = object_normal;
	pv_modifiable.object_tangent = object_tangent;
	pv_modifiable.object_binormal = object_binormal;
	
	pv_modifiable.prev_object_position = prev_object_position;
	
#if SYSTEM_WRITE_MOTION_VECTORS
	#if VDECL_HAS_SKIN_DATA
		output.prev_object_space_position = prev_object_position;
		output.object_space_position = object_position.xyz;
	#endif
#endif

}
void calculate_world_space_values_hair_aniso(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
#if !defined(SHADOWMAP_PASS)
	float4 world_position = mul(g_world, pv_modifiable.object_position);
	float3 world_normal = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal.xyz).xyz);  //normal in g_world space
	
	Out.world_position = world_position;
	Out.world_normal = world_normal;

	#if VDECL_HAS_TANGENT_DATA
		Out.world_tangent.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_tangent.xyz));
		Out.world_tangent.w = pv_modifiable.object_tangent.w;
	#else
		Out.world_tangent.xyz = normalize(mul(to_float3x3(g_world), float3(1, 0, 0)));
		Out.world_tangent.w = 1.0f;
	#endif
	
	Out.world_position.xyz = world_position.xyz;

#ifdef POINTLIGHT_SHADOWMAP_PASS
	{
#if SYSTEM_INSTANCING_ENABLED
		int face_index = In.instanceID / g_zero_constant_output;
#else
		int face_index = In.instanceID;
#endif
		uint light_face_id = light_faces[g_light_face_id + face_index];
		uint light_index = light_face_id / 6;
		uint face = light_face_id % 6;
		int shadow_index = visible_lights_params[light_index].shadow_params_index;
		float4 shadow_tc = mul(visible_light_shadow_params[shadow_index].shadow_view_proj[face], float4(world_position.xyz, 1));

		float4 shadow_tc_copy = shadow_tc;
		shadow_tc.xyz = shadow_tc.xyz / (shadow_tc.w);
		shadow_tc.x = shadow_tc.x / 2 + 0.5;
		shadow_tc.y = shadow_tc.y / 2 + 0.5;
		shadow_tc.y = 1.0 - shadow_tc.y;

		shadow_tc.xy *= visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].zw;
		shadow_tc.xy += visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].xy;
		shadow_tc.xy = shadow_tc.xy * 2.0 - 1.0f;
		shadow_tc.y *= -1;

		Out.position = float4(shadow_tc.xyz * shadow_tc_copy.w, shadow_tc_copy.w);

		[unroll]
		for(uint i = 0; i < 4; i++)
		{
			Out.clip_distances[i] = GetClipDistance(world_position.xyz, visible_lights_params[light_index].position.xyz, light_index, face, i);
		}
	}
#endif
#endif

#if ENABLE_DYNAMIC_INSTANCING
	Out.world_position.w = In.instanceID + INDEX_EPSILON;
#endif

	pv_modifiable.world_position = Out.world_position;

}
void calculate_render_related_values_hair_aniso(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
	Out.tex_coord = In.tex_coord;
#if !defined(SHADOWMAP_PASS)
	Out.vertex_color = get_vertex_color(In.color);
#endif

#if SYSTEM_USE_CUSTOM_CLIPPING
	if (!g_zero_constant_output)
	{
		Out.clip_distances[0] = GetCustomClipDistance(pv_modifiable.world_position.xyz, g_clipping_plane_position.xyz, g_clipping_plane_normal.xyz);
	}
#endif

#if defined(SYSTEM_CLOTH_SIMULATION_ENABLED) 
#if VDECL_HAS_SKIN_DATA && SYSTEM_WRITE_MOTION_VECTORS
	Out.object_space_position.x = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
	Out.object_space_position.y = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
	Out.object_space_position.z = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];
	Out.prev_object_space_position.x = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
	Out.prev_object_space_position.y = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
	Out.prev_object_space_position.z = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];
#endif
#endif
}
#endif

#if PIXEL_SHADER
float aniso_specular_term(float3 T, float3 H, float exponent)
{
	float dotTH = dot(T, H);
	float sinTH = sqrt(1.0 - saturate(dotTH*dotTH));
	float dirAtten = smoothstep(-1.0, 0.0, dotTH);
	return dirAtten * pow(sinTH, exponent);
}

float3 shift_aniso_tangent(float3 T, float3 N, float shiftAmount)
{
	return normalize(T + shiftAmount * N);
}

float3 calculate_anisotropic_specular(float3 specular_color, float specular_power, float3 normal, float3 tangent, float3 lightVec, float3 viewVec, float tangent_shift, float second_spec_mask)
{
	float2 specularExp = float2(specular_power, specular_power * 4);
	float3 specularColor1 = lerp(dot(specular_color, LUMINANCE_WEIGHTS), specular_color, 0.5);
	float3 specularColor2 = specular_color;


	float3 T1 = shift_aniso_tangent(tangent, normal, (2.0 * second_spec_mask - 1.0) * (-0.2) + (tangent_shift) * 0.46);
	float3 T2 = shift_aniso_tangent(tangent, normal, (2.0 * second_spec_mask - 1.0) * (-0.2) + (tangent_shift) * 0.511872);

	float3 H = normalize(lightVec + viewVec);

	float3 specular1 = specularColor1 * aniso_specular_term(T1, H, specularExp.y * 0.13);
	float3 specular2 = specularColor2 * aniso_specular_term(T2, H, specularExp.y * 0.0153);
	specular1 *= 5.8;
	specular2 *= 5.8;

	float3 final_specular = 0;
	final_specular += specular1;
	final_specular += specular2 * second_spec_mask;
	
	// 	if (g_debug_vector.z > 2)
	// 	{
	// 		final_specular += specular1;
	// 		final_specular += specular2 * second_spec_mask;
	// 	}
	// 	else if (g_debug_vector.z > 1)
	// 	{
	// 		final_specular += specular1;
	// 	}
	// 	else if (g_debug_vector.z > 0)
	// 	{
	// 		final_specular += specular2 * second_spec_mask;
	// 	}

	return final_specular;
}

float3 compute_hair_albedo(inout Pixel_shader_input_type In, float3 diffuse_texture_color, float4 vertex_color, float2 tex_coord)
{
	float3 hairBaseColor = g_mesh_factor_color.rgb;
	float old_texture_color = dot(diffuse_texture_color.rgb, LUMINANCE_WEIGHTS);

	float oldness = (1.0f - g_mesh_factor2_color.a);
	float oldness_alpha = saturate(vertex_color.b + oldness * 2.0f - 1.0f);

	float3 albedo = diffuse_texture_color;
	albedo.rgb = lerp(albedo.rgb * hairBaseColor, old_texture_color.xxx * lerp(hairBaseColor, float3(1,1,1), oldness * oldness), oldness_alpha);
	
#ifdef SYSTEM_TEXTURE_DENSITY
	albedo.rgb = checkerboard(albedo, tex_coord.xy, diffuse_texture, false, In.world_position.xyz);
#endif

	return albedo;
}

void aniso_hair_alpha_test_function(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
#if !defined(SHADOWMAP_PASS)
	float vertex_aniso_factor  = In.vertex_color.g;
	bool dont_do_alpha_testing = (g_mesh_factor2_color.x > 0);
	if(dont_do_alpha_testing == false)
	{
		apply_alpha_test(In, pp_modifiable.early_alpha_value);
	}
#else
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
#endif
}


//main pixel shader functions for aniso hair
void calculate_alpha_hair_aniso(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 _diffuse_texture_color = pp_modifiable.diffuse_sample;//sample_diffuse_texture(anisotropic_sampler, In.tex_coord);

	pp_modifiable.early_alpha_value =  _diffuse_texture_color.a * g_mesh_factor_color.a;

#if USE_SMOOTH_FADE_OUT
	dithered_fade_out(pp_static.screen_space_position, g_mesh_factor_color.a);
#endif
}

#if !defined(SHADOWMAP_PASS)

void calculate_normal_hair_aniso(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
#if SYSTEM_TWO_SIDED_RENDER
	pp_modifiable.world_space_normal = In.is_fronface ? normalize(In.world_normal.xyz) : normalize(-In.world_normal.xyz);
#else
	pp_modifiable.world_space_normal = normalize(In.world_normal.xyz);
#endif
	pp_modifiable.vertex_normal = pp_modifiable.world_space_normal;

	float4 decal_albedo_alpha = float4(0, 0, 0, 0);
	float3 decal_normal = float3(0, 0, 0);
	float2 decal_specularity = float2(0, 0);
#if SYSTEM_BLOOD_LAYER
	compute_blood_amount(In, decal_albedo_alpha, decal_normal, decal_specularity, In.local_position.xyz, In.local_normal);
#endif

	pp_aux.decal_albedo_alpha = decal_albedo_alpha;
	pp_aux.decal_normal = decal_normal;
	pp_aux.decal_specularity = decal_specularity;
}

void calculate_albedo_hair_aniso(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 _diffuse_texture_color = pp_modifiable.diffuse_sample;// sample_diffuse_texture(anisotropic_sampler, In.tex_coord);
	pp_aux.diffuse_texture_color = _diffuse_texture_color;
	pp_modifiable.albedo_color = compute_hair_albedo(In, _diffuse_texture_color.rgb, In.vertex_color, In.tex_coord);

#if SYSTEM_BLOOD_LAYER
	{
		pp_modifiable.albedo_color.rgb = lerp(pp_modifiable.albedo_color.xyz, blend_hardlight(pp_modifiable.albedo_color.xyz, pp_aux.decal_albedo_alpha.xyz), pp_aux.decal_albedo_alpha.a);
		pp_modifiable.specularity = lerp(float2(0.1, 0.1), float2(0, 0.95), pp_aux.decal_albedo_alpha.a);
	}
#else
		pp_modifiable.specularity = saturate(float2(0.1 * g_specular_coef, 0.2 * g_gloss_coef));
#endif
}

void calculate_ao_hair_aniso_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float diffuse_occlusion_factor = 1.0;
	float ambient_occlusion_factor = 1.0;

	#if SYSTEM_BLOOD_LAYER
	pp_modifiable.diffuse_ao_factor = (diffuse_occlusion_factor * In.vertex_color.r);
		pp_modifiable.ambient_ao_factor = lerp(ambient_occlusion_factor * In.vertex_color.r, 0.85, pp_aux.decal_albedo_alpha.a);
	#else
		pp_modifiable.diffuse_ao_factor = (diffuse_occlusion_factor * In.vertex_color.r);
		pp_modifiable.ambient_ao_factor = (ambient_occlusion_factor * In.vertex_color.r);
	#endif
}

void calculate_ao_hair_aniso_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float diffuse_occlusion_factor = 1.0;
	float ambient_occlusion_factor = 1.0;

	ambient_occlusion_factor = diffuse_occlusion_factor = sample_ssao_texture(pp_static.screen_space_position).r;

#if SYSTEM_BLOOD_LAYER
	pp_modifiable.diffuse_ao_factor = (diffuse_occlusion_factor * In.vertex_color.r);
	pp_modifiable.ambient_ao_factor = lerp(ambient_occlusion_factor * In.vertex_color.r, 0.85, pp_aux.decal_albedo_alpha.a);
#else
	pp_modifiable.diffuse_ao_factor = (diffuse_occlusion_factor * In.vertex_color.r);
	pp_modifiable.ambient_ao_factor = (ambient_occlusion_factor * In.vertex_color.r);
#endif
}

float3 compute_point_light_contribution_hair_aniso(int light_id, float2 specularity_info, float3 albedo_color,
											 float3 world_space_normal, float3 view_direction,
											 float3 world_space_position, float2 screen_space_position, float4 occ_vec, 
											 float3 vertex_color, float3 specular_color, float vertex_aniso_factor,
											 float3 world_fur_direction, float2 tex_coord, float tangent_shift, float second_spec_mask, Per_pixel_modifiable_variables pp_modifiable)
{
	bool is_spotlight = visible_lights_params[light_id].spotlight_and_direction.x;

	float3 world_point_to_light 	= visible_lights_params[light_id].position.xyz - world_space_position;
	float world_point_to_light_len	= length(world_point_to_light);

	float radius = visible_lights_params[light_id].color.w;
	float dist_to_light_n = world_point_to_light_len / radius;

	if(dist_to_light_n > 1.0f)
	{
		return float3(0, 0, 0);
	}

	float3 light_direction = world_point_to_light / world_point_to_light_len;


	float ambient_occlusion_factor = vertex_color.r;
	float diffuse_occlusion_factor = vertex_color.r;

	float3 light_color = visible_lights_params[light_id].color.rgb;
	float _light_attenuation;
	float light_amount;
	[branch]
	if (is_spotlight)
	{
		_light_attenuation = compute_light_attenuation_spot(light_id, world_point_to_light, radius);
		light_amount = calculate_spot_light_shadow(-world_point_to_light, world_space_position, light_id);
	}
	else
	{
		_light_attenuation = compute_light_attenuation_point(light_id, world_point_to_light, radius);
		light_amount = calculate_point_light_shadow(-world_point_to_light, world_space_position, light_id);
	}

	float ndotl = wrapped_ndotl(world_space_normal, light_direction, 0.0);

	float3 diffuse = diffuse_occlusion_factor * light_color.rgb * albedo_color * ndotl * light_amount * (1.0 - 0.1);

	float3 specular = float3(0,0,0);

#if USE_ANISO_SPECULAR	
	specular = calculate_anisotropic_specular(specular_color, pow(2, 10 * 1), world_space_normal, world_fur_direction.xyz, light_direction,
		view_direction, tangent_shift, second_spec_mask) * vertex_aniso_factor * 0.05 * 1;	//use specularity_info texture?
#endif

	float3 resulting_color =  diffuse;
	resulting_color += ndotl * vertex_color.g * specular * light_amount * light_color.rgb * ambient_occlusion_factor;

	return resulting_color * _light_attenuation * diffuse_occlusion_factor;
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_pbr_hair_aniso(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	float4 _diffuse_texture_color = sample_texture(DiffuseMap, anisotropic_sampler, In.tex_coord);

	float sun_amount = compute_sun_amount_from_cascades(In.world_position.xyz, pp_static.screen_space_position);

	float3 _final_albedo_color = pp_modifiable.albedo_color.rgb;
	float3 hairBaseColor = g_mesh_factor_color.rgb;
	float base_color_intensity = dot(hairBaseColor.rgb, LUMINANCE_WEIGHTS);	
	float2 _specularity_info = pp_modifiable.specularity;// (0, 0.602);//compute_specularity(In.tex_coord.xy, _world_space_normal.xyz, In.vertex_color, _blood_amount, _wetness_amount);

#if USE_ANISO_SPECULAR

#if USE_OBJECT_SPACE_TANGENT
	float3 world_binormal = cross(In.world_normal.xyz, normalize(In.world_tangent.xyz)) * In.world_tangent.w;
	float3x3 TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
#else
	float3x3 TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord.xy);
#endif
	float3 world_fur_direction = TBN[1];
#else
	float3 world_fur_direction = float3(0, 0, 0);
#endif
	
#if USE_ANISO_SPECULAR && 0 //TODO Intended
	float env_map_factor = 1.0;
	float3 anisotropicTangent = normalize(cross(-pp_static.view_vector.xyz, normalize(world_fur_direction.xyz)));
	float3 anisotropicNormal = normalize(cross(anisotropicTangent.xyz, normalize(world_fur_direction.xyz)));
	anisotropicNormal  = normalize(lerp(pp_modifiable.world_space_normal, anisotropicNormal, 1.0));
	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	get_ambient_terms(pp_static.world_space_position, anisotropicNormal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy, 
		pp_static.view_vector, _specularity_info, _final_albedo_color, sun_amount, specular_ambient_term, diffuse_ambient_term);
	float3 ambient_light = (1.0 - _specularity_info.x) * _final_albedo_color * diffuse_ambient_term * pp_modifiable.ambient_ao_factor;
		ambient_light +=  specular_ambient_term * pp_modifiable.ambient_ao_factor;
#else
	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	float sky_visibility;

	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy, 
		pp_static.view_vector, pp_modifiable.specularity.xy, pp_modifiable.albedo_color, sun_amount,
		specular_ambient_term, diffuse_ambient_term, sky_visibility);

	float3 ambient_light = pp_modifiable.albedo_color.rgb * diffuse_ambient_term;
	ambient_light *= pp_modifiable.ambient_ao_factor;

#endif

	float3 lightDir = g_sun_direction_inv;
	
	// diffuse term
	float ndotl = saturate(dot(pp_modifiable.world_space_normal, lightDir));

	float diffuse_ndotl = wrapped_ndotl(pp_modifiable.world_space_normal, lightDir, 0.2);
	float3 scatter_color = lerp(float3(0.992, 0.808, 0.518), normalize(_final_albedo_color), 0.5);
	float3 scatter_light = saturate(scatter_color + ndotl) * diffuse_ndotl;

	float3 diffuse = 0;
	diffuse = pp_modifiable.diffuse_ao_factor * g_sun_color.rgb * sun_amount * _final_albedo_color * scatter_light / RGL_PI;

	// specular term
	float3 specular = float3(0,0,0);
	float vertex_aniso_factor = 0;
	float3 specular_color = float3(0,0,0);

	float tangent_shift = 0;
	float second_spec_mask = 0;

#if USE_ANISO_SPECULAR	
	// shift tangents
	tangent_shift = sample_texture(HairShiftandNoiseMap, linear_sampler, In.tex_coord.xy * 0.2).r * 2.0 - 1.0;
	second_spec_mask = sample_texture(HairShiftandNoiseMap, linear_sampler, In.tex_coord.xy * 7).g;

	float oldness = (1.0f - g_mesh_factor2_color.a);
	vertex_aniso_factor  = In.vertex_color.g * saturate(0.5 + oldness * 0.5);
	specular_color = 4 * lerp(3 * _final_albedo_color * lerp(1, 0.25, saturate(oldness * 2.0 - 1.0)), _final_albedo_color * lerp(1, 0.25, saturate(oldness * 2.0 - 1.0)), base_color_intensity);
	specular = calculate_anisotropic_specular(specular_color, pow(2, 10 * g_gloss_coef), pp_modifiable.world_space_normal, world_fur_direction.xyz, lightDir, 
		pp_static.view_vector, tangent_shift, second_spec_mask) * vertex_aniso_factor * 0.05 * g_specular_coef;	//use specularity_info texture?
#endif
	float3 specular_light = ndotl * specular * sun_amount * g_sun_color.rgb / RGL_PI;
	
	float3 final_color = 0;
	final_color = ambient_light;
	final_color += diffuse * (1.0 - 0.1);
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
		uint probe_index = visible_lights[start_index];

		float total_weight = 0;

		float4 occ_vec = sample_ssao_texture(pp_static.screen_space_position);

		while(probe_index != 0xFFFF)
		{
			total_color += compute_point_light_contribution_hair_aniso(probe_index, pp_modifiable.specularity, _final_albedo_color, pp_modifiable.world_space_normal,
				pp_static.view_vector.xyz, pp_static.world_space_position.xyz, pp_static.screen_space_position, occ_vec, In.vertex_color.rgb, specular_color, vertex_aniso_factor, world_fur_direction, In.tex_coord.xy, tangent_shift, second_spec_mask, pp_modifiable).rgb;

			start_index++;
			probe_index = visible_lights[start_index];
		}

		final_color.rgb += total_color;
	}
#endif

	float border = g_mesh_factor2_color.r;//0.76;//195.0 / 255.0;
	if (border > 0)
	{
		uint id = get_material_id(pp_static.screen_space_position, true);
		if (MATERIAL_ID_FACE == id || MATERIAL_ID_TRANSLUCENT_FACE == id)
		{
			//do not apply fog it will applied in sssss specular pass
		}
		else
		{
			apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);
		}
	}
	else
	{
		apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);
	}

	Output.RGBColor.rgb = output_color(final_color);
	
	float new_alpha = saturate(1.0 - ((border - pp_modifiable.early_alpha_value) / border));
	Output.RGBColor.a = new_alpha;
}
#endif

#endif

#endif

#endif
