#ifndef EYE_RSH
#define EYE_RSH

#include "definitions.rsh"
#include "shared_functions.rsh"

#if PIXEL_SHADER
//eye pixel shader functions
void calculate_alpha_eye(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{	
	In.tex_coord.xy = ((In.tex_coord.xy * 2.0 - 1.0) * 1.20) * 0.5 - 0.5;
	pp_modifiable.early_alpha_value = 1;	

#if USE_SMOOTH_FADE_OUT
	dithered_fade_out(pp_static.screen_space_position, g_mesh_factor_color.a);
#endif

}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS)
void calculate_normal_eye(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float3 _world_space_normal = normalize(In.world_normal.xyz);

	pp_aux.wetness_value = 0.0;
#if SYSTEM_RAIN_LAYER
	pp_aux.wetness_value = saturate(g_rain_density);
#endif

#if VDECL_HAS_TANGENT_DATA
	{
		#if USE_OBJECT_SPACE_TANGENT
		float3 world_binormal = cross(In.world_normal.xyz, normalize(In.world_tangent.xyz)) * In.world_tangent.w;
		float3x3 _TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
		#else
		float3x3 _TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord.xy);
		#endif
		float h = texture1.Sample(linear_sampler, In.tex_coord.xy).r;
		float3 eye_space_tangent = normalize(mul(_TBN, g_camera_position.xyz-In.world_position.xyz));
		pp_aux.parallax_texcoord = In.tex_coord - (eye_space_tangent.xy * h * 0.125);

		float3 normalTS = compute_tangent_space_normal(In, pp_modifiable, pp_aux.parallax_texcoord.xy, In.world_normal.xyz);
		_world_space_normal = normalize(mul(normalTS, _TBN));

		float3 nrml = 0;
		nrml = (2.0f * texture3.Sample(linear_sampler, pp_aux.parallax_texcoord.xy).rgb - 1.0f);
		nrml.xy *= g_normalmap_power;
		nrml.z = sqrt(1.0f - saturate(dot(nrml.xy, nrml.xy)));
		nrml = normalize(mul(nrml, _TBN));
		pp_modifiable.secondary_normal = nrml;
	}
#endif

	pp_modifiable.world_space_normal = _world_space_normal;
}

void calculate_albedo_eye(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 texcoord = pp_aux.parallax_texcoord;
	float4 diffuse_texture_color = sample_diffuse_texture(anisotropic_sampler, texcoord.xy).rgba;	
	INPUT_TEX_GAMMA(diffuse_texture_color.rgb);
	float3 _albedo_color = compute_albedo_color(In, pp_modifiable, diffuse_texture_color, texcoord, pp_static.world_space_position.xyz, In.vertex_color, false, pp_aux, pp_modifiable.world_space_normal);
	pp_modifiable.albedo_color = _albedo_color;
	pp_aux.albedo_color_without_effects = _albedo_color;
}

void calculate_specular_eye(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.specularity = compute_specularity(In, pp_modifiable, In.tex_coord, pp_static.world_space_position, pp_modifiable.world_space_normal.xyz, In.vertex_color, pp_aux, pp_modifiable.albedo_color, pp_aux.albedo_color_without_effects);
	pp_modifiable.ambient_ao_factor = 1;
	bool eye_scar = false;

	if(In.vertex_color.a > 0)
	{
		if(g_mesh_vector_argument.x > 0)
		{
			eye_scar = true;
		}
	}
	else if(g_mesh_vector_argument.y > 0)
	{
		eye_scar = true;
	}

	if(eye_scar)
	{
		pp_modifiable.specularity.x *= 0.3f;
	}
}

void calculate_eye_ao_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;
	pp_modifiable.diffuse_ao_factor = 1.0f;
}

void calculate_eye_ao_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;
	pp_modifiable.diffuse_ao_factor = 1.0f;
}

float3 calculate_direct_light_eye(float2 _specularity_info, float3 albedo_color, float3 light_direction, float3 view_direction, 
								  float3 world_space_normal, float3 inverted_world_space_normal, float3 light_color, float3 light_amount, bool eye_scar)
{

	float NdotL = saturate( dot(light_direction, world_space_normal) );
	float NdotLinverted = 0;
	if(eye_scar)
		NdotLinverted = saturate(dot(light_direction, world_space_normal));
	else
		NdotLinverted = saturate(dot(light_direction, inverted_world_space_normal));

	float3 diffuse_light = albedo_color.rgb / RGL_PI;
	float3 specular_light = float3(0.0, 0.0, 0.0);
	float3 result_color = float3(0.0, 0.0, 0.0);
	float3 reconstructed_pixel_specular_color = lerp(float3(0.04, 0.04, 0.04), float3(1.0, 1.0, 1.0), _specularity_info.x);
	float roughness = 1.0f - _specularity_info.y;

	float3 half_vector = normalize(view_direction.xyz + light_direction);
	float NdotH = saturate(dot(world_space_normal, half_vector));
	float VdotH = saturate(dot(view_direction, half_vector));
	float NdotV = saturate(dot(world_space_normal, view_direction));

	float3 specular_fresnel;
	{
		float fresnelVH = (1.0 - VdotH);
		specular_fresnel = reconstructed_pixel_specular_color + (1.0f - reconstructed_pixel_specular_color) * pow(fresnelVH, 5);
	}

	{
		//NDF
		roughness = max(1e-6, roughness);
		float alpha = roughness * roughness;
		float alpha_sqr = alpha * alpha;
		float ndoth_sqr = NdotH * NdotH;
		float D = alpha_sqr;
		float denominator = (ndoth_sqr * (alpha_sqr - 1) + 1);
		denominator *= denominator;
		denominator = max(denominator, 1e-6);
		D = D / denominator;

		//Geometric shadowing
		float k = alpha * 0.5;
		float G_L = 1.0f / (NdotL * (1.0 - k) + k);
		float G_V = 1.0f / (NdotV * (1.0 - k) + k);
		float G = G_L * G_V;

		specular_light = D * G * specular_fresnel;
		specular_light = specular_light / (4.0 * RGL_PI);
	}

	result_color = (diffuse_light * NdotLinverted + specular_light * NdotL) * light_color.rgb * light_amount;

	return result_color;
}

float3 compute_point_light_contribution_eye(int light_id, float2 _specularity_info, float3 albedo_color,
							float3 world_space_normal, float3 inverted_world_space_normal,  float3 view_direction, 
							float3 world_space_position, bool eye_scar, float2 screen_space_position, float4 occ_vec)
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

	//add specular terms 
	float3 result_color = 0;
	float3 specular_light = 0;
	float3 sun_lighting = 0;


	float ambient_occlusion_factor = 1.0f;
	float diffuse_occlusion_factor = 1.0f;


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

	float3 resulting_color = calculate_direct_light_eye(_specularity_info, albedo_color, light_direction, view_direction, world_space_normal, inverted_world_space_normal,
										light_color, light_amount, eye_scar);


	return resulting_color * _light_attenuation * diffuse_occlusion_factor;
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_eye(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	float _sun_amount = compute_sun_amount_from_cascades(pp_static.world_space_position, pp_static.screen_space_position);

	float3 wsn = pp_modifiable.world_space_normal;
	float3 inverted_wsn = pp_modifiable.world_space_normal;
	float3 wsp = pp_static.world_space_position;

	bool eye_scar = false;

	if(In.vertex_color.a > 0)
	{
		if(g_mesh_vector_argument.x > 0)
		{
			eye_scar = true;
		}
	}
	else if(g_mesh_vector_argument.y > 0)
	{
		eye_scar = true;
	}

	float alpha_value = sample_diffuse_texture(anisotropic_sampler, In.tex_coord.xy).a;


	float2 _specularity_info = pp_modifiable.specularity;
	float3 final_color = 0;//ambient_light * pp_modifiable.ambient_ao_factor *  max(_sun_amount, 0.65); 
	float3 iris_color = 0;


	{
		iris_color += calculate_direct_light_eye(_specularity_info, pp_modifiable.albedo_color.rgb, g_sun_direction_inv, pp_static.view_vector,
			pp_modifiable.world_space_normal, pp_modifiable.secondary_normal, g_sun_color.rgb, _sun_amount, eye_scar);
	}
	
#ifdef USE_POINT_LIGHTS
	//compute point lights
	[branch]
	if(g_use_tiled_rendering > 0.0)
	{
		float3 total_color = 0;
		float2 ss_pos = saturate(pp_static.screen_space_position);
		uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		uint2 tile_index = (ss_pos * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE;
		uint start_index = MAX_LIGHT_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint probe_index = visible_lights_wDepth[start_index];

		float total_weight = 0;

		float4 occ_vec = sample_ssao_texture(pp_static.screen_space_position);

		while(probe_index != 0xFFFF)
		{
			total_color += compute_point_light_contribution_eye(probe_index, _specularity_info, pp_modifiable.albedo_color.rgb,
				pp_modifiable.world_space_normal, pp_modifiable.secondary_normal, pp_static.view_vector, pp_static.world_space_position, eye_scar, pp_static.screen_space_position, occ_vec);

			start_index++;
			probe_index = visible_lights_wDepth[start_index];
		}

		iris_color += total_color;
	}
#endif
	 
	float env_map_factor = 1.0;

	float3 specular_ambient_term;
	float3 diffuse_ambient_term;
	float sky_visibility;
	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy, 
		pp_static.view_vector, _specularity_info, float3(pp_modifiable.albedo_color.rgb), _sun_amount, specular_ambient_term, diffuse_ambient_term, sky_visibility);

	float strength = length(specular_ambient_term.xyz);
	strength = step(0.8, strength) * strength * 0.8;
	strength = saturate(pow(strength, 5));
	specular_ambient_term = (specular_ambient_term * strength);
	float3 diffuse_ambient_light = pp_modifiable.albedo_color.rgb * diffuse_ambient_term;
	
	final_color = diffuse_ambient_light + specular_ambient_term;
	final_color += iris_color * pp_modifiable.diffuse_ao_factor;

	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);	

	//set color
	Output.RGBColor.rgb = final_color;

	Output.RGBColor.a = 1;
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
}

#endif

#endif
#endif

#endif
