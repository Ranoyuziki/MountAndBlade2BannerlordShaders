#ifndef FLORA_BILLBOARD_RSH
#define FLORA_BILLBOARD_RSH

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"

#if (VERTEX_DECLARATION != VDECL_POSTFX)	
#if VERTEX_SHADER
void calculate_flora_billboard(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
	float4 object_position;
	float3 object_normal;
	float4 world_position;
	float4 shadow_world_position;
	float3 world_normal;
	float3 prev_object_position;
	float4 temp_vert_color = get_vertex_color(In.color);	
	float4x4 world_frame;

	//////////////////////////////////////////////////////////////////////////
	object_position = float4(In.position,1);
#if VDECL_HAS_NORMAL_DATA
	float4 qtangent = normalize(In.qtangent);
	object_normal = quat_to_mat_zAxis(qtangent);
#endif

#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
	float4 pos_column = float4(g_instance_data[In.instanceID].position, 0);
	float4 scale_column = g_instance_data[In.instanceID].scale.xxxx;
	const float3 billboard_up_base = float3(0,0,1);
	float3 billboard_forward = normalize(float3(pos_column.xy - g_camera_position.xy, 0));
	float3 billboard_side = cross(billboard_forward, billboard_up_base);
	float3 billboard_up = billboard_up_base;
	
	billboard_side *= scale_column.x;
	billboard_forward *= scale_column.y;
	billboard_up *= scale_column.z;

	world_frame = float4x4
		(
		float4(billboard_side.x,	billboard_forward.x,	billboard_up.x,		pos_column.x),
		float4(billboard_side.y,	billboard_forward.y,	billboard_up.y,		pos_column.y),
		float4(billboard_side.z,	billboard_forward.z,	billboard_up.z,		pos_column.z),
		float4(0,0,0,1)
		);
	Out.fadeout_constant = pos_column.w;
#else
	world_frame = g_world;
	world_frame[3][3] = 1;
	
	float4 scale_column = get_column(world_frame, 0);
	
	Out.fadeout_constant = g_world[3][3];
#endif
	//////////////////////////////////////////////////////////////////////////

	shadow_world_position = world_position = mul(world_frame, object_position);
	world_normal = -normalize(mul(to_float3x3(world_frame),object_normal));

	float2 view_vec = g_camera_position.xy - world_position.xy;
#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
	float instance_angle = ((g_instance_data[In.instanceID].color >> 24) / 255.0f) * 2.0 - 1.0;
#else
	float instance_angle = 0.0f;
#endif
	Out.position = mul(g_view_proj, world_position);
	Out.world_position = world_position;
	Out.tex_coord.xy = In.tex_coord.xy;
	Out.world_normal = float4(world_normal, instance_angle);

	float view_angle = atan2(view_vec.y, view_vec.x) * (1.0 / RGL_PI);

	float view_index			= uint(floor(view_angle		* (FLORA_BILLBOARD_COUNT / 2)) + FLORA_BILLBOARD_COUNT) % FLORA_BILLBOARD_COUNT;
	uint view_index_int			= (uint(view_index) + FLORA_BILLBOARD_COUNT) % FLORA_BILLBOARD_COUNT;
	uint instance_view_offset	= uint(floor(instance_angle	* (FLORA_BILLBOARD_COUNT / 2)) + FLORA_BILLBOARD_COUNT) % FLORA_BILLBOARD_COUNT;

	uint main_billboard_index = (view_index_int - instance_view_offset + FLORA_BILLBOARD_COUNT + FLORA_BILLBOARD_COUNT) % FLORA_BILLBOARD_COUNT;
	uint secondary_billboard_index = (main_billboard_index + 1) % FLORA_BILLBOARD_COUNT;

	Out.sample_data = float3(main_billboard_index, secondary_billboard_index, 0);

	float4 shadow_screen_position = mul(g_view, shadow_world_position);

	Out.shadow_world_position = shadow_world_position;
#if ALBEDO_MULTIPLIER_PROJECTION 
	#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
		Out.albedo_multiplier_center_position = g_instance_data[In.instanceID].position;
	#else
		Out.albedo_multiplier_center_position = In.position;
	#endif
#endif
}
#endif

#if PIXEL_SHADER
void calculate_alpha_flora_billboard(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coords = In.tex_coord;
	tex_coords.x *= (1.0 / FLORA_BILLBOARD_COUNT);
	float4 tex_coord_1 = float4(tex_coords + float2(In.sample_data.x * (1.0 / FLORA_BILLBOARD_COUNT), 0), 0, 0);

	float4 albed_tex = sample_diffuse_texture(point_sampler, tex_coord_1.xy);
	//float4 albed_tex = sample_diffuse_texture_level(point_sampler, float4(tex_coord_1.xy, 0, g_debug_vector.z));
	pp_modifiable.early_alpha_value = albed_tex.a;


#ifdef USE_SMOOTH_FLORA_LOD_TRANSITION
	dithered_fade_out(pp_static.screen_space_position, In.fadeout_constant);
#endif
}
void calculate_normal_flora_billboard(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coords = In.tex_coord;
	tex_coords.x *= (1.0 / FLORA_BILLBOARD_COUNT);
	float4 tex_coord_1 = float4(tex_coords + float2(In.sample_data.x * (1.0 / FLORA_BILLBOARD_COUNT), 0), 0, 0);

	float instance_cos, instance_sin;
	sincos(In.world_normal.w * RGL_PI, instance_sin, instance_cos);

	float2x2 rotation_matrix;

	rotation_matrix[0][0] = instance_cos;	rotation_matrix[0][1] = -instance_sin;
	rotation_matrix[1][0] = instance_sin;	rotation_matrix[1][1] = instance_cos;

	float4 normal_tex = sample_normal_texture(tex_coord_1.xy);
	pp_modifiable.ambient_ao_factor = normal_tex.w;
	float3 standard_world_normal = normal_tex.xyz * 2.0 - 1.0;
	standard_world_normal.xy = mul(rotation_matrix, standard_world_normal.xy);

	pp_modifiable.world_space_normal.xyz = normalize(standard_world_normal);
}
void calculate_albedo_flora_billboard(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coords = In.tex_coord;
	tex_coords.x *= (1.0 / FLORA_BILLBOARD_COUNT);
	float4 tex_coord_1 = float4(tex_coords + float2(In.sample_data.x * (1.0 / FLORA_BILLBOARD_COUNT), 0), 0, 0);

	float4 albed_tex = sample_diffuse_texture(point_sampler, tex_coord_1.xy);
	//float4 albed_tex = sample_diffuse_texture_level(point_sampler, float4(tex_coord_1.xy, 0, g_debug_vector.z));
	

#if ALBEDO_MULTIPLIER_PROJECTION
#if SYSTEM_INSTANCING_ENABLED 
	float3 z_projection_coord = In.albedo_multiplier_center_position.xyz; 
#else
	float3 z_projection_coord = get_column(g_world, 3).xyz;
#endif
	float3 tex = sample_diffuse2_texture(z_projection_coord.xy * g_terrain_size_inv).rgb;
	pp_modifiable.albedo_color.rgb = albed_tex.rgb * tex.rgb;//lerp(pp_modifiable.albedo_color.rgb, tex, 0.25);
#else
	pp_modifiable.albedo_color.rgb = albed_tex.rgb;
#endif
	//pp_modifiable.albedo_color.rgb = float3(1,0,1);
}

void calculate_ao_flora_billboard_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , 
	inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coords = In.tex_coord;
	tex_coords.x *= (1.0 / FLORA_BILLBOARD_COUNT);
	float4 tex_coord_1 = float4(tex_coords + float2(In.sample_data.x * (1.0 / FLORA_BILLBOARD_COUNT), 0), 0, 0);

	float4 normal_tex = sample_normal_texture(tex_coord_1.xy);
	//float4 normal_tex = sample_normal_texture_level(float4(tex_coord_1.xy, 0, g_debug_vector.z));
	pp_modifiable.diffuse_ao_factor = normal_tex.w;
	pp_modifiable.ambient_ao_factor = normal_tex.w;
}

void calculate_ao_flora_billboard_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	calculate_ao_flora_billboard_deferred(In, pp_static, pp_modifiable, pp_aux);

	compute_occlusion_factors_forward_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, pp_static.world_space_position, pp_static.screen_space_position, In.tex_coord, float4(1, 1, 1, 1));
}

void calculate_specular_flora_billboard(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.specularity = 0;
}
#endif


#endif

#if PIXEL_SHADER
void flora_billboard_alpha_test_function(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	if (ALPHA_TEST)
	{
		clip(pp_modifiable.early_alpha_value - g_alpha_ref);
	}
}

#endif

#endif //_FLORA_RSH