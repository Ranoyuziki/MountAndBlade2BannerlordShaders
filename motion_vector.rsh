#ifndef MOTION_VECTOR_RSH
#define MOTION_VECTOR_RSH

#include "definitions.rsh"
#include "definitions_samplers.rsh"
#include "modular_struct_definitions.rsh"


#ifdef GBUFFER_PASS
#if PIXEL_SHADER

void set_gbuffer_camera_motion_vector(in Pixel_shader_input_type In, inout PS_OUTPUT_GBUFFER Out)
{
#if SYSTEM_WRITE_MOTION_VECTORS
	Out.gbuffer_motion_vector = float2(0.0, 0.0);

	float4 cur_uv = mul(g_viewproj_unjittered, float4(In.world_position.xyz, 1));
	cur_uv = cur_uv / cur_uv.w;
	cur_uv.xy = cur_uv.xy * 0.5 + 0.5;
	cur_uv.y = 1.0 - cur_uv.y;

	float2 ss_xy_position = 2.0 * cur_uv.xy - 1.0;
	float4 ss_position = float4(ss_xy_position.xy, In.position.z, 1.0);
	ss_position.y *= -1.0f;

	float4 prev_frame_ss_camera_pos = float4(0.0, 0.0, 0.0, 0.0);
	prev_frame_ss_camera_pos = mul(g_curr_to_prev_frame_ss_matrix, ss_position);
	prev_frame_ss_camera_pos = prev_frame_ss_camera_pos / prev_frame_ss_camera_pos.w;

	float2 prev_camera_uv = prev_frame_ss_camera_pos.xy * 0.5 + 0.5;
	prev_camera_uv.y = 1.0 - prev_camera_uv.y;

	Out.gbuffer_motion_vector = (cur_uv.xy - prev_camera_uv.xy);
#endif
}

void set_gbuffer_motion_vector(in Pixel_shader_input_type In, inout PS_OUTPUT_GBUFFER Out)
{

#if SYSTEM_WRITE_MOTION_VECTORS
#if ALIGNMENT_DEFORMATION_WITH_OFFSET
	Out.gbuffer_motion_vector = float2(0.0, 0.0);
	return;
#endif
	Out.gbuffer_motion_vector = float2(0.0, 0.0);


#if (VERTEX_DECLARATION != VDECL_POSTFX)
#if VDECL_HAS_SKIN_DATA
#if defined(SYSTEM_CLOTH_SIMULATION_ENABLED) 
 	float4 cur_uv = mul(g_viewproj_unjittered, mul(g_world, float4(In.object_space_position.xyz, 1))); 	
#else
	float4 cur_uv = mul(g_viewproj_unjittered, float4(In.world_position.xyz, 1));
#endif

 	cur_uv = cur_uv / cur_uv.w;
 	cur_uv.xy = cur_uv.xy * 0.5 + 0.5;
 	cur_uv.y = 1.0 - cur_uv.y;

	//float2 cur_uv = In.position.xy * g_application_halfpixel_viewport_size_inv.zw;

	float4 prev_frame_ss_object_pos = float4(0.0, 0.0, 0.0, 0.0);
	prev_frame_ss_object_pos = mul(g_mesh_prev_frame_transform, float4(In.prev_object_space_position, 1));
	prev_frame_ss_object_pos = prev_frame_ss_object_pos / prev_frame_ss_object_pos.w;

	float2 prev_object_uv = prev_frame_ss_object_pos.xy * 0.5 + 0.5;
	cur_uv.y = 1.0 - cur_uv.y;	

	Out.gbuffer_motion_vector = (cur_uv.xy - prev_object_uv.xy);
	Out.gbuffer_motion_vector.y = -1.0 * Out.gbuffer_motion_vector.y;
#else
 	float4 cur_uv = mul(g_viewproj_unjittered, float4(In.world_position.xyz, 1));
 	cur_uv = cur_uv / cur_uv.w;
 	cur_uv.xy = cur_uv.xy * 0.5 + 0.5;
 	cur_uv.y = 1.0 - cur_uv.y;

	//float2 cur_uv = In.position.xy * g_application_halfpixel_viewport_size_inv.zw;

	float4 prev_frame_ss_object_pos = float4(0.0, 0.0, 0.0, 0.0);

#if my_material_id != MATERIAL_ID_TERRAIN
	prev_frame_ss_object_pos = mul(g_mesh_prev_frame_transform, float4(In.world_position.xyz, 1));
#else
	prev_frame_ss_object_pos = mul(g_custom_matrix, float4(In.world_position.xyz, 1));
#endif
	prev_frame_ss_object_pos = prev_frame_ss_object_pos / prev_frame_ss_object_pos.w;

	float2 prev_object_uv = prev_frame_ss_object_pos.xy * 0.5 + 0.5;
	prev_object_uv.y = 1.0 - prev_object_uv.y;

	Out.gbuffer_motion_vector = (cur_uv.xy - prev_object_uv);
#endif
#endif
#endif
}


#endif
#endif
#endif
