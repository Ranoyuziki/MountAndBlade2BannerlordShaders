#ifndef PARTICLE_SHADING_RSH
#define PARTICLE_SHADING_RSH

//See Particle_manager::Gpu_misc_flags
#define gpumf_billboard_turn_to_velocity_side			0x00000001
#define gpumf_billboard_2d								0x00000002
#define gpumf_billboard_turn_to_velocity_forward		0x00000004
#define gpumf_billboard_none							0x00000008
#define gpumf_spherical_normals							0x00000010
#define gpumf_fixed_billboard_direction					0x00000020
#define gpumf_use_terrain_albedo						0x00000040
#define gpumf_skew_with_respect_to_particle_velocity	0x00000080
#define gpumf_soften_alpha_with_water_level				0x00000100
#define gpumf_camera_near_fading_out					0x00000200
#define gpumf_soften_alpha_with_depth					0x00000400
#define gpumf_use_sky_visibility						0x00000800
#define gpumf_use_exposure_compensation					0x00001000

#define BUFFERLESS_DRAW (VERTEX_DECLARATION == VDECL_EMPTY)
//#define PARTICLE_SHADING
//#define ATLAS_SHADING
#include "gbuffer_functions.rsh"
#include "shared_pixel_functions.rsh"

float4 extract_particle_color(uint color)
{
	float4 ret;
	ret.a = (color >> 24) / 255.0;
	ret.r = ((color & 0x00FF0000) >> 16) / 255.0;
	ret.g = ((color & 0x0000FF00) >> 8) / 255.0;
	ret.b = (color & 0x000000FF) / 255.0;
	return ret;
}

float4x4 get_particle_frame(uint emitter_misc_values, float3 particle_position, float3 particle_move_dir, float3 fixed_billboard_dir, float rotation, float skew_with_particle_vel, float skew_with_particle_limit)
{
	float4x4 particle_frame;
	float3 up, side, forward;
	if (emitter_misc_values & gpumf_billboard_turn_to_velocity_side)
	{
		if (emitter_misc_values & gpumf_fixed_billboard_direction)
		{
			side = normalize(particle_move_dir);
			up = normalize(fixed_billboard_dir);
			forward = normalize(cross(up, side));
			side = normalize(cross(forward, up));
		}
		else
		{
			side = normalize(particle_move_dir);
			up = normalize(g_camera_position.xyz - particle_position);
			forward = normalize(cross(up, side));
			up = normalize(cross(side, forward));
		}
	}
	else if (emitter_misc_values & gpumf_billboard_2d)
	{
		up = normalize(float3(g_camera_position.xy - particle_position.xy, 0));
		side = normalize(cross(float3(0.0, 0.0, 1.0), up));
		forward = cross(up, side);
	}
	else if (emitter_misc_values & gpumf_billboard_turn_to_velocity_forward)
	{
		up = normalize(particle_move_dir);
		side = normalize(cross(float3(0.0, 0.0, 1.0), up));
		forward = cross(up, side);
	}
	else if (emitter_misc_values & gpumf_billboard_none)
	{
		if (emitter_misc_values & gpumf_fixed_billboard_direction)
		{
			up = normalize(fixed_billboard_dir);
			side = normalize(cross(float3(0.10, 0.99, 0), up));
			forward = cross(up, side);
		}
		else
		{
			up = normalize(particle_move_dir);
			side = normalize(cross(float3(2.0, 2.0, 4.0), up));
			forward = cross(up, side);
		}
	}
	else
	{
		up = normalize(g_camera_position.xyz - particle_position);
		side = normalize(cross(float3(0.0, 0.0, 1.0), up));
		forward = cross(up, side);
	}

	float sina, cosa;
	sincos(rotation, sina, cosa);

	float3 new_s = side*cosa + forward*sina;
	float3 new_f = forward*cosa - side*sina;

	if (emitter_misc_values & gpumf_skew_with_respect_to_particle_velocity)
	{
		float f_proj = dot(particle_move_dir, new_f);
		float s_proj = dot(particle_move_dir, new_s);
		float3 move_direction_on_sf_plane = new_f * f_proj + new_s * s_proj;
		if (skew_with_particle_limit > 0)
		{
			skew_with_particle_vel = min(skew_with_particle_limit, skew_with_particle_vel);
		}
		float3 skewed_f = new_f + move_direction_on_sf_plane * f_proj * skew_with_particle_vel;
		float3 skewed_s = new_s + move_direction_on_sf_plane * s_proj * skew_with_particle_vel;
		new_f = skewed_f;
		new_s = skewed_s;
	}

	particle_frame._m00_m10_m20_m30 = float4(new_s, 0);
	particle_frame._m01_m11_m21_m31 = float4(new_f, 0);
	particle_frame._m02_m12_m22_m32 = float4(up, 0);
	particle_frame._m03_m13_m23_m33 = float4(particle_position.xyz, 1);

	return particle_frame;
}

#if PARTICLE_SHADING
static const float4 quad_positions[6] =
{
		float4(-1,1,0,1),
		float4(-1,-1,0,1),
		float4(1,-1,0,1),
		float4(1,1,0,1),
		float4(-1,1,0,1),
		float4(1,-1,0,1)
	};

static const float2 quad_uvs[6] =
	{
		float2(0,0),
		float2(0,1),
		float2(1,1),
		float2(1,0),
		float2(0,0),
		float2(1,1)
	};


static const float rcp_sqrt3 = 0.57735026f;
static const float3 spherical_quad_normals[6] =
	{
		float3(-rcp_sqrt3, rcp_sqrt3, rcp_sqrt3),
		float3(-rcp_sqrt3, -rcp_sqrt3, rcp_sqrt3),
		float3(rcp_sqrt3, -rcp_sqrt3, rcp_sqrt3),
		float3(rcp_sqrt3, rcp_sqrt3, rcp_sqrt3),
		float3(-rcp_sqrt3, rcp_sqrt3, rcp_sqrt3),
		float3(rcp_sqrt3, -rcp_sqrt3, rcp_sqrt3)
	};

static const float3 flat_quad_normals[6] =
	{
		float3(0, 0, 1.0),
		float3(0, 0, 1.0),
		float3(0, 0, 1.0),
		float3(0, 0, 1.0),
		float3(0, 0, 1.0),
		float3(0, 0, 1.0)
	};

void generate_quad_info(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{

	uint quad_vertex_id = In.vertex_id % 6;
	const Particle_record particle = particle_records[Out.particle_index];
	const Particle_emitter_record emitter = emitter_records[particle.emitter_index_];
	float4x4 particle_frame = get_particle_frame(emitter.misc_flags, particle.position, particle.displacement, particle.fixed_billboard_direction, particle.rotation, emitter.skew_with_particle_velocity_coef_, emitter.skew_with_particle_velocity_limit_);
	float4 pos = quad_positions[quad_vertex_id];
	pos.xy = pos.xy * emitter.quad_scale + emitter.quad_bias;
	pv_modifiable.object_position = mul(particle_frame, float4(pos.xyz * particle.size, 1));
#if ATLAS_SHADING
	pv_modifiable.tex_coord_1.zw = quad_uvs[quad_vertex_id];
	const uint atlas_data = particle.atlas_data;
	const float2 inv_atlas_uv_scale = (((atlas_data & 0xFF000000) >> 24) - 1).rr / float2(g_particle_atlas_width, g_particle_atlas_height);
 	pv_modifiable.tex_coord_1.zw *= inv_atlas_uv_scale;
	//pv_modifiable.tex_coord_1.zw += float2(0, 3072 / (4096.0 - 1.0));
	pv_modifiable.tex_coord_1.zw += float2(((atlas_data & 0x00FFF000) >> 12) / g_particle_atlas_width, ((atlas_data & 0x00000FFF) >> 0) / g_particle_atlas_height);
	pv_modifiable.tex_coord_1.zw += 0.5 / float2(g_particle_atlas_width, g_particle_atlas_height);
#endif
#if SPRITE_BLENDING
	float frame_time = particle.uv_bias.x;
	float blend = frac(frame_time);
	float f0 = frame_time - blend;
	float2 sprite_count = 1.0 / emitter.uv_scale;
	pv_modifiable.tex_coord_1.xy = quad_uvs[quad_vertex_id];
	pv_modifiable.tex_coord_1.xy *= emitter.uv_scale;
	pv_modifiable.tex_coord_2.xy = pv_modifiable.tex_coord_1.xy;
	float2 uv0_bias;
	uv0_bias.y = floor(f0 * emitter.uv_scale.x);
	uv0_bias.x = fmod(f0, 1 / emitter.uv_scale.x);
	pv_modifiable.tex_coord_1.xy += emitter.uv_scale * uv0_bias;

	float f1 = min(f0 + 1.0, sprite_count.x * sprite_count.y - 1);		
	float2 uv1_bias;
	uv1_bias.y = floor(f1 * emitter.uv_scale.x);
	uv1_bias.x = fmod(f1, 1 / emitter.uv_scale.x);
	pv_modifiable.tex_coord_2.xy += emitter.uv_scale * uv1_bias;
	pv_modifiable.tex_coord_2.z = blend;
#else
	pv_modifiable.tex_coord_1.xy = quad_uvs[quad_vertex_id];
	pv_modifiable.tex_coord_1.xy *= emitter.uv_scale;
	pv_modifiable.tex_coord_1.xy += particle.uv_bias;
#endif	
	pv_modifiable.vertex_color = extract_particle_color(particle.particle_color);
	if (emitter.misc_flags & gpumf_use_terrain_albedo)
	{
		float2 colormap_uv;
		colormap_uv.x = ((particle.colormap_uv_ & 0xFFFF0000) >> 16) / ((float)0xFFFF);
		colormap_uv.y = ((particle.colormap_uv_ & 0x0000FFFF) >> 0) / ((float)0xFFFF);
		float3 colormap = sample_texture_level(colormap_diffuse_texture, linear_sampler, colormap_uv, 0).rgb;
		pv_modifiable.vertex_color.rgb *= colormap * colormap;
	}

	if (emitter.misc_flags & gpumf_spherical_normals)
	{
		pv_modifiable.object_normal = mul(to_float3x3(particle_frame), spherical_quad_normals[quad_vertex_id]);
	}
	else
	{
		pv_modifiable.object_normal = mul(to_float3x3(particle_frame), flat_quad_normals[quad_vertex_id]);
	}

	pv_modifiable.object_tangent = float4(mul(to_float3x3(particle_frame), float3(1,0,0)), 1);
	Out.emitter_index = particle.emitter_index_;
}
#endif

#if VERTEX_SHADER
void calculate_object_space_values_particle(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
#if PARTICLE_SHADING
	#if BUFFERLESS_DRAW
		Out.particle_index = In.vertex_id / 6 + g_bone_buffer_offset;
	#else
		Out.particle_index = In.instanceID + g_bone_buffer_offset;
	#endif
#endif
	Out.instanceID = In.instanceID;
#if BUFFERLESS_DRAW
	#if PARTICLE_SHADING
		generate_quad_info(In, pv_modifiable, Out);
	#endif
#else
#if PARTICLE_SHADING
	Particle_record particle = particle_records[Out.particle_index];
	Out.emitter_index = particle.emitter_index_;
	pv_modifiable.vertex_color = extract_particle_color(particle.particle_color);
#if USE_TERRAIN_ALBEDO
	float2 colormap_uv;
	colormap_uv.x = ((particle.colormap_uv_ & 0xFFFF0000) >> 16) / ((float)0xFFFF);
	colormap_uv.y = ((particle.colormap_uv_ & 0x0000FFFF) >> 0) / ((float)0xFFFF);
	float3 colormap = sample_texture_level(colormap_diffuse_texture, linear_sampler, colormap_uv, 0).rgb;
	pv_modifiable.vertex_color.rgb *= colormap * colormap;
#endif
#else
#if VDECL_IS_DEPTH_ONLY
	pv_modifiable.vertex_color = 1;
#else
	pv_modifiable.vertex_color = get_vertex_color(In.color);
#endif
#endif
		
	float3 dummy;
		float3 prev_object_position;
	rgl_vertex_transform(In, pv_modifiable.object_position, pv_modifiable.object_normal, pv_modifiable.object_tangent, prev_object_position, dummy);
	
#if VDECL_IS_DEPTH_ONLY
	pv_modifiable.tex_coord_1 = 0;
#else
	pv_modifiable.tex_coord_1 = float4(In.tex_coord.xy, 0, 0);
#endif
#endif
}

void calculate_world_space_values_particle(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
#if BUFFERLESS_DRAW
	pv_modifiable.world_position = pv_modifiable.object_position;
	pv_modifiable.world_normal.xyz = pv_modifiable.object_normal;
#else
	pv_modifiable.world_position = mul(g_world, float4(pv_modifiable.object_position.xyz, 1));
	pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));
#endif
}

void calculate_render_related_values_particle(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
#if PARTICLE_SHADING
	output.world_tangent = float4(normalize(pv_modifiable.object_tangent.xyz), 1);
	if (emitter_records[output.emitter_index].misc_flags & gpumf_use_exposure_compensation)
	{
		output.world_normal.w = particle_records[output.particle_index].exposure_compensation;
	}
#else
	#if VDECL_HAS_TANGENT_DATA
	output.world_tangent.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_tangent.xyz));
	output.world_tangent.w = -sign(In.qtangent.w);
	#endif
#endif

	output.world_position = pv_modifiable.world_position;
	output.position = mul(g_view_proj, float4(output.world_position.xyz, 1));
	output.world_position.w = mul(g_view, float4(pv_modifiable.world_position.xyz, 1)).z;
	output.world_normal.xyz = pv_modifiable.world_normal.xyz;
#ifndef SHADOWMAP_PASS
	output.vertex_color = pv_modifiable.vertex_color;
	output.tex_coord = pv_modifiable.tex_coord_1;
#if SPRITE_BLENDING
	output.tex_coord_2 = pv_modifiable.tex_coord_2.xyz;
#endif
#endif
}
#endif



float3 compute_lighting_particle(float2 specularity_info, float3 albedo_color,
	float3 light_color, float light_amount, float3 world_space_normal, float3 view_direction, float3 light_direction,
	float diffuse_ao_factor, float backlight_factor)
{
	// 	float NdotL = max(dot(light_direction, world_space_normal.xyz), g_debug_vector.y);
	// 	float SdotV = saturate(-dot(light_direction, view_direction) * g_debug_vector.x * abs(dot(light_direction, world_space_normal.xyz)));

	float NdotL = max(dot(light_direction, world_space_normal.xyz), backlight_factor);
	float SdotV = saturate(-dot(light_direction, view_direction))  * backlight_factor;

	float3 diffuse_light = albedo_color.rgb;
	float3 specular_light = float3(0.0, 0.0, 0.0);
	float3 result_color = float3(0.0, 0.0, 0.0);
#if USE_MONOCHROME_SPECULAR
	float3 reconstructed_pixel_specular_color = lerp(float3(0.04, 0.04, 0.04), float3(1, 1, 1), specularity_info.x);
#else
	float3 reconstructed_pixel_specular_color = construct_specular_color(specularity_info, diffuse_light);
#endif
	float3 half_vector = normalize(view_direction.xyz + light_direction);
	float NdotH = saturate(dot(world_space_normal, half_vector));
	float VdotH = saturate(dot(view_direction, half_vector));
	float fresnelVH = (1.0 - VdotH);
	float3 specular_fresnel = reconstructed_pixel_specular_color + (max(specularity_info.yyy, reconstructed_pixel_specular_color) - reconstructed_pixel_specular_color) * pow(fresnelVH, 5);
	if (specularity_info.y > 0) //TODO_PERF_SHADERS: create material flag option?
	{
		specular_light = pow(NdotH, pow(2, specularity_info.y * 11)) * specular_fresnel * 5.6; //g_debug_vector was here
		specular_light *= saturate(specularity_info.y * 8);
	}

	diffuse_light = diffuse_light * saturate(1.0 - 1.5f * specularity_info.x);

	result_color = (diffuse_light + specular_light * diffuse_ao_factor) * (light_color.rgb / RGL_PI) * max(NdotL, SdotV) * light_amount;

	return result_color;
}

float3 compute_point_light_contribution_particle(int light_id, float2 specularity_info, float3 albedo_color,
	float3 world_space_normal, float3 view_direction,
	float3 world_space_position, float2 screen_space_position, float backlight)
{
	bool is_spotlight = visible_lights_params[light_id].spotlight_and_direction.x;

	float3 world_point_to_light = visible_lights_position_and_radius[light_id].xyz - world_space_position;
	float world_point_to_light_len = length(world_point_to_light);

	float radius = visible_lights_position_and_radius[light_id].w;
	float dist_to_light_n = world_point_to_light_len / radius;

	if (dist_to_light_n > 1.0f)
	{
		return float3(0, 0, 0);
	}

	float _light_attenuation = compute_light_attenuation_point(light_id, world_point_to_light, radius);

	float ambient_occlusion_factor = 1.0f;
	float diffuse_occlusion_factor = 1.0f;

	float3 light_color = visible_lights_params[light_id].color.rgb;
	float light_amount = 1;//calculate_point_light_shadow(-world_point_to_light, world_space_position, light_id);
	float3 light_direction = world_point_to_light / world_point_to_light_len;

	float3 resulting_color = compute_lighting_particle(specularity_info.xy, albedo_color.rgb,
		light_color, light_amount, world_space_normal, view_direction,
		light_direction, ambient_occlusion_factor, backlight) * _light_attenuation * diffuse_occlusion_factor;

	return resulting_color;
}

#if PIXEL_SHADER
void sample_textures_particle(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	//Albedo
	pp_modifiable.diffuse_sample = DiffuseMap.Sample(linear_sampler, In.tex_coord.xy);
#if SPRITE_BLENDING
	float4 diffuse_sample2 = DiffuseMap.Sample(linear_sampler, In.tex_coord_2.xy);
	pp_modifiable.diffuse_sample = lerp(pp_modifiable.diffuse_sample, diffuse_sample2, In.tex_coord_2.z);
#endif

	//Specular
	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
	#if !USE_SPECULAR_FROM_DIFFUSE
		pp_modifiable.specular_sample = float3(SpecularMap.Sample(linear_sampler, In.tex_coord.xy).xy, 0);
		#if SPRITE_BLENDING
			float3 specular_sample2 = float3(SpecularMap.Sample(linear_sampler, In.tex_coord_2.xy).xy, 0);
			pp_modifiable.specular_sample = lerp(pp_modifiable.specular_sample, specular_sample2, In.tex_coord_2.z);
		#endif
	#endif
	}

	//Emissive mask
	#if USE_EMISSIVE_MASK
		#if USE_SUNLIGHT
			#if PARTICLE_SHADING	
				float heatmap = pp_modifiable.diffuse_sample.b;
				heatmap *= emitter_records[In.emitter_index].heatmap_multiplier_;
				pp_modifiable.diffuse2_sample = EmissiveMask.Sample(linear_sampler, float2(saturate(1.0 - heatmap), 0.5));
			#endif
		#endif
		pp_modifiable.normal_sample = NormalMap.Sample(linear_sampler, In.tex_coord.xy);
		#if SPRITE_BLENDING
			float4 normal_sample2 = NormalMap.Sample(linear_sampler, In.tex_coord_2.xy);
			pp_modifiable.normal_sample = lerp(pp_modifiable.normal_sample, normal_sample2, In.tex_coord_2.z);
		#endif
	#else
		//Normalmap
		#if VDECL_HAS_TANGENT_DATA || PARTICLE_SHADING
			#if USE_NORMALMAP
				#if SYSTEM_DXT5_NORMALMAP
					pp_modifiable.normal_sample.xy = 2.0 * NormalMap.Sample(linear_sampler, In.tex_coord.xy).ag - 1.0;
					pp_modifiable.normal_sample.z = sqrt(1.0f - dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy));
					pp_modifiable.normal_sample.w = 0;
					#if SPRITE_BLENDING
						float3 normal_sample2;
						normal_sample2.xy = 2.0 * NormalMap.Sample(linear_sampler, In.tex_coord_2.xy).ag - 1.0;
						normal_sample2.z = sqrt(1.0f - dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy));
						pp_modifiable.normal_sample.xyz = lerp(pp_modifiable.normal_sample, normal_sample2, In.tex_coord_2.z);
					#endif					
				#elif SYSTEM_BC5_NORMALMAP
					pp_modifiable.normal_sample.xy = 2.0 * NormalMap.Sample(linear_sampler, In.tex_coord.xy).rg - 1.0;
					pp_modifiable.normal_sample.z = sqrt(1.0f - dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy));
					pp_modifiable.normal_sample.w = 0;
					#if SPRITE_BLENDING
						float3 normal_sample2;
						normal_sample2.xy = 2.0 * NormalMap.Sample(linear_sampler, In.tex_coord_2.xy).rg - 1.0;
						normal_sample2.z = sqrt(1.0f - dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy));
						pp_modifiable.normal_sample.xyz = lerp(pp_modifiable.normal_sample, normal_sample2, In.tex_coord_2.z);
					#endif					
				#else
					pp_modifiable.normal_sample = float4(2.0 * NormalMap.Sample(linear_sampler, In.tex_coord.xy).rgb - 1.0, 0);
					#if SPRITE_BLENDING
						float3 normal_sample2 = 2.0 * NormalMap.Sample(linear_sampler, In.tex_coord.xy).rgb - 1.0;						
						pp_modifiable.normal_sample.xyz = lerp(pp_modifiable.normal_sample.xyz, normal_sample2, In.tex_coord_2.z);
					#endif	
				#endif
			#endif
		#endif	
	#endif	
}

void calculate_alpha_particle(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float early_alpha_value = In.vertex_color.a;
	early_alpha_value *= pp_modifiable.diffuse_sample.a;
	float depth_val = sample_depth_texture(pp_static.screen_space_position).r;
	clip(In.position.z - depth_val);
#if PARTICLE_SHADING
	uint emitter_misc_flags = emitter_records[In.emitter_index].misc_flags;
	if (emitter_misc_flags & gpumf_camera_near_fading_out)
	{
		float distance_to_cam = length(g_camera_position.xyz - pp_static.world_space_position.xyz);
		const float camer_near_fadeout_coef = emitter_records[In.emitter_index].camera_fadeout_coef;
		const float camer_near_fadeout_effect = saturate((distance_to_cam - camer_near_fadeout_coef) / camer_near_fadeout_coef);
		early_alpha_value *= camer_near_fadeout_effect * camer_near_fadeout_effect;
	}

	if (emitter_misc_flags & gpumf_soften_alpha_with_depth)
	{
		if (g_use_depth_effects)
		{
			float3 prev_world_pos = get_ws_position_at_gbuffer(depth_val, pp_static.screen_space_position);
			float depth = length(g_camera_position.xyz - prev_world_pos);
			float mesh_depth = length(g_camera_position.xyz - pp_static.world_space_position);
			float depth_diff = max(0.0001, depth - mesh_depth);
			float soften_factor = pow(saturate(depth_diff / emitter_records[In.emitter_index].fadeout_distance), 1 + emitter_records[In.emitter_index].fadeout_coef);
			early_alpha_value *= soften_factor;
		}
	}
	
	if(emitter_misc_flags & gpumf_soften_alpha_with_water_level)
	{
		if (g_use_depth_effects)
		{
			float depth = saturate(pp_static.world_space_position.z - g_water_level);
			float soften_factor = saturate( depth / emitter_records[In.emitter_index].fadeout_distance);
			early_alpha_value *= soften_factor;
		}
	}

	if(emitter_misc_flags &  gpumf_use_sky_visibility)
	{
		float2 world_uv = pp_static.world_space_position.xy * g_terrain_size_inv;
		world_uv.y = 1 - world_uv.y;
		float topdown_depth_sample = (1 - topdown_depth_texture.SampleLevel(linear_sampler, world_uv, 0).r) * 800 - 400;
		early_alpha_value *= (step(topdown_depth_sample, pp_static.world_space_position.z));
	}
#endif

	pp_modifiable.early_alpha_value = early_alpha_value;
}


void calculate_normal_particle(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if ATLAS_SHADING == 0
	float3 world_space_normal_n = normalize(In.world_normal.xyz);
#if VDECL_HAS_TANGENT_DATA || PARTICLE_SHADING
#if USE_NORMALMAP
	float3 world_binormal = -normalize(cross(world_space_normal_n.xyz, In.world_tangent.xyz));
	float3x3 _TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, world_space_normal_n.xyz);
	float3 normalTS = pp_modifiable.normal_sample.xyz;		
	world_space_normal_n = normalize(mul(normalTS, _TBN));
#endif
#endif
	pp_modifiable.world_space_normal = world_space_normal_n;
#endif
}

void calculate_albedo_particle(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if ATLAS_SHADING == 0
	float4 diffuse_texture_color = 0;
	if (HAS_MATERIAL_FLAG(g_mf_dont_use_albedo_texture) || USE_EMISSIVE_MASK)
	{
		diffuse_texture_color = 1.0;
	}
	else
	{
		diffuse_texture_color = pp_modifiable.diffuse_sample;
		INPUT_TEX_GAMMA(diffuse_texture_color.rgb);
	}
	pp_modifiable.albedo_color = diffuse_texture_color.rgb;
	pp_modifiable.albedo_color *= In.vertex_color.rgb;
	
#ifdef SYSTEM_TEXTURE_DENSITY
	pp_modifiable.albedo_color = checkerboard(pp_modifiable.albedo_color, In.tex_coord.xy, diffuse_texture, false, In.world_position.xyz);
#endif
	pp_aux.albedo_color_without_effects = pp_modifiable.albedo_color.rgb;
#endif // ATLAS_SHADING
}

void calculate_specularity_particle(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 specularity_info = float2(0, 0);
	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
#if USE_SPECULAR_FROM_DIFFUSE
		specularity_info.x = max((pp_aux.albedo_color_without_effects.x + pp_aux.albedo_color_without_effects.y + pp_aux.albedo_color_without_effects.z) * 0.33, 0.01);
		specularity_info.y = max((pp_aux.albedo_color_without_effects.x + pp_aux.albedo_color_without_effects.y + pp_aux.albedo_color_without_effects.z) * 0.33, 0.01);
#else
		specularity_info = pp_modifiable.specular_sample.xy;
		specularity_info.x *= specularity_info.x;
#endif
		specularity_info.x = saturate(specularity_info.x * g_specular_coef);
		specularity_info.y = saturate(specularity_info.y * g_gloss_coef);
	}
	pp_modifiable.specularity = specularity_info;
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_particle(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	float sky_visibility = 0.0f;
	
#if ATLAS_SHADING
	float diffuse_multiplier = emitter_records[In.emitter_index].diffuse_multiplier;
	float4 diffuse_texture_color = pp_modifiable.diffuse_sample;
	INPUT_TEX_GAMMA(diffuse_texture_color.rgb);
	float3 atlas_shading = particle_shading_atlas_texture.SampleLevel(linear_sampler, In.tex_coord.zw, 0).xyz / get_pre_exposure();

#if SYSTEM_USE_PRT
	sky_visibility = particle_shading_atlas_sky_vis_texture.SampleLevel(linear_sampler, In.tex_coord.zw, 0).x;
#endif

	float3 final_color = atlas_shading.rgb * diffuse_texture_color.rgb;
	final_color = lerp(final_color, final_color * diffuse_multiplier, diffuse_texture_color.a);
#else
	pp_modifiable.diffuse_ao_factor = 1;
	pp_modifiable.ambient_ao_factor = 1;
#if EMISSIVE
	float3 final_color = pp_modifiable.albedo_color;
#if PARTICLE_SHADING
	final_color *= emitter_records[In.emitter_index].emissive_multiplier;
	final_color *= emitter_records[In.emitter_index].diffuse_multiplier;
#endif
#else
	direct_lighting_info l_info;// = get_lighting_info(pp_static.world_space_position, In.world_position.w, pp_static.screen_space_position);
	l_info.light_amount = compute_sun_amount_for_texture_no_blend(pp_static.world_space_position);
	l_info.light_color = g_sun_color;
	l_info.light_direction = g_sun_direction_inv;

	float3 specular_ambient_term = 0;
	float3 diffuse_ambient_term = 0;
	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy,
		pp_static.view_vector, pp_modifiable.specularity.xy, pp_modifiable.albedo_color, l_info.light_amount,
		specular_ambient_term, diffuse_ambient_term, sky_visibility);

	float3 ambient_light = pp_modifiable.albedo_color.rgb * diffuse_ambient_term;
	ambient_light *= 1.0 - pp_modifiable.specularity.x;
	ambient_light += specular_ambient_term;
	float3 final_color = 0 /** pp_modifiable.ambient_ao_factor*/;
#if PARTICLE_SHADING
	float backlight_factor = emitter_records[In.emitter_index].backlight_multiplier;
#else
	float backlight_factor = 0;
#endif

#if USE_SUNLIGHT || ENABLE_POINT_LIGHTS
	#if USE_EMISSIVE_MASK
		#if PARTICLE_SHADING			
		float3 world_binormal = normalize(cross(In.world_tangent.xyz, In.world_normal.xyz));
		float3x3 _TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
		float4 lightmap = pp_modifiable.normal_sample;
		float4 heatmap = pp_modifiable.diffuse_sample;
		heatmap.b *= emitter_records[In.emitter_index].heatmap_multiplier_;
		#endif
	#endif
#endif

	float3 total_shaded_light = 0;
	float3 total_emissive_light = 0;
	float albedo_multiplier = 1;
#if USE_SUNLIGHT
	#if USE_EMISSIVE_MASK
		#if PARTICLE_SHADING			
		float emissive_mask_emissive_value = saturate(heatmap.b);		
		albedo_multiplier = emitter_records[In.emitter_index].diffuse_multiplier;
		float4 emissive_mask = pp_modifiable.diffuse2_sample;
		INPUT_TEX_GAMMA(emissive_mask.rgb);
		{
			float3 light_dir_ts = normalize(mul(_TBN, g_sun_direction_inv));
			float h_map = (light_dir_ts.x > 0.0f) ? (lightmap.r) : (lightmap.b);   // Picks the correct horizontal side.
			float v_map = (light_dir_ts.y > 0.0f) ? (lightmap.a) : (lightmap.g);   // Picks the correct Vertical side.
			float d_map = (light_dir_ts.z > 0.0f) ? (heatmap.r) : (heatmap.g * 0.5);              // Picks the correct Front/back Pseudo Map
			float lightMap = h_map * light_dir_ts.x*light_dir_ts.x + v_map * light_dir_ts.y*light_dir_ts.y + d_map * light_dir_ts.z*light_dir_ts.z; // Pythagoras!
			total_shaded_light += (max(lightMap, backlight_factor) * l_info.light_amount * l_info.light_color * albedo_multiplier * pp_modifiable.albedo_color.rgb) + ambient_light;
			total_emissive_light += emissive_mask_emissive_value * emissive_mask.rgb * emitter_records[In.emitter_index].emissive_multiplier;
		}	
		#endif
	#else
	{
		#if PARTICLE_SHADING
			albedo_multiplier = emitter_records[In.emitter_index].diffuse_multiplier;
		#endif
		float3 sun_lighting = compute_lighting_particle(pp_modifiable.specularity, pp_modifiable.albedo_color.rgb * albedo_multiplier,
			l_info.light_color, l_info.light_amount, pp_modifiable.world_space_normal, pp_static.view_vector, l_info.light_direction,
			pp_modifiable.diffuse_ao_factor, backlight_factor);
		final_color += ambient_light;
		final_color += sun_lighting;
	}
	#endif
#endif
#endif

#if ENABLE_POINT_LIGHTS
	//compute point lights
#if !EMISSIVE
	[branch]
	if (g_use_tiled_rendering > 0.0)
	{
		float3 total_color = 0;
		float2 ss_pos = saturate(pp_static.screen_space_position);
		uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		uint2 tile_index = (ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE;
		uint start_index = MAX_LIGHT_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint probe_index = visible_lights[start_index];
		while (probe_index != 0xFFFF)
		{
			#if USE_EMISSIVE_MASK
				#if PARTICLE_SHADING
					float3 world_point_to_light = visible_lights_position_and_radius[probe_index].xyz - In.world_position.xyz;
					float world_point_to_light_len = length(world_point_to_light);
					float radius = visible_lights_position_and_radius[probe_index].w;
					float dist_to_light_n = world_point_to_light_len / radius;
					if (dist_to_light_n <= 1.0f)
					{
						float _light_attenuation = compute_light_attenuation_point(probe_index, world_point_to_light, radius);
						float3 light_dir_ts = normalize(mul(_TBN, world_point_to_light / world_point_to_light_len));
						float h_map = (light_dir_ts.x > 0.0f) ? (lightmap.r) : (lightmap.b);   // Picks the correct horizontal side.
						float v_map = (light_dir_ts.y > 0.0f) ? (lightmap.a) : (lightmap.g);   // Picks the correct Vertical side.
						float d_map = (light_dir_ts.z > 0.0f) ? (heatmap.r) : (heatmap.g * 0.5);
						float lightMap = h_map * light_dir_ts.x*light_dir_ts.x + v_map * light_dir_ts.y*light_dir_ts.y + d_map * light_dir_ts.z*light_dir_ts.z; // Pythagoras!
						
						total_shaded_light += (lightMap * _light_attenuation * visible_lights_params[probe_index].color.rgb * albedo_multiplier * pp_modifiable.albedo_color.rgb)* (1.0 - heatmap.b);
					}
				#endif
			#else
				final_color.rgb += compute_point_light_contribution_particle(probe_index, pp_modifiable.specularity,
						pp_modifiable.albedo_color, pp_modifiable.world_space_normal, pp_static.view_vector,
						pp_static.world_space_position, pp_static.screen_space_position, backlight_factor);
			#endif
			start_index++;
			probe_index = visible_lights[start_index];
		}
	}
#endif
#endif

#if PARTICLE_SHADING			
	if (emitter_records[In.emitter_index].misc_flags & gpumf_use_exposure_compensation)
	{
		float pre_exposure_value = get_pre_exposure();
#if USE_SUNLIGHT && USE_EMISSIVE_MASK && PARTICLE_SHADING && !EMISSIVE
		float3 compensated_value = (total_emissive_light * In.world_normal.w) / pre_exposure_value;
		final_color.rgb = lerp(total_shaded_light, compensated_value, emissive_mask_emissive_value);
#else
		final_color.rgb = final_color.rgb * In.world_normal.w;
		final_color.rgb /= pre_exposure_value;
#endif
	}
	else
	{
#if USE_SUNLIGHT && USE_EMISSIVE_MASK && PARTICLE_SHADING && !EMISSIVE
		final_color.rgb = total_emissive_light * emissive_mask_emissive_value + total_shaded_light * (1.0 - emissive_mask_emissive_value);
#endif
	}
#endif

#endif

#ifndef SYSTEM_NO_FOG
	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);
#endif
#if !PARTICLE_SHADING
	pp_modifiable.early_alpha_value = 1;
#endif
#if ADDITIVE
	float3 color_to_write = final_color.rgb * pp_modifiable.early_alpha_value;
	float alpha_to_write = 1;
#else
	float3 color_to_write = final_color.rgb * pp_modifiable.early_alpha_value;
	float alpha_to_write = 1.0 - pp_modifiable.early_alpha_value;
#endif
	//Output.RGBColor.rgb = output_color(pp_modifiable.world_space_normal.zzz*3);
	//Output.RGBColor.rgb = output_color(In.world_tangent.xyz * 0.5 + 0.5);
	Output.RGBColor.rgb = output_color(color_to_write);
	Output.RGBColor.a = alpha_to_write;
}

#endif

#endif

#endif
