#ifndef GRASS_RSH
#define GRASS_RSH

#include "../shader_configuration.h"

// #define VERTEX_DECLARATION VDECL_REGULAR

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"

#define FLORA_FADE_OUT_STARTER_COEFFICIENT 0.8


float grass_fade_out_coefficient_calculator(float view_distance, float factor, float randomizer, float distance)
{
#if !ENABLE_DYNAMIC_INSTANCING
	float fade_out_ending_distance = view_distance - factor;
	float fade_out_beginning_distance = fade_out_ending_distance * FLORA_FADE_OUT_STARTER_COEFFICIENT;
	float distance_ratio = saturate((distance - fade_out_beginning_distance) / (fade_out_ending_distance - fade_out_beginning_distance));

	if (distance_ratio >= randomizer)
	{
		return 0;
}
	else
	{
		return 1;
	}
#endif
	return 1;
}

#if PIXEL_SHADER

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)

float3 calculate_grass_specular(float sun_amount, float NdotL, float2 specularity_info, float3 view_direction, float3 world_normal, float3 albedo_color)
{
	float3 reconstructed_pixel_specular_color = construct_specular_color(specularity_info, albedo_color);
	float3 half_vector = normalize(view_direction.xyz + g_sun_direction_inv.xyz);
	float NdotH = saturate(dot(world_normal, half_vector));

	float3 specular_fresnel;
	{
		float fresnelNH = (1.0 - NdotH);
		specular_fresnel = reconstructed_pixel_specular_color + (float3(1.0f, 1.0f, 1.0f) - reconstructed_pixel_specular_color) * pow(fresnelNH, 5);
	}

	float power = construct_specular_power(specularity_info);
	float normalization_factor = (power + 2) / 8;
	float blinn_phong = (pow(NdotH, power));

	float3 specular_light = specular_fresnel * normalization_factor * blinn_phong;

	return specular_light * g_sun_color.rgb * NdotL * sun_amount;
}

float3 grass_lambert_rendering(float3 world_position, float2 screen_space_poition, float3 tex_col, float diffuse_ao_factor, float ambient_ao_factor, float3 world_normal, float sun_amount)
{
	//float NdotL = saturate(dot(g_sun_direction_inv.xyz, world_normal.xyz));

	const float wrap_ndotl = 0;
	float NdotL = abs((dot(g_sun_direction_inv, world_normal) + wrap_ndotl) / (1 + wrap_ndotl));

	float3 view_dir = normalize(world_position - g_camera_position.xyz);
	const float wrap_sdotv = -0.5;
	float SdotV = max(0, (dot(g_sun_direction_inv, view_dir) + wrap_sdotv) / (1 + wrap_sdotv));

	float3 env_color, ambient_color;
	float4 view_reflect;
	view_reflect.xyz = reflect(-view_dir, world_normal);
	view_reflect.w = ENVMAP_LEVEL - 2;

	float sky_visibility = 1.0f;
	get_blended_env_map_multiple_sample(view_reflect.xyz, view_reflect.w, world_normal, ENVMAP_LEVEL - 2, world_position, 
		screen_space_poition, env_color, ambient_color, world_normal, sky_visibility);

	//float3 ambient_color = get_ambient_term_with_skyaccess(world_position, world_normal, screen_space_poition).rgb;
	float3 diffuse_light = tex_col.rgb  * sun_amount * g_sun_color.rgb * diffuse_ao_factor * NdotL;//*  (1.0f - translucency_factor) ;
	float3 translucency_light = tex_col.rgb * SdotV * g_sun_color.rgb * sun_amount;

	float3 ambient_light = ambient_ao_factor * ambient_color * tex_col.rgb;
	//float3 translucency_light = tex_col.rgb * transluceny_term * g_sun_color.rgb * sun_amount;

	float3 final_color = translucency_light + ((diffuse_light + ambient_light) * (1 - SdotV));// +translucency_light + ambient_light;// ambient_light + diffuse_light + translucency_light;

	return final_color;
}

#endif 

#endif 

#if (VERTEX_DECLARATION != VDECL_POSTFX)
#if VERTEX_SHADER
void deform_grass(inout float3 pos_xyz, float2 tex_coord, float3 object_location, float factor, out float color_multiplier)
{
	float3 original_pos = pos_xyz;
	factor -= 0.1f; //its for removing sliding movement in bottom of the grass;
	float2 global_wind_dir = g_global_wind_direction.xy;
	const float wind_power = clamp(length(global_wind_dir), 0.0, 1);

	float2 wind_move = 0;
	float2 tex = float2(pos_xyz.x, pos_xyz.y) / 8;
	tex.xy -= global_wind_dir * g_time_var * 0.08;
	float3 wind_tex = sample_texture_level(grass_wind_texture, linear_sampler, tex, 0).rgb;
	wind_move += (wind_tex.r - 0.3) * 0.2;
	wind_move += (wind_tex.g * 0.05) - 0.025;
	wind_move = saturate(factor) * global_wind_dir * wind_move * wind_power;

	pos_xyz.xy += wind_move;
	if (wind_power > 0)
		color_multiplier = clamp(1 - (length(wind_move * 3)), 0.5, 1.0);
	else
		color_multiplier = 1;


	float3 snapped_camera = g_camera_position.xyz - fmod(g_camera_position.xyz, 2);
	float3 dirsamp = snow_diffuse_texture.SampleLevel(linear_clamp_sampler, (pos_xyz.xy - snapped_camera.xy + float2(16, 16)) / 32.0f, 0).rgb * 2.0f - 1.0f;
	float height_factor = 1 - smoothstep(1.9, 2.0, distance(dirsamp.z * 16 + snapped_camera.z, pos_xyz.z - 1));
	pos_xyz.xyz += float3(dirsamp.xy * 0.75 * factor, -length(dirsamp.xy) * factor * 0.3) * height_factor;
}

void calculate_world_space_values_grass(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
	float4 object_position, object_tangent;
	float3 object_normal, object_binormal;
	float3 object_location, object_color;
	float4 world_position;
	float3 world_normal;
	float4 vertex_color;
	float distance;
	float wind_bend_factor = 1;
	float grass_fade_coefficient = 1;
	//init from inputs
	{
		float3 prev_object_position;
		rgl_vertex_transform(In, object_position, object_normal, object_tangent, prev_object_position, object_color);
		vertex_color = get_vertex_color(In.color);

#ifdef SYSTEM_INSTANCING_ENABLED
		world_position = object_position;
#else
		world_position = mul(g_world, object_position);
#endif
		distance = length(g_camera_position.xyz - world_position.xyz);

		//calculate randomizer coord
			float2 randomizer_loc = world_position.xy;		
		float random_coef = (sin(randomizer_loc.x * 100 + randomizer_loc.y * 35) + 0.5f) * 0.5f;
		
		#if !ENABLE_DYNAMIC_INSTANCING
		grass_fade_coefficient = grass_fade_out_coefficient_calculator(g_mesh_vector_argument_2.z, g_mesh_vector_argument.w, random_coef, distance);
		#endif
		
		//do wind animation unless the grass started to fade out
		{
			bool do_wind_animation = grass_fade_coefficient > 0.5;
			if (do_wind_animation)
			{	
				#if USE_BIG_LEAF_WIND_DEFORMATION
				deform_palm_leaf(get_vertex_color(In.color), world_position.xyz, object_position.xyz);
				#else
				deform_grass(world_position.xyz, In.tex_coord.xy, world_position.xyz, 1 - vertex_color.b, wind_bend_factor);
				#endif
			}
		}
	}

	float fade_alpha = 1;

#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING) 
	Instance_data instance_data = g_instance_data[In.instanceID];
	fade_alpha = instance_data.alpha;
#endif

	//position and normals
#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING) && !(VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS))
	{
		float4 quat = float4(f16tof32(instance_data.tangent0), f16tof32(instance_data.tangent0 >> 16), f16tof32(instance_data.tangent1), f16tof32(instance_data.tangent1 >> 16));
		float4x4 frame = flora_transform_quat_position(quat, instance_data.scale, instance_data.position);
		object_normal.z = max(object_normal.z, (saturate(g_mesh_vector_argument_2.x) * 5));
		object_normal = normalize(object_normal);
		world_normal.xyz = normalize(mul(to_float3x3(frame), object_normal));
	}
#else
	object_normal.z = max(object_normal.z, (saturate(g_mesh_vector_argument_2.x) * 5));
	object_normal = normalize(object_normal);
	world_normal.xyz = normalize(mul(to_float3x3(g_world), object_normal));
#endif


	//world_normal = object_normal;
	//assign to output
	{
		Out.position = mul(g_view_proj, world_position);
		Out.tex_coord.xy = In.tex_coord.xy;
		Out.tex_coord.w = fade_alpha;
		Out.tex_coord.z = saturate((distance / 350));
#if !(VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS))
		Out.world_position.xyz = world_position.xyz;
		Out.world_normal.xyz = lerp(world_normal, object_normal, saturate((1 - Out.tex_coord.z) - 0.8));
		Out.world_normal.z *= wind_bend_factor;
		Out.world_normal = normalize(Out.world_normal);
		Out.world_normal.w = saturate(max(In.position.z + 0.7 + Out.tex_coord.z * 2, 0.0)); // ambient_ao_factor
#endif
	}
	
#if ENABLE_DYNAMIC_INSTANCING
	Out.world_position.w = In.instanceID + INDEX_EPSILON;
#endif


#ifdef POINTLIGHT_SHADOWMAP_PASS
	{
#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
		uint face_index = In.instanceID / g_zero_constant_output;
#else
		uint face_index = In.instanceID;
#endif
		uint light_face_id = light_faces[g_light_face_id + face_index];
		uint light_index = light_face_id / 6;
		uint face = light_face_id % 6;
		uint shadow_index = visible_lights_params[light_index].shadow_params_index;

		float4 shadow_tc = mul(visible_light_shadow_params[shadow_index].shadow_view_proj[face], float4(pv_modifiable.world_position.xyz, 1));

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
		for (uint i = 0; i < 4; i++)
		{
			Out.clip_distances[i] = GetClipDistance(pv_modifiable.world_position.xyz, visible_lights_position_and_radius[light_index].xyz, light_index, face, i);
		}
	}
#endif

	Out.instanceID = In.instanceID;
}
#endif

#if PIXEL_SHADER
void calculate_alpha_grass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{ 
    float fading_alpha = 1;
#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
	float3 instance_position = g_instance_data[In.instanceID].position;
	float world_space_distance = length(g_camera_position.xyz - instance_position.xyz);
	float per_instance_random_value = get_random_float(instance_position.xy);
	fading_alpha = grass_fade_out_coefficient_calculator(g_mesh_vector_argument_2.z, g_mesh_vector_argument.w, per_instance_random_value, world_space_distance);
#endif
	
	//TODO_GOKHAN_PERF do not calculate complex fade out on shadows
#if defined(SHADOWMAP_PASS) || defined(SYSTEM_DEPTH_PREPASS) 
	float tex_col_alpha = pp_modifiable.diffuse_sample.a;
	pp_modifiable.early_alpha_value = tex_col_alpha * fading_alpha;
#ifdef USE_SMOOTH_FLORA_LOD_TRANSITION
	dithered_fade_out(pp_static.screen_space_position, In.tex_coord.w);
#endif

#else
	float tex_col_alpha = pp_modifiable.diffuse_sample.a;
	pp_modifiable.early_alpha_value = tex_col_alpha * fading_alpha;
#endif
}

void calculate_normal_grass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if (VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS))
#else
	float3 _world_space_normal = normalize(In.world_normal.xyz);

	{
		_world_space_normal = normalize(In.world_normal.xyz);
	}

#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
	float fading_alpha = 1;

	float3 world_position = g_instance_data[In.instanceID].position;
	float world_space_distance = length(g_camera_position.xyz - world_position);
	float2 randomizer_loc = world_position.xy;
	float random_coef = (sin(randomizer_loc.x * 100 + randomizer_loc.y * 35) + 0.5f) * 0.5f;
	fading_alpha = grass_fade_out_coefficient_calculator(g_mesh_vector_argument_2.z, g_mesh_vector_argument.w, random_coef, world_space_distance);
#endif

	//float max_distance = 80;
	//float cur_distance = length(In.world_position.xyz - g_camera_position.xyz);
	//float lerp_factor = pow(cur_distance / max_distance , g_debug_vector.x);
	//float multiply_factor = lerp( 0.5f , 6.5f,   lerp_factor );
	//world_space_normal.xy *= multiply_factor;
	//world_space_normal = normalize(world_space_normal);

	//_world_space_normal = float3(0,0,1);


	pp_modifiable.world_space_normal = _world_space_normal;
	pp_modifiable.vertex_normal = _world_space_normal;
#endif
}

void calculate_albedo_grass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if (VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS))
#else
	float4 tex_col = pp_modifiable.diffuse_sample;
	
#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING) 
	Instance_data instance_data = g_instance_data[In.instanceID];
	pp_modifiable.albedo_color = tex_col.rgb * float3(((instance_data.color >> 16) & 0xFF) / 255.0, ((instance_data.color >> 8) & 0xFF) / 255.0, ((instance_data.color) & 0xFF) / 255.0);
#else
	pp_modifiable.albedo_color = tex_col.rgb;
#endif
#if SYSTEM_RAIN_LAYER
		float _wetness_amount = saturate(g_rain_density);
#endif
	
	#ifdef SYSTEM_TEXTURE_DENSITY
		pp_modifiable.albedo_color.rgb = checkerboard(tex_col, In.tex_coord, diffuse_texture, true, In.world_position.xyz);
	#endif
	
	#if BLEND_TERRAIN_COLOR
		float2 terrain_coord = pp_static.world_space_position.xy * g_terrain_size_inv_xy_colormap_size_inv_zw.xy;
		float3 colormap_albedo = sample_colormap_albedo(terrain_coord).rgb;
		INPUT_TEX_GAMMA(colormap_albedo.rgb);
		
		float lerp_factor = 0;// saturate(pow(1.0f - In.vertex_color.a, 3.61));
	pp_modifiable.albedo_color = lerp(pp_modifiable.albedo_color, colormap_albedo, lerp_factor);
	#endif
	
#if ALBEDO_MULTIPLIER_PROJECTION 
#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING) 
		float3 z_projection_coord = g_instance_data[In.instanceID].position;
#else
		float3 z_projection_coord = get_column(g_world, 3).xyz;
#endif		
		float3 tex = sample_diffuse2_texture(z_projection_coord.xy * g_terrain_size_inv * 15.4).rgb;
		INPUT_TEX_GAMMA(tex.rgb);
	pp_modifiable.albedo_color.rgb = pp_modifiable.albedo_color.rgb * (float3(0.5, 0.5, 0.5) + tex.rgb * 0.5f);
 	#endif
#endif
}

void calculate_ao_grass_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if (VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS))
#else
	pp_modifiable.ambient_ao_factor = In.world_normal.w;
#endif
}

void calculate_ao_grass_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	calculate_ao_grass_deferred(In, pp_static, pp_modifiable, pp_aux);

	compute_occlusion_factors_forward_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, pp_static.world_space_position, pp_static.screen_space_position, In.tex_coord.xy, float4(1, 1, 1, 1));
}

void calculate_specular_grass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if VDECL_IS_DEPTH_ONLY
#else
	float2 _specularity_info = 0;
	
	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
		#ifdef USE_SPECULAR_FROM_DIFFUSE
		_specularity_info.x = max((pp_modifiable.albedo_color.x + pp_modifiable.albedo_color.y + pp_modifiable.albedo_color.z) * 0.33, 0.01);
		_specularity_info.y = max((pp_modifiable.albedo_color.x + pp_modifiable.albedo_color.y + pp_modifiable.albedo_color.z) * 0.33, 0.01);
		#else
		float3 specular = sample_specular_texture(In.tex_coord.xy);
		_specularity_info = specular.rg;
		_specularity_info.r *= _specularity_info.r;
		#endif
		_specularity_info.x = saturate(_specularity_info.x * g_specular_coef);
		_specularity_info.y = saturate(_specularity_info.y * g_gloss_coef);
	}
	
		pp_modifiable.specularity = 0;
#endif
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_grass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
#if VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS)
#else
	float sun_amount = 1;
		
		direct_lighting_info l_info = get_lighting_info(pp_static.world_space_position, pp_static.screen_space_position);
		sun_amount = l_info.light_amount;
	

	Output.RGBColor.rgb = grass_lambert_rendering(pp_static.world_space_position, pp_static.screen_space_position, pp_modifiable.albedo_color.rgb,
		pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor, pp_modifiable.world_space_normal, sun_amount);

	float NdotL = saturate((dot(g_sun_direction_inv, pp_modifiable.world_space_normal.xyz) + 0.3) * (1.0f / 1.3f));
		
	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
		Output.RGBColor.rgb += calculate_grass_specular(sun_amount, NdotL, pp_modifiable.specularity, pp_static.view_vector, pp_modifiable.world_space_normal, pp_modifiable.albedo_color.rgb);
	}
	
	//fog and gamma correction
	{
		apply_advanced_fog(Output.RGBColor.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, 1.0f);
		Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	}
#endif
}
#endif

#endif

#endif

#endif
