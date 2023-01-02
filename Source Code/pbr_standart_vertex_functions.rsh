#ifndef PBR_STANDART_VERTEX_FUNCTIONS_RSH
#define PBR_STANDART_VERTEX_FUNCTIONS_RSH

#ifdef VERTEX_SHADER

#include "skyaccess_functions.rsh"
#include "math_conversions.rsh"

//main vertex shader functions
void calculate_render_related_values_standart(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
#if (VERTEX_DECLARATION != VDECL_DEPTH_ONLY)
	if(HAS_MATERIAL_FLAG(g_mf_use_atlas_shading))
	{
	In.tex_coord = In.tex_coord * g_mesh_vector_argument.xy + g_mesh_vector_argument.zw;
	}
#endif

#if defined(SHADOWMAP_PASS)
#if (my_material_id != MATERIAL_ID_TERRAIN) && (VERTEX_DECLARATION != VDECL_DEPTH_ONLY) && ALPHA_TEST
	output.tex_coord.xy = In.tex_coord.xy;
	output.vertex_color = pv_modifiable.vertex_color;
#endif
#else
	pv_modifiable.tex_coord_1 = float4(In.tex_coord.xy, 0, 0);

#if USE_TEXTURE_SCALERS
	pv_modifiable.tex_coord_1.xy = pv_modifiable.tex_coord_1.xy * g_mesh_vector_argument_2.xy + g_mesh_vector_argument_2.zw;
#endif

	if(bool(USE_ANIMATED_TEXTURE_COORDS))
	{
		uint num_frames_x = (uint)g_mesh_vector_argument.x;
		uint num_frames_y = (uint)g_mesh_vector_argument.y;
		float animation_speed = g_mesh_vector_argument.z;
		uint num_frames = (uint)g_mesh_vector_argument.w;

		int phase_difference = (int)((g_world._m03 + g_world._m13 + g_world._m23) * 2.4);

		uint cur_frame = (uint)(g_time_var * animation_speed + phase_difference) % num_frames;
		uint cur_frame_x = cur_frame % num_frames_x;
		uint cur_frame_y = cur_frame / num_frames_x;

		pv_modifiable.tex_coord_1.x *= 1.0f / (float)num_frames_x;
		pv_modifiable.tex_coord_1.y *= 1.0f / (float)num_frames_y;

		pv_modifiable.tex_coord_1.x += ((float)cur_frame_x / (float)num_frames_x);
		pv_modifiable.tex_coord_1.y += ((float)cur_frame_y / (float)num_frames_y);
	}

	#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS)
#ifdef STANDART_FOR_EYE
	pv_modifiable.vertex_color.a = (In.position.x > 0) ? 1.0 : -1.0;	//defines left&right eye
#endif
	#endif

#if (my_material_id != MATERIAL_ID_TERRAIN)
	output.vertex_color = pv_modifiable.vertex_color;
#ifndef SHADOWMAP_PASS
#if USE_TESSELATION
#ifndef PN_TRIANGLES
	output.world_normal.xyz = pv_modifiable.world_normal.xyz;
#endif
#else
	output.world_normal.xyz = pv_modifiable.world_normal.xyz;
#endif
#endif
#endif

#if (my_material_id != MATERIAL_ID_TERRAIN)
	output.tex_coord.xy = pv_modifiable.tex_coord_1.xy;
#endif

#ifdef STANDART_FOR_CRAFT_TRACK
	output.tex_coord.x += g_mesh_vector_argument.x;
	output.tex_coord.y += g_mesh_vector_argument.y * 0.25f;
#endif

#if VDECL_HAS_DOUBLEUV
	output.tex_coord.zw = In.tex_coord2.xy;
#endif
#endif

#if USE_TEXTURE_SWEEP && (!defined(SHADOWMAP_PASS) || ALPHA_TEST)
	output.tex_coord.xy -= g_mesh_vector_argument.xy * g_time_var * 1.64f;
#endif

#if SYSTEM_USE_CUSTOM_CLIPPING
	if (!g_zero_constant_output)
	{
		output.clip_distances[0] = GetCustomClipDistance(pv_modifiable.world_position.xyz, g_clipping_plane_position.xyz, g_clipping_plane_normal.xyz);
	}
#endif

#if defined(SYSTEM_CLOTH_SIMULATION_ENABLED) 
#if VDECL_HAS_SKIN_DATA && SYSTEM_WRITE_MOTION_VECTORS
	output.object_space_position.x = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
	output.object_space_position.y = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
	output.object_space_position.z = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];
	output.prev_object_space_position.x = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
	output.prev_object_space_position.y = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
	output.prev_object_space_position.z = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];
#endif
#endif
}

void calculate_object_space_values_standart(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
#if defined(SHADOWMAP_PASS)
	float4 object_color;	//only used for instanced floras
	rgl_vertex_transform_shadow(In, pv_modifiable.object_position, object_color);
#else

	float4 qtangent = float4(0, 0, 0, 1);
#if !VDECL_HAS_SKIN_DATA
	qtangent = In.qtangent;
#endif

#if SYSTEM_BLOOD_LAYER
	output.local_position = In.position.xyz;
	output.local_normal = get_in_normal(In, normalize(qtangent));
#elif TRIPLANAR_PROTOTYPE_MATERIAL
	float3 scale = float3(
		length(get_column(g_world, 0)),
		length(get_column(g_world, 1)),
		length(get_column(g_world, 2))
	);
	output.local_position = In.position.xyz * g_areamap_scale * scale;
	output.local_normal = get_in_normal(In, normalize(qtangent));
#endif

	float3 object_color;	//only used for instanced floras
	rgl_vertex_transform(In, pv_modifiable.object_position, pv_modifiable.object_normal, pv_modifiable.object_tangent, pv_modifiable.prev_object_position, object_color);

#if VDECL_HAS_SKIN_DATA && SYSTEM_WRITE_MOTION_VECTORS
	output.prev_object_space_position = pv_modifiable.prev_object_position;
	output.object_space_position = pv_modifiable.object_position.xyz;

#if defined(SYSTEM_CLOTH_SIMULATION_ENABLED) 
	output.object_space_position.x = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
	output.object_space_position.y = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
	output.object_space_position.z = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];

	output.prev_object_space_position.x = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
	output.prev_object_space_position.y = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
	output.prev_object_space_position.z = prev_global_skinned_vertex_buffer[(g_prev_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];
#endif

#endif

#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING) && (my_material_id == MATERIAL_ID_FLORA)
	output.albedo_multiplier_center_position = g_instance_data[In.instanceID].position;
#endif
#endif

#if (my_material_id != MATERIAL_ID_TERRAIN) && (VERTEX_DECLARATION != VDECL_DEPTH_ONLY) && (VERTEX_DECLARATION != VDECL_DEPTH_ONLY_WITH_ALPHA)
	pv_modifiable.vertex_color = get_vertex_color(In.color);
#else
	pv_modifiable.vertex_color = float4(1.0, 1.0, 1.0, 1.0); // TODO_OZGUR Might require rework
#endif
	
#if	!defined(SHADOWMAP_PASS) || ALPHA_TEST || defined(HAS_MODIFIER) || USE_TESSELATION
	output.vertex_color = pv_modifiable.vertex_color;
#endif
	
#if USE_PROCEDURAL_WIND_ANIMATION && (VERTEX_DECLARATION != VDECL_DEPTH_ONLY) && (VERTEX_DECLARATION != VDECL_DEPTH_ONLY_WITH_ALPHA)
	pv_modifiable.object_position.xyz = simple_wind_animation(pv_modifiable.object_position.xyz, pv_modifiable.vertex_color.a, pv_modifiable.object_normal);
#endif
}

void calculate_world_space_values_standart(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
#if SYSTEM_INSTANCING_ENABLED
	pv_modifiable.world_position = pv_modifiable.object_position;
#else
	pv_modifiable.world_position = mul(g_world, pv_modifiable.object_position);
#endif

#ifdef OUTER_MESH_RENDERING 
	if(pv_modifiable.vertex_color.a < 1.0f)
	{
		float2 sky_acces = saturate(pv_modifiable.world_position.xy * g_terrain_size_inv.xy);
#if USE_SNOW_FLOWMAP
		sky_acces.y = 1 - sky_acces.y;
#endif
		float height = get_terrain_height_at(sky_acces);
		float factor = pv_modifiable.vertex_color.a;
		pv_modifiable.world_position.z = lerp(height, pv_modifiable.world_position.z, factor);
	}
#endif

#if USE_GPU_BILLBOARDS
	enlarge_gpu_billboards_with_z(pv_modifiable.world_position, pv_modifiable.object_normal);	//TODO_BURAK: enlarge_gpu_billboards_with_z/enlarge_gpu_billboards difference
#endif

#if ALIGNMENT_DEFORMATION || ALIGNMENT_DEFORMATION_WITH_OFFSET
	{
		//better alignment of map icons to terrain
		float4x4 world_fixed_up = g_world;
		float3 side_vec = get_column(g_world, 0).xyz;
		float3 forward_vec = get_column(g_world, 1).xyz;
		float3 up_vec = get_column(g_world, 2).xyz;
		float side_size = length(side_vec.xyz);
		float forward_size = length(forward_vec);
		float up_size = length(up_vec);

		//side
		side_vec.z = 0;
		side_vec = normalize(side_vec) * side_size;
		world_fixed_up[0][0] = side_vec.x;
		world_fixed_up[1][0] = side_vec.y;
		world_fixed_up[2][0] = 0;

		//forward
		forward_vec.z = 0;
		forward_vec = normalize(forward_vec) * forward_size;
		world_fixed_up[0][1] = forward_vec.x;
		world_fixed_up[1][1] = forward_vec.y;
		world_fixed_up[2][1] = 0;

		//up:
		world_fixed_up[0][2] = 0;
		world_fixed_up[1][2] = 0;
		world_fixed_up[2][2] = up_size;

		float position_fix_effect = saturate(pv_modifiable.object_position.z * 2 - 0.15f);
		float4 fixed_world_position = mul(world_fixed_up, pv_modifiable.object_position);
		pv_modifiable.world_position = lerp(pv_modifiable.world_position, fixed_world_position, position_fix_effect);
		pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(world_fixed_up), pv_modifiable.object_normal));
	}
#endif

#if VDECL_IS_DEPTH_ONLY
#else

#ifndef SHADOWMAP_PASS
	pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));
	Out.world_normal.w = pv_modifiable.object_position.x; // mesh_frame_handedness

#if USE_OBJECT_SPACE_TANGENT
	Out.world_tangent.xyz = mul(to_float3x3(g_world), pv_modifiable.object_tangent.xyz);
	Out.world_tangent.w = pv_modifiable.object_tangent.w;
#endif // VDECL_HAS_TANGENT_DATA
#endif

#endif

#if USE_TESSELATION
	// Calculate distance between vertex and camera, and a vertex distance factor issued from it
#ifdef SHADOWMAP_PASS
	float3 view_dir = g_root_camera_position.xyz - pv_modifiable.world_position.xyz;
#else
	float3 view_dir = g_camera_position.xyz - pv_modifiable.world_position.xyz;

	float current_distance = length(view_dir);
	float normalized_d = 1.0f - saturate((current_distance - 40.0f) / 80.0f);
	Out.vertex_distance_factor = saturate(normalized_d);
#endif
#endif

#ifdef NO_VERTEX_PROJECTION
	Out.position = (In.position.xyz, 1);
#else
	Out.position = mul(g_view_proj, float4(pv_modifiable.world_position.xyz, 1));
#endif

#ifdef POINTLIGHT_SHADOWMAP_PASS
	{
		uint light_face_id = light_faces[g_light_face_id + In.instanceID];
		uint light_index = light_face_id / 6;
		uint face = light_face_id % 6;
		float3 world_normal = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));
		float3 new_pos = pv_modifiable.world_position.xyz - world_normal.xyz * 0.001;

		int shadow_index = visible_lights_params[light_index].shadow_params_index;
#ifdef TRANSLUCENT
		float4 shadow_tc = mul(visible_light_shadow_params[shadow_index].shadow_view_proj[face], float4(pv_modifiable.world_position.xyz, 1));
#else
		float4 shadow_tc = mul(visible_light_shadow_params[shadow_index].shadow_view_proj[face], float4(new_pos.xyz, 1));
#endif

		float4 shadow_tc_copy = shadow_tc;
		shadow_tc.xyz = shadow_tc.xyz / (shadow_tc.w);
		shadow_tc.x = shadow_tc.x / 2 + 0.5;
		shadow_tc.y = shadow_tc.y / 2 + 0.5;
		shadow_tc.y = 1.0 - shadow_tc.y;

		shadow_tc.xy *= visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].zw;
		shadow_tc.xy += visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].xy;
		shadow_tc.xy = shadow_tc.xy * 2.0 - 1.0f;
		shadow_tc.y *= -1;

// 		if (g_debug_vector.x)
// 		{
// 			Out.position = float4(1, 0, 0, 1);
// 		}
// 		else
		{
			Out.position = float4(shadow_tc.xyz * shadow_tc_copy.w, shadow_tc_copy.w);
		}

		[unroll]
		for(uint i = 0; i < 4; i++)
		{
			Out.clip_distances[i] = GetClipDistance(pv_modifiable.world_position.xyz, visible_lights_params[light_index].position.xyz, light_index, face, i);
		}
	}
#endif

#if !defined(SHADOWMAP_PASS)
	Out.world_position = pv_modifiable.world_position;
#if ENABLE_DYNAMIC_INSTANCING || SYSTEM_USE_COMPRESSED_FLORA_INSTANCING
	Out.world_position.w = In.instanceID + INDEX_EPSILON;
#endif
#endif



#if USE_TESSELATION
#ifdef PN_TRIANGLES
	Out.world_position = pv_modifiable.object_position;
#ifndef SHADOWMAP_PASS
	Out.world_normal = float4(pv_modifiable.object_normal.xyz, 1);
#endif
#endif
#endif

}

void apply_multi_material_output_modifier(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
#if !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(SHADOWMAP_PASS)
	if (g_mesh_vector_argument_2.x <= 0.0)
	{
		output.vertex_color.a *= saturate(1.0 - output.vertex_color.b);
		output.vertex_color.rgb = float3(1, 0, 1);
	}
#endif
}

#endif

#endif
