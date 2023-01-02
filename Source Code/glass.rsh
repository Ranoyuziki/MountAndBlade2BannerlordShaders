#ifndef GLASS_RSH
#define GLASS_RSH

#include "shared_functions.rsh"
#include "standart.rsh"
#include "system_postfx.rsh"
#include "pbr_shading_functions.rsh"


#if PIXEL_SHADER
//Detail detail normalmap tile, detail normalmap power, detail normalmap speed, normalmap speed, material selection

float3 convert_dxt5_normal(float4 tex_value)
{
	float3 normal;
	normal.xy = (2.0f * tex_value.ag - 1.0f);
	normal.z = sqrt(1.0f - dot(normal.xy, normal.xy));
	return normal;
}

float3 compute_glass_normal(inout VS_OUTPUT_GLASS In)
{
	float3 normal_;
	float3 normalTS = normalize(2.0 * sample_normal_texture(In.tex_coord.xy).rgb - 1).rgb;

#if VDECL_HAS_TANGENT_DATA

	float3 world_binormal = normalize(cross(In.world_normal.xyz, In.world_tangent.xyz)) * In.world_tangent.w;
	float3x3 _TBN = create_float3x3(In.world_tangent.xyz, world_binormal.xyz, In.world_normal.xyz);

	normal_.rgb = normalize(mul(normalTS.rgb, _TBN));
	normalTS = normalize(normalTS);
#else
	normal_.rgb = normalize(normalTS);
#endif

	return normal_;
}

float3 compute_tangent_space_normal_glass(Pixel_shader_input_type In, float2 texcoord, float3 vertex_world_normal, float3 vertex_world_tangent, float wetness_amount)
{
	float3 normalTS;

	normalTS = (2.0f * sample_normal_texture(texcoord.xy).rgb - 1.0f);
	normalTS.xy *= g_normalmap_power;
	normalTS.z = sqrt(1.0f - saturate(dot(normalTS.xy, normalTS.xy)));

	if (bool(USE_DETAILNORMALMAP))
	{
		return float3(1, 1, 1);
		float3 detail_normal = sample_detail_normal_texture(texcoord.xy * g_detailmap_scale).rgb * 2.0f - 1.0f;
		{
			float3 n1 = normalTS;
			float3 n2 = detail_normal;

			//partial derivative
			if (false)
			{
				float2 pd = n1.xy / n1.z + n2.xy / n2.z;
				float3 r = normalize(float3(pd, 1));
				normalTS = r;
			}

			//whiteout blending
			if (false)
			{
				normalTS = normalize(float3(n1.xy + n2.xy, n1.z*n2.z));
			}

			//UDN
			if (true)
			{
				normalTS = normalize(float3(n1.xy + n2.xy, n1.z));
			}
		}
	}
	return normalTS;
}
#endif

#if VERTEX_SHADER
void calculate_object_space_values_glass(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float3 prev_object_position, object_color;
	rgl_vertex_transform(In, pv_modifiable.object_position, pv_modifiable.object_normal, pv_modifiable.object_tangent, prev_object_position, object_color);
	output.vertex_color = get_vertex_color(In.color);
}

void calculate_world_space_values_glass(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float4 world_position = mul(g_world, float4(In.position, 1.0f));
	float3 detailNormalTS;

#if VDECL_HAS_TANGENT_DATA  
	float4 qtangent = normalize(In.qtangent);
	float3 normal = quat_to_mat_zAxis(qtangent);
	float4 tangent = float4(quat_to_mat_yAxis(qtangent), -sign(In.qtangent.w));

	float3 world_normal = normalize(mul(to_float3x3(g_world), normal));
	float3 binormal = cross(normal.xyz, tangent.xyz) * tangent.w;
	float3 vWorld_binormal = normalize(mul(to_float3x3(g_world), binormal));

	output.world_binormal.xyz = vWorld_binormal;
	output.world_normal.xyz = world_normal;

	output.world_tangent.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_tangent.xyz));

	float mesh_frame_handedness;
	{
		float3 mesh_rot_s = get_column(g_world, 0).xyz;
		float3 mesh_rot_f = get_column(g_world, 1).xyz;
		float3 mesh_rot_u = get_column(g_world, 2).xyz;

		float handedness_dot = dot(cross(mesh_rot_u, mesh_rot_s), mesh_rot_f);
		mesh_frame_handedness = (handedness_dot < 0.0) ? -1.0 : 1.0;
	}
	output.world_tangent.w = -sign(In.qtangent.w) * mesh_frame_handedness;
#endif

	output.tex_coord = In.tex_coord;
	output.world_position = world_position;
}
void calculate_render_related_values_glass(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float4 screenspace_position = mul(g_view_proj, float4(output.world_position.xyz, 1));
	output.position = mul(g_view_proj, mul(g_world, float4(In.position.xyz, 1)));

	output.ClipSpacePos = screenspace_position;

	//output.position.z = min(output.position.z, output.position.w-0.001f);

	output.projCoord = 1;

#if ENABLE_DYNAMIC_INSTANCING
	output.instanceID = In.instanceID;
	output.world_position.w = In.instanceID;
#endif
}
#endif

#if PIXEL_SHADER

#include "gbuffer_functions.rsh"

void calculate_alpha_glass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	In.ClipSpacePos.xy /= In.ClipSpacePos.w;

	#if USE_DEPTH
		float2 tc = In.ClipSpacePos.xy;
		tc.x = tc.x * 0.5f + 0.5f;
		tc.y = tc.y * -0.5f + 0.5f;

		float hw_depth = sample_depth_texture(tc * g_rc_scale).r;
		pp_modifiable.refraction_world_position = get_ws_position_at_gbuffer(hw_depth, tc);
	#endif

	pp_modifiable.early_alpha_value = 1;
}

void calculate_normal_glass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 specularity_info;
	float3 normalTS = compute_tangent_space_normal_glass(In, In.tex_coord.xy * g_detailmap_scale, In.world_normal.xyz, In.world_tangent.xyz, 0);

	float3 _world_space_normal = normalTS;
	pp_modifiable.depth_distance = 1 - saturate(length(g_camera_position.xyz - In.world_position.xyz) / 64);

#if VDECL_HAS_TANGENT_DATA

	float3 world_binormal = normalize(cross(In.world_normal.xyz, In.world_tangent.xyz)) * In.world_tangent.w;
	float3x3 _TBN = create_float3x3(In.world_tangent.xyz, world_binormal.xyz, In.world_normal.xyz);

	_world_space_normal.rgb = normalize(mul(normalTS.rgb, _TBN));
#else
	_world_space_normal.rgb = normalize(normalTS);
#endif

	pp_modifiable.tangent_space_normal = normalize(normalTS);
	pp_modifiable.world_space_normal = normalize(_world_space_normal);
}

void calculate_albedo_glass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
#if USE_DEPTH
	//geometry buffer depth distance
	{
		pp_modifiable.gbuffer_depth = max(length(pp_modifiable.refraction_world_position.xyz - In.world_position.xyz), 0);
	}
#else
	pp_modifiable.gbuffer_depth = 1;
#endif
}

void calculate_specularity_glass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.specularity.xy = float2(0.0f, 1.0f);
}

void calculate_diffuse_ao_factor_glass_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;
	float tsao_factor = sample_ssao_texture(pp_static.screen_space_position).r;
	pp_modifiable.ambient_ao_factor *= tsao_factor;
	float3 world_pos = pp_static.world_space_position.xyz;
	float2 skyacc_coord = pp_static.world_space_position.xy * g_terrain_size_inv;
	float ao_lerp_factor = saturate(0.8f - (pp_modifiable.world_space_normal.z * 0.1f));
	pp_modifiable.ambient_ao_factor = max(pp_modifiable.ambient_ao_factor, 0.05);
}

void calculate_diffuse_ao_factor_glass_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;
}

float3 calculate_glass_refraction(inout Pixel_shader_input_type In, inout Per_pixel_modifiable_variables pp_modifiable)
{
	float3 refraction = 0;
	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f;
	tc.y = tc.y * -0.5f + 0.5f;
	tc *= g_rc_scale;
	float4 coord_start = float4(tc, 0, 0);
	float4 coord_disto = coord_start;
	float2 texture_distort = (pp_modifiable.tangent_space_normal.xy * 0.1) * g_normalmap_power;
	coord_disto.xy += texture_distort;

	float3 exposure_sample = get_pre_exposure();

	refraction = sample_texture(texture9, point_clamp_sampler, coord_disto.xy).rgb / exposure_sample;

	return refraction;
}

void calculate_glass_specular(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, float NdotL, float3 view_direction, float sun_amount, out float3 specular_ambient_term, out float3 diffuse_ambient_term)
{
	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
	const float3 half_vector = normalize(view_direction.xyz + g_sun_direction_inv);
	const float NdotH = saturate(dot(pp_modifiable.world_space_normal.xyz, half_vector));
	const float NdotV = saturate(dot(pp_modifiable.world_space_normal.xyz, view_direction));

	float3 reconstructed_pixel_specular_color = construct_specular_color(pp_modifiable.specularity, float3(1, 1, 1));

	float3 view_reflect = reflect(-view_direction, pp_modifiable.world_space_normal);
	view_reflect.z = abs(view_reflect.z) + 0.1;
	view_reflect = normalize(view_reflect);

	specular_ambient_term = sample_cubic_global_texture_level(view_reflect.xyz, 0).rgb;
	diffuse_ambient_term = sample_cubic_global_texture_level(view_reflect.xyz, 8).rgb;

	const float power = construct_specular_power(pp_modifiable.specularity);
	const float normalization_factor = (power + 2) / 8;
	const float blinn_phong = (pow(NdotH, power));
	const float3 specular_light = (blinn_phong * normalization_factor) * g_gloss_coef;

	const float NoV = saturate(dot(pp_static.view_vector.xyz, pp_modifiable.world_space_normal.xyz));
	const float2 env_brdf = sample_texture_level(brdf_texture, linear_clamp_sampler, float2(pp_modifiable.specularity.x, NoV), 0).xy * g_specular_coef;
	specular_ambient_term = specular_ambient_term.rgb * (reconstructed_pixel_specular_color * env_brdf.x + env_brdf.y) * saturate(sun_amount + 0.8);
	specular_ambient_term.rgb += (specular_light * NdotL * sun_amount * (g_sun_color.rgb));
	}
	else
	{
	specular_ambient_term = 0;
	diffuse_ambient_term = 0;
}
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_glass(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	const float depth = pp_modifiable.gbuffer_depth;
	const float NdotL = saturate(dot(pp_modifiable.world_space_normal.xyz, g_sun_direction_inv.xyz));
	float3 view_direction = normalize(pp_static.view_vector);
	float sun_amount = compute_sun_amount_from_cascades(In.world_position.xyz, pp_static.screen_space_position.xy);
	//float sun_amount = compute_sun_amount(In.world_position.xyz, pp_static.screen_space_position);
	float3 sun_color = sun_amount * g_sun_color.rgb;

	float3 refraction = 1;
	float3 final_color = 0;
	float3 specular_ambient_term;
	float3 diffuse_ambient_term ;
	//Specular
	{
		calculate_glass_specular(In, pp_static, pp_modifiable, NdotL, view_direction, sun_amount, specular_ambient_term, diffuse_ambient_term);
	}

#if USE_REFRACTION
	{
		refraction = calculate_glass_refraction(In, pp_modifiable);

		final_color = refraction * (sample_diffuse_texture(linear_sampler, In.tex_coord * g_areamap_scale).rgb * sun_amount);
		final_color += refraction;
	}
#else
	final_color = sample_diffuse_texture(linear_sampler, In.tex_coord * g_areamap_scale) * sun_amount;
#endif

	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
	final_color += specular_ambient_term;
	}

	direct_lighting_info l_info = get_lighting_info(pp_static.world_space_position, pp_static.screen_space_position);
	l_info.light_amount = sun_amount;
	float3 sun_lighting = compute_direct_lighting(l_info, pp_modifiable.specularity, pp_modifiable.albedo_color.rgb,
		pp_modifiable.world_space_normal, pp_static.view_vector, pp_static.world_space_position,
		pp_static.screen_space_position, pp_modifiable.ambient_ao_factor);

	final_color += sun_lighting;
	//apply_advanced_fog(final_color.rgb, view_direction, pp_static.view_vector_unorm.z, pp_static.view_length * fade_out_shallow);

	Output.RGBColor.rgb = final_color.rgb;
	Output.RGBColor.a = 1;
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
}
#endif

#endif

#endif
