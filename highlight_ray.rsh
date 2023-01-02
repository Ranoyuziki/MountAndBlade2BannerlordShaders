#ifndef HIGHLIGHT_RAY_RSH
#define HIGHLIGHT_RAY_RSH

#if VERTEX_SHADER
void calculate_object_space_values_highlight(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float3 prev_object_position, object_color;
	rgl_vertex_transform(In, pv_modifiable.object_position, pv_modifiable.object_normal, pv_modifiable.object_tangent, prev_object_position, object_color);
	output.vertex_color = get_vertex_color(In.color);
}

void calculate_world_space_values_highlight(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
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
void calculate_render_related_values_highlight(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float4 screenspace_position = mul(g_view_proj, float4(output.world_position.xyz, 1));
	output.position = mul(g_view_proj, mul(g_world, float4(In.position.xyz, 1)));

	output.ClipSpacePos = screenspace_position;

	output.projCoord = 1;

#if ENABLE_DYNAMIC_INSTANCING
	output.instanceID = In.instanceID;
	output.world_position.w = In.instanceID;
#endif
}
#endif

#if PIXEL_SHADER
#include "gbuffer_functions.rsh"

float3 compute_highlight_normal(inout VS_OUTPUT_GLASS In)
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

void calculate_alpha_highlight(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	In.ClipSpacePos.xy /= In.ClipSpacePos.w;

	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f;
	tc.y = tc.y * -0.5f + 0.5f;

	float hw_depth = sample_depth_texture(tc * g_rc_scale).r;
	pp_modifiable.refraction_world_position = get_ws_position_at_gbuffer(hw_depth, tc);

	pp_modifiable.early_alpha_value = 1;
}

void calculate_normal_highlight(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 specularity_info;
	float3 normalTS = float3(0.5, 0.5, 1.0);

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

void calculate_albedo_highlight(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.gbuffer_depth = max(length(pp_modifiable.refraction_world_position.xyz - In.world_position.xyz), 0);
}

void calculate_specularity_highlight(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.specularity.xy = float2(0.0f, 1.0f);
}

void calculate_diffuse_ao_factor_highlight_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;

#ifdef SYSTEM_USE_SSDO
	float4 occ_vec = sample_ssao_texture(pp_static.screen_space_position);
	pp_modifiable.ambient_ao_factor *= (1.0 - saturate(occ_vec.w));
#elif defined(SYSTEM_USE_TSAO)
	float tsao_factor = sample_ssao_texture(pp_static.screen_space_position).r;
	pp_modifiable.ambient_ao_factor *= tsao_factor;
#endif

#if SYSTEM_USE_SKYACCESS_AO
	float3 world_pos = pp_static.world_space_position.xyz;
	float2 skyacc_coord = pp_static.world_space_position.xy * g_terrain_size_inv;
	float ao_lerp_factor = saturate(0.8f - (pp_modifiable.world_space_normal.z * 0.1f));
#endif

	pp_modifiable.ambient_ao_factor = max(pp_modifiable.ambient_ao_factor, 0.05);
}

void calculate_diffuse_ao_factor_highlight_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;
}

float3 calculate_highlight_refraction(inout Pixel_shader_input_type In, inout Per_pixel_modifiable_variables pp_modifiable)
{
	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f;
	tc.y = tc.y * -0.5f + 0.5f;

	float3 exposure_sample = g_use_pre_exposure ? exposure_texture.SampleLevel(point_clamp_sampler, float2(0.5, 0.5), 0).rrr : 1.0;
	return sample_texture(texture9, point_clamp_sampler, tc).rgb / exposure_sample;
}

void calculate_highlight_specular(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, float NdotL, float3 view_direction, float sun_amount, out float3 specular_ambient_term, out float3 diffuse_ambient_term)
{
	specular_ambient_term = 0;
	diffuse_ambient_term = 0;
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_highlight(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	const float depth = pp_modifiable.gbuffer_depth;
	const float NdotL = saturate(dot(pp_modifiable.world_space_normal.xyz, g_sun_direction_inv.xyz));
	float3 view_direction = normalize(pp_static.view_vector);

	float3 refraction = 1;
	float3 final_color = 0;
	float3 specular_ambient_term;
	float3 diffuse_ambient_term;

	float height_from_terrain = In.world_position.z - get_terrain_height_at(In.world_position.xy * g_terrain_size_inv);
	float world_height_mask = saturate(1 - (height_from_terrain *0.1) / g_mesh_vector_argument.z);

	float2 pos = In.tex_coord;
	float t = g_time_var / 1.0;
	float scale1 = 40.0;
	float scale2 = 20.0;
	float val = 0.0;

	float len = 1 - (depth * 0.05 * (g_mesh_vector_argument.w));

	float right_scale = length(get_column(g_world, 0));
	float up_scale = length(get_column(g_world, 2));

	float ratio_compensate = up_scale / right_scale;

	float glow_height_mask = saturate(1 - (height_from_terrain) * 0.793);
	float glow = 0.020 / (0.015 + distance(len, 1)) * g_mesh_vector_argument.x * glow_height_mask;
	glow *= (1.5 + sin(g_time_var * 2) * 0.75);
	val = (cos(RGL_PI*val) + 1.0) * g_mesh_vector_argument.y;

	float4 col1 = g_mesh_factor_color;
	float4 col2 = g_mesh_factor2_color;
	float3 zone_color = step(len, 1.0) * 0.5 * col1.xyz * val + glow * col2.xyz + 0.5 * final_color;

	final_color = lerp(final_color, zone_color, world_height_mask);

	Output.RGBColor.rgb = final_color.rgb;
	Output.RGBColor.a = 0.012438;
}
#endif
#endif

#endif
