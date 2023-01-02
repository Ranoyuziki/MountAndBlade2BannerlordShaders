//TODO_BURAK_CLOTH we already have skinned current vertices from gpu skinning pass, use them

#include "definitions.rsh"

#include "math_conversions.rsh"

//TODO_BURAK divide into functions and files?

//If you change these limits, make sure you also changed the limits CLOTH_POSITION_COMPRESSION_MAX/MIN in vertex shader function
#define POSITION_COMPRESSION_MAX (float3(5.0, 5.0, 5.0) * 2)
#define POSITION_COMPRESSION_MIN (float3(-5.0, -5.0, -5.0) * 2)
#define REST_POS 10

#define THREAD_COUNT 128

#ifndef SKINNED_MESH
#define SKINNED_MESH 0
#endif

#ifndef USE_COLLISION
#define USE_COLLISION 0
#endif

#ifndef TELEPORT_MODE
#define TELEPORT_MODE 0
#endif

#ifndef USE_SHARED_MEMORY
#define USE_SHARED_MEMORY 0
#endif

#if USE_SHARED_MEMORY
#define USE_SHARED_MEMORY_FOR_NORMALS 1
#else
#define USE_SHARED_MEMORY_FOR_NORMALS 0
#endif

//At high iteration frequencies, this results jittering due to compression errors
#if PRECISE_SIMULATION
#define PACKED_GS_POSITIONS 0
#else
#define PACKED_GS_POSITIONS 1
#endif

#ifdef __PSSL__
#define RGL_PRECISE
#else
#define RGL_PRECISE precise
#endif

#if USE_SHARED_MEMORY
#if PACKED_GS_POSITIONS
groupshared uint gs_positions[1024 * 2];
#else
groupshared float gs_positions[1024 * 3];
#endif
#endif

groupshared float4 gs_global_buffer[1024];

struct Simulation_info
{
	float _stretching;
	float _bending;
	float _shearing;
	int _constraint_set_count;

	int _iteration_count;
	float _iteration_dt;
	int _vertex_count;
	float padding0;

	uint _simulation_start_index;
	int _start_with_rest_state;
	uint _bone_count;
	uint _virtual_particle_entry_count;

	int _capsule_count;
	int _capsule_offset;
	float _max_distance_multiplier;
	float _damping;

	float4 _accel;

	float4 _prev_bias;

	int _bone_buffer_offset;
	int _prev_bone_buffer_offset;
	int _dummy_particle_set_count;
	int normal_update_start_index_;

	float3 bbox_min_;
	float padding1;

	float3 bbox_max_;
	float bone_frames_z_displacement_;

	float3 wind_dir_;
	float wind_alpha_;

	float anchor_scale_;
	float anchor_stiffness_;
	int padding5;
	int padding_;

	int _constraints_offset_;
	int _constraint_sets_offset_;
	int _dummy_particle_indices_offset_;
	int _dummy_particle_sets_offset_;

	int _rest_lengths_offset_;
	int _rest_positions_offset_;
	int _max_distance_offset_;
	int _bone_weights_offset_;

	int _bone_indices_offset_;
	int _vertex_area_sums_offset_;
	int anchor_constraints_offset_;
	int _positions_offset_;

	int _normals_offset_;
	int padding6;
	int padding7;
	int padding8;
};

cbuffer a : register(b_custom_0)
{
	Simulation_info g_params[64];
};

#define stretching								g_params[group_id.x]._stretching
#define bending									g_params[group_id.x]._bending
#define shearing								g_params[group_id.x]._shearing
#define constraint_set_count					g_params[group_id.x]._constraint_set_count
#define iteration_count							g_params[group_id.x]._iteration_count
#define g_iteration_dt							g_params[group_id.x]._iteration_dt
#define g_vertex_count							g_params[group_id.x]._vertex_count
#define simulation_start_index					g_params[group_id.x]._simulation_start_index
#define g_start_with_rest_state					g_params[group_id.x]._start_with_rest_state
#define g_bone_count							g_params[group_id.x]._bone_count
#define virtual_particle_entry_count			g_params[group_id.x]._virtual_particle_entry_count
#define g_capsule_count							g_params[group_id.x]._capsule_count
#define g_capsule_offset						g_params[group_id.x]._capsule_offset
#define max_distance_multiplier					g_params[group_id.x]._max_distance_multiplier
#define g_damping								g_params[group_id.x]._damping
#define accel									g_params[group_id.x]._accel
#define prev_bias								g_params[group_id.x]._prev_bias
#define bone_buffer_offset						g_params[group_id.x]._bone_buffer_offset
#define prev_bone_buffer_offset					g_params[group_id.x]._prev_bone_buffer_offset
#define dummy_particle_set_count				g_params[group_id.x]._dummy_particle_set_count
#define g_anchor_constraints_offset				g_params[group_id.x].anchor_constraints_offset_
#define defragmentation_offset					g_params[group_id.x]._defragmentation_offset
#define constraints_offset_						g_params[group_id.x]._constraints_offset_
#define constraint_sets_offset_					g_params[group_id.x]._constraint_sets_offset_
#define dummy_particle_indices_offset_			g_params[group_id.x]._dummy_particle_indices_offset_
#define dummy_particle_sets_offset_				g_params[group_id.x]._dummy_particle_sets_offset_
#define rest_lengths_offset_					g_params[group_id.x]._rest_lengths_offset_
#define rest_positions_offset_					g_params[group_id.x]._rest_positions_offset_
#define max_distance_offset_					g_params[group_id.x]._max_distance_offset_
#define bone_weights_offset_					g_params[group_id.x]._bone_weights_offset_
#define bone_indices_offset_					g_params[group_id.x]._bone_indices_offset_
#define vertex_area_sums_offset_				g_params[group_id.x]._vertex_area_sums_offset_
#define positions_offset_						g_params[group_id.x]._positions_offset_
#define normals_offset_							g_params[group_id.x]._normals_offset_
#define g_normal_update_start_index				g_params[group_id.x].normal_update_start_index_
#define g_bbox_min								g_params[group_id.x].bbox_min_
#define g_bbox_max								g_params[group_id.x].bbox_max_
#define g_wind_dir								g_params[group_id.x].wind_dir_
#define g_wind_alpha							g_params[group_id.x].wind_alpha_
#define g_bone_frames_z_displacement			g_params[group_id.x].bone_frames_z_displacement_
#define g_anchor_scale							g_params[group_id.x].anchor_scale_
#define g_anchor_stiffness						g_params[group_id.x].anchor_stiffness_

void encode_position_flt3_to_ui2(float3 pos, float3 bbox_max, float3 bbox_min, out unsigned int x, out unsigned int y)
{
	float3 d_pos = bbox_max - bbox_min;
	float3 normalized_pos = (pos - bbox_min) / d_pos;
	unsigned int x_int = normalized_pos.x * 0x1FFFFF;
	unsigned int y_int = normalized_pos.y * 0x1FFFFF;
	unsigned int z_int = normalized_pos.z * 0x1FFFFF;
	x = (x_int << 11) | ((y_int & 0x1FFC00) >> 10);
	y = ((y_int & 0x3FF) << 22) | (z_int << 1);
}

void decode_position_ui2_to_flt3(unsigned int x, unsigned int y, float3 bbox_max, float3 bbox_min, out float3 pos)
{
	float3 d_pos = bbox_max - bbox_min;
	unsigned int x_int = (x & 0xFFFFF800) >> 11;
	unsigned int y_int = ((x & 0x7FF) << 10) | ((y & 0xFFC00000) >> 22);
	unsigned int z_int = (y & 0x3FFFFE) >> 1;
	pos = float3(x_int, y_int, z_int) / 0x1FFFFF;
	pos *= d_pos;
	pos += bbox_min;
}
#if PACKED_GS_POSITIONS
uint2 pack_position_gs(const float3 pos)
{
	uint2 packed_pos;
	encode_position_flt3_to_ui2(pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, packed_pos.x, packed_pos.y);
	return packed_pos;
}

float3 unpack_position_gs(const uint2 pos)
{
	float3 unpacked_pos;
	decode_position_ui2_to_flt3(pos.x, pos.y, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, unpacked_pos);
	return unpacked_pos;
}
#endif

#if USE_SHARED_MEMORY
void sm_store_position(int vertex_count, const float3 pos, const int vertex_index)
{
#if PACKED_GS_POSITIONS
	uint2 packed_pos = pack_position_gs(pos);
	gs_positions[vertex_index] = packed_pos.x;
	gs_positions[vertex_index + vertex_count] = packed_pos.y;
#else
	gs_positions[vertex_index] = pos.x;
	gs_positions[vertex_index + vertex_count] = pos.y;
	gs_positions[vertex_index + vertex_count * 2] = pos.z;
#endif
}

float3 sm_load_position(int vertex_count, const int vertex_index)
{
#if PACKED_GS_POSITIONS	
	return unpack_position_gs(uint2(gs_positions[vertex_index], gs_positions[vertex_index + vertex_count]));
#else
	return float3(gs_positions[vertex_index], gs_positions[vertex_index + vertex_count], gs_positions[vertex_index + vertex_count * 2]);
#endif
}

#endif

#ifdef USE_DIRECTX12
#define constraint_sets (StructuredBuffer_Constraint_set_table[indices.t_custom_0])
#define constraints (Buffer_uint2_table[indices.t_custom_1])
#define rest_lengths (Buffer_float_table[indices.t_custom_2])
#define max_distances (Buffer_float_table[indices.t_custom_3])
#define rest_positions (Buffer_uint_table[indices.t_custom_4])
#define virtual_particle_indices (Buffer_uint3_table[indices.t_custom_5])
#define vertex_area_sums (Buffer_float_table[indices.t_custom_8])
#define capsules (StructuredBuffer_Capsule3_table[indices.t_custom_11])
#define dummy_particle_sets (StructuredBuffer_Dummy_particle_set_table[indices.t_custom_12])
#define rest_normals (Buffer_uint_table[indices.t_custom_13])
#define anchor_constraints (Buffer_uint_table[indices.t_custom_14])

#define previous_positions (RWBuffer_uint_table[indices.u_custom_0])
#define current_positions (RWBuffer_uint_table[indices.u_custom_1])
#define vertex_normals (RWBuffer_uint_table[indices.u_custom_4])
#else
StructuredBuffer<Constraint_set>		constraint_sets					:	register(t_custom_0);
Buffer<uint2>							constraints						:	register(t_custom_1);
Buffer<float>							rest_lengths					:	register(t_custom_2);
Buffer<float>							max_distances					:	register(t_custom_3);
Buffer<uint>							rest_positions					:	register(t_custom_4);
Buffer<uint3>							virtual_particle_indices		:	register(t_custom_5);
Buffer<float>							vertex_area_sums				:	register(t_custom_8);
StructuredBuffer<Capsule3>				capsules						:	register(t_custom_11);
StructuredBuffer<Dummy_particle_set>	dummy_particle_sets				:	register(t_custom_12);
Buffer<uint>							rest_normals					:	register(t_custom_13);
Buffer<uint>							anchor_constraints				:	register(t_custom_14);

RWBuffer<uint>		previous_positions	:	register(u_custom_0);
RWBuffer<uint>		current_positions	:	register(u_custom_1);
RWBuffer<uint>		vertex_normals		:	register(u_custom_4);
#endif

void satisfy_constraint2(inout RGL_PRECISE float4 v1, inout RGL_PRECISE float4 v2, float rest_length, float stifness)
{
	float3 v1_to_v2 = v2.xyz - v1.xyz;
	float e = 1.0 - (rest_length / (length(v1_to_v2)));
	float3 stretching_amount = (v1_to_v2 * e * stifness) / (v1.w + v2.w);
	v1.zyx = v1.zyx + stretching_amount.zyx * v1.w;
	v2.zyx = v2.zyx - stretching_amount.zyx * v2.w;
}

float4x4 matrix_from_quaternion(float4 quat, float4 pos)
{
	float two_xx, two_wx, two_wy, two_wz, two_yy, two_yz, two_xy, two_xz, two_zz;
	float two_x, two_y, two_z;

	// calculate coefficients
	two_x = quat.x + quat.x; two_y = quat.y + quat.y;
	two_z = quat.z + quat.z;
	two_xx = quat.x * two_x;   two_xy = quat.x * two_y;   two_xz = quat.x * two_z;
	two_yy = quat.y * two_y;   two_yz = quat.y * two_z;   two_zz = quat.z * two_z;
	two_wx = quat.w * two_x;   two_wy = quat.w * two_y;   two_wz = quat.w * two_z;

	float4x4 m;

	m._m00 = 1.0 - (two_yy + two_zz);	m._m10 = two_xy + two_wz;			m._m20 = two_xz - two_wy;			m._m30 = 0;
	m._m01 = two_xy - two_wz;	        m._m11 = 1.0 - (two_xx + two_zz);	m._m21 = two_yz + two_wx;			m._m31 = 0;
	m._m02 = two_xz + two_wy;	        m._m12 = two_yz - two_wx;			m._m22 = 1.0 - (two_xx + two_yy);	m._m32 = 0;
	m._m03 = pos.x;					    m._m13 = pos.y;						m._m23 = pos.z;						m._m33 = 1.0;

	return m;
}

float4 quaternion_from_matrix(float3x3 mat)
{
	float4 quat;
	float trace = mat[0][0] + mat[1][1] + mat[2][2];
	if (trace > 0.0f)
	{
		float s = sqrt(trace + 1.0);
		quat.w = 0.5f * s;
		s = 0.5f / s;
		quat.x = (mat[2][1] - mat[1][2]) * s;
		quat.y = (mat[0][2] - mat[2][0]) * s;
		quat.z = (mat[1][0] - mat[0][1]) * s;
	}
	else
	{
		if (mat[0][0] > mat[1][1] && mat[0][0] > mat[2][2])
		{
			float s = 2.0 * sqrt(1.0 + mat[0][0] - mat[1][1] - mat[2][2]);
			float inv_s = 1 / s;

			quat.w = (mat[2][1] - mat[1][2]) * inv_s;
			quat.x = 0.25f * s;
			quat.y = (mat[0][1] + mat[1][0]) * inv_s;
			quat.z = (mat[0][2] + mat[2][0]) * inv_s;
		}
		else if (mat[1][1] > mat[2][2])
		{
			float s = 2.0 * sqrt(1.0 + mat[1][1] - mat[0][0] - mat[2][2]);
			float inv_s = 1 / s;

			quat.w = (mat[0][2] - mat[2][0]) * inv_s;
			quat.x = (mat[0][1] + mat[1][0]) * inv_s;
			quat.y = 0.25f * s;
			quat.z = (mat[1][2] + mat[2][1]) * inv_s;
		}
		else
		{
			float s = 2.0 * sqrt(1.0 + mat[2][2] - mat[0][0] - mat[1][1]);
			float inv_s = 1 / s;

			quat.w = (mat[1][0] - mat[0][1]) * inv_s;
			quat.x = (mat[0][2] + mat[2][0]) * inv_s;
			quat.y = (mat[1][2] + mat[2][1]) * inv_s;
			quat.z = 0.25f * s;
		}
	}

	return quat;
}

float3 ensure_point_is_outside_of_cone(float3 c0, float r0, float3 c1, float r1, float3 vertex)
{
	const float3 axis = c1 - c0;
	const float axis_len = length(axis);
	const float3 axis_dir = axis / (axis_len + 0.00001);
	const float3 c0_to_point = vertex - c0;
	const float proj_on_axis = dot(c0_to_point, axis_dir);
	const float clamped_proj = clamp(proj_on_axis, 0, axis_len);
	const float normalized_proj = clamped_proj / (axis_len + 0.00001);
	const float current_radius = lerp(r0, r1, normalized_proj);
	const float3 closest_point = axis_dir * clamped_proj + c0;
	const float3 closest_point_to_point = vertex - closest_point;
	const float closest_point_to_point_len = length(closest_point_to_point);
	const float3 closest_point_to_point_norm = closest_point_to_point / closest_point_to_point_len;
	return closest_point + closest_point_to_point_norm * max(closest_point_to_point_len, current_radius);
}

void solve_constraint_range(const uint3 group_id, int start_index, int end_index, float stiffness, bool even_odd)
{
	int vertex_count = g_vertex_count;
	for (int i_constraint = start_index; i_constraint < end_index; i_constraint += THREAD_COUNT)
	{
		const uint2 cur_constraint = constraints[i_constraint];

		float4 v1;
		float4 v2;
#if USE_SHARED_MEMORY
		v1.xyz = sm_load_position(vertex_count, cur_constraint.x);
		v2.xyz = sm_load_position(vertex_count, cur_constraint.y);
#else
		int x1_index = cur_constraint.x * 2 + 0 + positions_offset_;
		int y1_index = cur_constraint.x * 2 + 1 + positions_offset_;

		int x2_index = cur_constraint.y * 2 + 0 + positions_offset_;
		int y2_index = cur_constraint.y * 2 + 1 + positions_offset_;
		decode_position_ui2_to_flt3(current_positions[x1_index], current_positions[y1_index], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, v1.xyz);
		decode_position_ui2_to_flt3(current_positions[x2_index], current_positions[y2_index], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, v2.xyz);
#endif		
		v2.w = cur_constraint.y < simulation_start_index ? 0.0 : 1.0;
		v1.w = cur_constraint.x < simulation_start_index ? 0.0 : 1.0;

		satisfy_constraint2(v1, v2, rest_lengths[i_constraint], stiffness);

#if USE_SHARED_MEMORY
		sm_store_position(vertex_count, v1.xyz, cur_constraint.x);
		sm_store_position(vertex_count, v2.xyz, cur_constraint.y);
#else
		uint encoded_x;
		uint encoded_y;
		encode_position_flt3_to_ui2(v1.xyz, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
		current_positions[x1_index] = encoded_x;
		current_positions[y1_index] = encoded_y;
		encode_position_flt3_to_ui2(v2.xyz, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
		current_positions[x2_index] = encoded_x;
		current_positions[y2_index] = encoded_y;
#endif		
	}
}

void solve_constraint_range2(
	const uint3 group_id, int start_index, int end_index, 
	int stretching_start, float stretching_stiffness, 
	int bending_start, float bending_stiffness,
	int shearing_start, float shearing_stiffness)
{
	int vertex_count = g_vertex_count;
	for (int i_constraint = start_index; i_constraint < end_index; i_constraint += THREAD_COUNT)
	{
		float stiffness = (i_constraint >= bending_start) ? bending_stiffness :
			(i_constraint >= shearing_start ? shearing_stiffness : stretching_stiffness);
		const uint2 cur_constraint = constraints[i_constraint];

		float4 v1;
		float4 v2;
#if USE_SHARED_MEMORY
		v1.xyz = sm_load_position(vertex_count, cur_constraint.x);
		v2.xyz = sm_load_position(vertex_count, cur_constraint.y);
#else
		int x1_index = cur_constraint.x * 2 + 0 + positions_offset_;
		int y1_index = cur_constraint.x * 2 + 1 + positions_offset_;

		int x2_index = cur_constraint.y * 2 + 0 + positions_offset_;
		int y2_index = cur_constraint.y * 2 + 1 + positions_offset_;
		decode_position_ui2_to_flt3(current_positions[x1_index], current_positions[y1_index], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, v1.xyz);
		decode_position_ui2_to_flt3(current_positions[x2_index], current_positions[y2_index], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, v2.xyz);
#endif		
		v2.w = cur_constraint.y < simulation_start_index ? 0.0 : 1.0;
		v1.w = cur_constraint.x < simulation_start_index ? 0.0 : 1.0;

		satisfy_constraint2(v1, v2, rest_lengths[i_constraint], stiffness);

#if USE_SHARED_MEMORY
		sm_store_position(vertex_count, v1.xyz, cur_constraint.x);
		sm_store_position(vertex_count, v2.xyz, cur_constraint.y);
#else
		uint encoded_x;
		uint encoded_y;
		encode_position_flt3_to_ui2(v1.xyz, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
		current_positions[x1_index] = encoded_x;
		current_positions[y1_index] = encoded_y;
		encode_position_flt3_to_ui2(v2.xyz, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
		current_positions[x2_index] = encoded_x;
		current_positions[y2_index] = encoded_y;
#endif		
	}
}



float4 lerp_quaternion(float4 x, float4 y, float alpha)
{
	float one_minus_alpha = 1.0 - alpha;
	float cos_ = dot(x, y);
	if (cos_ < 0)
	{
		alpha *= -1.0;
	}

	return x * one_minus_alpha + y * alpha;
}


#if SKINNED_MESH

#ifdef USE_DIRECTX12
#define prev_skinning_buffer (Buffer_float4_table[indices.t_custom_6])
#define skinning_buffer (Buffer_float4_table[indices.t_custom_7])
#define bone_indices (Buffer_uint4_table[indices.t_custom_9])
#define bone_weights (Buffer_float4_table[indices.t_custom_10])
#else
Buffer<float4> prev_skinning_buffer			:	register(t_custom_6);
Buffer<float4> skinning_buffer				:	register(t_custom_7);
Buffer<uint4>							bone_indices	:	register(t_custom_9);
Buffer<float4>							bone_weights	:	register(t_custom_10);
#endif

float3 compute_skinned_position_4bone(float3 pos, float4 weights, uint4 indices_arg)
{
	float4 local_pos = float4(pos, 1);
	float3 skinning_position = float3(0, 0, 0);
	float3 bone_influences[2];
	bone_influences[0] = float3(dot(local_pos, gs_global_buffer[indices_arg.x + 0]), dot(local_pos, gs_global_buffer[indices_arg.x + 1]), dot(local_pos, gs_global_buffer[indices_arg.x + 2]));
	bone_influences[1] = float3(dot(local_pos, gs_global_buffer[indices_arg.y + 0]), dot(local_pos, gs_global_buffer[indices_arg.y + 1]), dot(local_pos, gs_global_buffer[indices_arg.y + 2]));
	skinning_position += bone_influences[0] * weights.x + bone_influences[1] * weights.y;
	bone_influences[0] = float3(dot(local_pos, gs_global_buffer[indices_arg.z + 0]), dot(local_pos, gs_global_buffer[indices_arg.z + 1]), dot(local_pos, gs_global_buffer[indices_arg.z + 2]));
	bone_influences[1] = float3(dot(local_pos, gs_global_buffer[indices_arg.w + 0]), dot(local_pos, gs_global_buffer[indices_arg.w + 1]), dot(local_pos, gs_global_buffer[indices_arg.w + 2]));
	skinning_position += bone_influences[0] * weights.z + bone_influences[1] * weights.w;
	return skinning_position.rgb;
}

float3 compute_skinned_position_2bone(float3 pos, float2 weights, int2 indices_arg)
{
	float4 local_pos = float4(pos, 1);
	float3 bone_influences[2];
	bone_influences[0] = float3(dot(local_pos, gs_global_buffer[indices_arg.x + 0]), dot(local_pos, gs_global_buffer[indices_arg.x + 1]), dot(local_pos, gs_global_buffer[indices_arg.x + 2]));
	bone_influences[1] = float3(dot(local_pos, gs_global_buffer[indices_arg.y + 0]), dot(local_pos, gs_global_buffer[indices_arg.y + 1]), dot(local_pos, gs_global_buffer[indices_arg.y + 2]));
	return bone_influences[0] * weights.x + bone_influences[1] * weights.y;
}

[numthreads(THREAD_COUNT, 1, 1)]
void main_cs(uint3 thread_id : SV_GroupThreadID, uint3 group_id : SV_GroupID)
{
#if TELEPORT_MODE
	if (thread_id.x < uint(g_bone_count))
	{
		int current_matrix_index = bone_buffer_offset + thread_id.x;
		float4x4 current_matrix = unpack_skinning_matrix(
			skinning_buffer[current_matrix_index * 3 + 0],
			skinning_buffer[current_matrix_index * 3 + 1],
			skinning_buffer[current_matrix_index * 3 + 2]
		);
		current_matrix = transpose(current_matrix);
		current_matrix[2][3] -= g_bone_frames_z_displacement;
		gs_global_buffer[thread_id.x * 3 + 0] = current_matrix[0];
		gs_global_buffer[thread_id.x * 3 + 1] = current_matrix[1];
		gs_global_buffer[thread_id.x * 3 + 2] = current_matrix[2];
	}

	GroupMemoryBarrierWithGroupSync();

	for (int i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		float4 bone_weight = bone_weights[i_vertex + bone_weights_offset_];
		uint4 blend_indice = bone_indices[i_vertex + bone_indices_offset_] * 3;
		float4 local_pos;
		decode_position_ui2_to_flt3(rest_positions[i_vertex * 2 + 0 + rest_positions_offset_], rest_positions[i_vertex * 2 + 1 + rest_positions_offset_],
			POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, local_pos.xyz);
		local_pos.w = 1;

		float4 skinning_position = float4(compute_skinned_position_4bone(local_pos.xyz, bone_weight, blend_indice), 1);
		uint encoded_x;
		uint encoded_y;
		encode_position_flt3_to_ui2(skinning_position.xyz, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);

		previous_positions[i_vertex * 2 + 0 + positions_offset_] = encoded_x;
		previous_positions[i_vertex * 2 + 1 + positions_offset_] = encoded_y;

		current_positions[i_vertex * 2 + 0 + positions_offset_] = encoded_x;
		current_positions[i_vertex * 2 + 1 + positions_offset_] = encoded_y;

		vertex_normals[i_vertex + normals_offset_] = rest_normals[i_vertex + (rest_positions_offset_ >> 1)];
	}
#else //TELEPORT_MODE
	int i_vertex;
	/*
	Bone matrices are always cached in shared memory.
	If shared memory is enabled also for simulation first g_vertex_count elements of it are
	reserved for current positions.Rest of it used for bone matrices until normal calculation step.
	During normal calculation vertex normals use bone matrix memory
	*/
	if (thread_id.x < uint(g_bone_count))
	{
		//Calculate cur iteration's blended bone frames and store in shared memory
		//Do not start alpha from zero. Prev pos buffer contains position calculated with those bone frames already
		//float alpha = (i_iteration + 1.0) / iteration_count;
		//int prev_matrix_index = prev_bone_buffer_offset + thread_id.x;
		int current_matrix_index = bone_buffer_offset + thread_id.x;
		//float4x4 prev_matrix = prev_skinning_buffer[prev_matrix_index];
		float4x4 current_matrix = unpack_skinning_matrix_4x4(
			skinning_buffer[current_matrix_index * 3 + 0],
			skinning_buffer[current_matrix_index * 3 + 1],
			skinning_buffer[current_matrix_index * 3 + 2]
		);
		current_matrix = transpose(current_matrix);
		current_matrix[2][3] -= g_bone_frames_z_displacement;
		//float4 prev_quat = quaternion_from_matrix(to_float3x3(prev_matrix));
		//float4 current_quat = quaternion_from_matrix(to_float3x3(current_matrix));
		//float4 blended_quat = lerp_quaternion(prev_quat, current_quat, alpha);
		//float4 current_pos = lerp(get_column(prev_matrix, 3), get_column(current_matrix, 3), alpha);
		//float4x4 bone_matrix = matrix_from_quaternion(blended_quat/*.yzwx*/, current_pos);
		gs_global_buffer[thread_id.x * 3 + 0] = current_matrix[0];
		gs_global_buffer[thread_id.x * 3 + 1] = current_matrix[1];
		gs_global_buffer[thread_id.x * 3 + 2] = current_matrix[2];
	}
	GroupMemoryBarrierWithGroupSync();
	int vertex_count = g_vertex_count;
#if USE_SHARED_MEMORY
	for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		const int x_index = i_vertex * 2 + 0;
		const int y_index = i_vertex * 2 + 1;
		float3 cur_pos;
		if (g_start_with_rest_state)
		{
			float4 bone_weight = bone_weights[i_vertex + bone_weights_offset_];
			uint4 blend_indice = bone_indices[i_vertex + bone_indices_offset_] * 3;
			uint x = rest_positions[x_index + rest_positions_offset_];
			uint y = rest_positions[y_index + rest_positions_offset_];
			decode_position_ui2_to_flt3(x, y, POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, cur_pos);
			cur_pos = compute_skinned_position_4bone(cur_pos, bone_weight, blend_indice);
			encode_position_flt3_to_ui2(cur_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, x, y);
			previous_positions[x_index + positions_offset_] = x;
			previous_positions[y_index + positions_offset_] = y;
		}
		else
		{
			decode_position_ui2_to_flt3(current_positions[x_index + positions_offset_], current_positions[y_index + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, cur_pos);
		}
		sm_store_position(vertex_count, cur_pos, i_vertex);
	}
	if (g_start_with_rest_state)
	{
		//Both prev and cur positions are updated
		AllMemoryBarrierWithGroupSync();
	}
	else
	{
		GroupMemoryBarrierWithGroupSync();
	}
#else //USE_SHARED_MEMORY
	if (g_start_with_rest_state)
	{
		for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
		{
			const int x_index = i_vertex * 2 + 0;
			const int y_index = i_vertex * 2 + 1;
			float4 bone_weight = bone_weights[i_vertex + bone_weights_offset_];
			uint4 blend_indice = bone_indices[i_vertex + bone_indices_offset_] * 3;
			float3 cur_pos;
			uint x = rest_positions[i_vertex * 2 + 0 + rest_positions_offset_];
			uint y = rest_positions[i_vertex * 2 + 1 + rest_positions_offset_];
			decode_position_ui2_to_flt3(x, y, POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, cur_pos);
			cur_pos = compute_skinned_position_4bone(cur_pos, bone_weight, blend_indice);
			encode_position_flt3_to_ui2(cur_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, x, y);
			previous_positions[i_vertex * 2 + 0 + positions_offset_] = x;
			previous_positions[i_vertex * 2 + 1 + positions_offset_] = y;
			current_positions[i_vertex * 2 + 0 + positions_offset_] = x;
			current_positions[i_vertex * 2 + 1 + positions_offset_] = y;
		}
		DeviceMemoryBarrierWithGroupSync();
	}
#endif //USE_SHARED_MEMORY

	if (thread_id.x < uint(g_capsule_count))
	{
		const Capsule3 cur_capsule = capsules[thread_id.x + g_capsule_offset];
		uint2 indices_0 = cur_capsule.point0_bone_indices_ * 3;
		uint2 indices_1 = cur_capsule.point1_bone_indices_ * 3;
		const float3 skinned_p0 = compute_skinned_position_2bone(cur_capsule.point0_, cur_capsule.point0_bone_weights_, indices_0);
		const float3 skinned_p1 = compute_skinned_position_2bone(cur_capsule.point1_, cur_capsule.point1_bone_weights_, indices_1);

		gs_global_buffer[g_bone_count * 3 + thread_id.x * 2 + 0] = float4(skinned_p0, cur_capsule.radius0_);
		gs_global_buffer[g_bone_count * 3 + thread_id.x * 2 + 1] = float4(skinned_p1, cur_capsule.radius1_);
	}

	GroupMemoryBarrierWithGroupSync();

	for (int i_iteration = 0; i_iteration < iteration_count; i_iteration++)
	{
#if 1//INTEGRATE PARTICLES
		for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
		{
			const int x_index = i_vertex * 2 + 0;
			const int y_index = i_vertex * 2 + 1;
			float3 cur_pos;
			float3 prev_pos;
			float3 local_pos;
#if USE_SHARED_MEMORY
			cur_pos = sm_load_position(vertex_count, i_vertex);
#else
			decode_position_ui2_to_flt3(current_positions[x_index + positions_offset_], current_positions[y_index + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, cur_pos);
#endif
			decode_position_ui2_to_flt3(rest_positions[i_vertex * 2 + 0 + rest_positions_offset_], rest_positions[i_vertex * 2 + 1 + rest_positions_offset_],
				POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, local_pos);
			decode_position_ui2_to_flt3(previous_positions[x_index + positions_offset_], previous_positions[y_index + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, prev_pos);
			float4 bone_weight = bone_weights[i_vertex + bone_weights_offset_];
			uint4 blend_indice = bone_indices[i_vertex + bone_indices_offset_] * 3;
			const float3 skinning_position = compute_skinned_position_4bone(local_pos, bone_weight, blend_indice);
			// 			float3 vertex_normal;
			// 			unpack_normal_ui_to_flt3(vertex_normals[i_vertex + normals_offset_], vertex_normal);
			// 			float3 net_force = accel.xyz + pow(abs(dot(vertex_normal, float3(1,0,0))), 8) * 40 * 0.0166666675* 0.0166666675;
#if 1
			const float3 velocity = (cur_pos - prev_pos) * g_iteration_dt;
			float3 dV = g_wind_dir - velocity;
			float3 vertex_normal = unpack_normal_ui_to_flt3(vertex_normals[i_vertex + normals_offset_]);			

			dV *= saturate(abs(dot(vertex_normal, normalize(dV))) * g_wind_alpha);
			const float3 dS = (cur_pos - prev_pos) * g_damping + accel.xyz + dV * g_iteration_dt * g_iteration_dt;
#else
			const float3 dS = (cur_pos - prev_pos) * g_damping + accel.xyz;
#endif
			float3 next_position = cur_pos + dS;
			const float3 prev_position = cur_pos + prev_bias.xyz;

			float max_distance = max_distances[i_vertex + max_distance_offset_] * max_distance_multiplier;
			float3 to_cur = next_position - skinning_position;
			float to_cur_len = length(to_cur);
			float valid_len = clamp(to_cur_len, 0, max_distance);
			next_position = skinning_position + (to_cur / (to_cur_len + 0.00001)) * valid_len;

			uint encoded_x;
			uint encoded_y;
			encode_position_flt3_to_ui2(prev_position, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
			previous_positions[x_index + positions_offset_] = encoded_x;
			previous_positions[y_index + positions_offset_] = encoded_y;
#if USE_SHARED_MEMORY
			sm_store_position(vertex_count, next_position, i_vertex);
#else
			encode_position_flt3_to_ui2(next_position, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
			current_positions[x_index + positions_offset_] = encoded_x;
			current_positions[y_index + positions_offset_] = encoded_y;
#endif			
		}

#if USE_SHARED_MEMORY
		//TODO_BURAK Prev positions are not used until next iteration so no need to use Device barrier here. Check if it is valid
		GroupMemoryBarrierWithGroupSync();
#else
		DeviceMemoryBarrierWithGroupSync();
#endif

#endif


#if 1//ANCHOR CONSTRAINTS
		if (g_anchor_stiffness > 0)
		{
			for (i_vertex = thread_id.x + simulation_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
			{
				uint anchor_data = anchor_constraints[i_vertex + g_anchor_constraints_offset];
				int anchor_index = (anchor_data & 0xFFFF0000) >> 16;
				float anchor_len = (anchor_data & 0x0000FFFF) * g_anchor_scale;
#if USE_SHARED_MEMORY
				
				float3 vertex_pos = sm_load_position(vertex_count, i_vertex);
				const float3 anchor_pos = sm_load_position(vertex_count, anchor_index);
#else
				float3 vertex_pos;
				float3 anchor_pos;
				int x1_index = i_vertex * 2 + 0 + positions_offset_;
				int y1_index = i_vertex * 2 + 1 + positions_offset_;

				int x2_index = anchor_index * 2 + 0 + positions_offset_;
				int y2_index = anchor_index * 2 + 1 + positions_offset_;
				decode_position_ui2_to_flt3(current_positions[x1_index], current_positions[y1_index],
					POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, vertex_pos);
				decode_position_ui2_to_flt3(current_positions[x2_index], current_positions[y2_index],
					POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, anchor_pos);
#endif
				float3 delta = vertex_pos - anchor_pos;
				float delta_len = length(delta) + 0.00000001;
				if (delta_len > anchor_len)
				{
					vertex_pos = vertex_pos - (delta / delta_len) * (delta_len - anchor_len) * g_anchor_stiffness;
				}
#if USE_SHARED_MEMORY
				sm_store_position(vertex_count, vertex_pos, i_vertex);
#else
				uint encoded_x;
				uint encoded_y;
				encode_position_flt3_to_ui2(vertex_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
				current_positions[x1_index] = encoded_x;
				current_positions[y1_index] = encoded_y;
#endif
			}
#if USE_SHARED_MEMORY
			GroupMemoryBarrierWithGroupSync();
#else
			DeviceMemoryBarrierWithGroupSync();
#endif
		}
#endif



#if 1//FABRIC CONSTRAINTS
		for (int i_const_set = 0; i_const_set < constraint_set_count; i_const_set++)
		{
			const Constraint_set cur_set = constraint_sets[i_const_set + constraint_sets_offset_];
			int constraint_count = cur_set.bending_count_ + cur_set.shearing_count_ + cur_set.stretching_count_;
			solve_constraint_range2(group_id, cur_set.stretching_start_ + thread_id.x + constraints_offset_, cur_set.stretching_start_ + constraint_count + constraints_offset_,
				cur_set.stretching_start_, stretching, cur_set.bending_start_, bending, cur_set.shearing_start_, shearing);
#if USE_SHARED_MEMORY
			GroupMemoryBarrierWithGroupSync();
#else
			DeviceMemoryBarrierWithGroupSync();
#endif
		}
#endif

		if (g_capsule_count > 0)
		{
			for (i_vertex = thread_id.x + simulation_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
			{
				float3 cur_position;
#if USE_SHARED_MEMORY
				cur_position = sm_load_position(vertex_count, i_vertex);
#else
				const int x_index = i_vertex * 2 + 0;
				const int y_index = i_vertex * 2 + 1;
				decode_position_ui2_to_flt3(current_positions[x_index + positions_offset_], current_positions[y_index + positions_offset_],
					POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, cur_position);
#endif
				for (int i_capsule = 0; i_capsule < g_capsule_count; i_capsule++)
				{
					uint gs_index = g_bone_count * 3 + i_capsule * 2;
					float4 capsule_point0 = gs_global_buffer[gs_index + 0];
					float4 capsule_point1 = gs_global_buffer[gs_index + 1];
					cur_position = ensure_point_is_outside_of_cone(capsule_point0.xyz, capsule_point0.w, capsule_point1.xyz, capsule_point1.w, cur_position);
				}
#if USE_SHARED_MEMORY
				sm_store_position(vertex_count, cur_position, i_vertex);
#else
				uint encoded_x;
				uint encoded_y;
				encode_position_flt3_to_ui2(cur_position, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
				current_positions[x_index + positions_offset_] = encoded_x;
				current_positions[y_index + positions_offset_] = encoded_y;
#endif			
			}
#if USE_SHARED_MEMORY
			GroupMemoryBarrierWithGroupSync();
#else
			DeviceMemoryBarrierWithGroupSync();
#endif
#if DUMMY_COLLISION_PARTICLES
			const float3 weights[4] = {
				{ 4.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0 },
				{ 4.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0 },
				{ 4.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0 },
				{ 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0 },
			};

			const float rcp_weights_sum_sq[4] = {
				1.0 / dot(weights[0], weights[0]),
				1.0 / dot(weights[1], weights[1]),
				1.0 / dot(weights[2], weights[2]),
				1.0 / dot(weights[3], weights[3]),
			};

			const uint3 swizzled_indices[4] = { uint3(0,1,2), uint3(1,2,0), uint3(2,0,1), uint3(0,1,2) };

			for (int i_set = 0; i_set < dummy_particle_set_count; i_set++)
			{
				const Dummy_particle_set cur_set = dummy_particle_sets[i_set + dummy_particle_sets_offset_];
				int index_begin = cur_set.element_start_ + thread_id.x + dummy_particle_indices_offset_;
				int index_end = cur_set.element_start_ + cur_set.element_count_ + dummy_particle_indices_offset_;

				for (int i_vp = index_begin; i_vp < index_end; i_vp += THREAD_COUNT)
				{
					const uint3 vertex_indices = virtual_particle_indices[i_vp].xyz;

					float3 current_pos[3];
#if USE_SHARED_MEMORY					
					current_pos[0] = sm_load_position(vertex_count, vertex_indices.x);
					current_pos[1] = sm_load_position(vertex_count, vertex_indices.y);
					current_pos[2] = sm_load_position(vertex_count, vertex_indices.z);
#else
					const uint2 first_indices = vertex_indices.x * 2 + float2(0, 1) + positions_offset_;
					const uint2 second_indices = vertex_indices.y * 2 + float2(0, 1) + positions_offset_;
					const uint2 third_indices = vertex_indices.z * 2 + float2(0, 1) + positions_offset_;
					decode_position_ui2_to_flt3(current_positions[first_indices[0]], current_positions[first_indices[1]],
						POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[0]);
					decode_position_ui2_to_flt3(current_positions[second_indices[0]], current_positions[second_indices[1]],
						POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[1]);
					decode_position_ui2_to_flt3(current_positions[third_indices[0]], current_positions[third_indices[1]],
						POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[2]);
#endif
					[unroll]
					for (uint i_swiz = 0; i_swiz < 4; i_swiz++)
					{
						float3 virtual_position =
							current_pos[swizzled_indices[i_swiz].x] * weights[i_swiz].x +
							current_pos[swizzled_indices[i_swiz].y] * weights[i_swiz].y +
							current_pos[swizzled_indices[i_swiz].z] * weights[i_swiz].z;
						float3 ideal_position = virtual_position;
						for (int i_capsule = 0; i_capsule < g_capsule_count; i_capsule++)
						{
							uint gs_index = g_bone_count * 3 + i_capsule * 2;
							float4 capsule_point0 = gs_global_buffer[gs_index + 0];
							float4 capsule_point1 = gs_global_buffer[gs_index + 1];
							ideal_position = ensure_point_is_outside_of_cone(capsule_point0.xyz, capsule_point0.w, capsule_point1.xyz, capsule_point1.w, ideal_position);
						}

						float3 d_pos = ideal_position - virtual_position;

						current_pos[0] += d_pos * weights[i_swiz].x * rcp_weights_sum_sq[i_swiz];
						current_pos[1] += d_pos * weights[i_swiz].y * rcp_weights_sum_sq[i_swiz];
						current_pos[2] += d_pos * weights[i_swiz].z * rcp_weights_sum_sq[i_swiz];
					}
#if USE_SHARED_MEMORY
					sm_store_position(vertex_count, current_pos[0], vertex_indices.x);
					sm_store_position(vertex_count, current_pos[1], vertex_indices.y);
					sm_store_position(vertex_count, current_pos[2], vertex_indices.z);
#else
					uint encoded_x;
					uint encoded_y;
					encode_position_flt3_to_ui2(current_pos[0], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
					current_positions[first_indices[0]] = encoded_x;
					current_positions[first_indices[1]] = encoded_y;

					encode_position_flt3_to_ui2(current_pos[1], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
					current_positions[second_indices[0]] = encoded_x;
					current_positions[second_indices[1]] = encoded_y;

					encode_position_flt3_to_ui2(current_pos[2], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
					current_positions[third_indices[0]] = encoded_x;
					current_positions[third_indices[1]] = encoded_y;
#endif
				}
#if USE_SHARED_MEMORY
				GroupMemoryBarrierWithGroupSync();
#else
				DeviceMemoryBarrierWithGroupSync();
#endif
			}
#endif
		}
	}

#if USE_SHARED_MEMORY
	for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		const int x_index = i_vertex * 2 + 0 + positions_offset_;
		const int y_index = i_vertex * 2 + 1 + positions_offset_;
#if PACKED_GS_POSITIONS
		current_positions[x_index] = gs_positions[i_vertex];
		current_positions[y_index] = gs_positions[i_vertex + vertex_count];
#else
		uint encoded_x;
		uint encoded_y;
		encode_position_flt3_to_ui2(sm_load_position(vertex_count, i_vertex), POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
		current_positions[x_index] = encoded_x;
		current_positions[y_index] = encoded_y;
#endif		
	}
#endif

#if 1//COMPUTE_NORMALS
	//Set constant normals
	if (g_start_with_rest_state)
	{
		for (i_vertex = thread_id.x; i_vertex < g_normal_update_start_index; i_vertex += THREAD_COUNT)
		{
			vertex_normals[i_vertex + normals_offset_] = rest_normals[i_vertex + (rest_positions_offset_ >> 1)];
		}
	}

	//Reset simulated normals
	for (i_vertex = thread_id.x + g_normal_update_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
#if USE_SHARED_MEMORY_FOR_NORMALS
		gs_global_buffer[i_vertex].xyz = float3(0, 0, 0);
#else
		vertex_normals[i_vertex + normals_offset_] = pack_normal_flt3_to_ui(float3(0, 0, 0));
#endif
	}
#if USE_SHARED_MEMORY_FOR_NORMALS
	GroupMemoryBarrierWithGroupSync();
#else
	DeviceMemoryBarrierWithGroupSync();
#endif

	//Compute weighted normals
	for (int i_set = 0; i_set < dummy_particle_set_count; i_set++)
	{
		const Dummy_particle_set cur_set = dummy_particle_sets[i_set + dummy_particle_sets_offset_];
		int index_begin = cur_set.element_start_ + thread_id.x + dummy_particle_indices_offset_;
		int index_end = cur_set.element_start_ + cur_set.element_count_ + dummy_particle_indices_offset_;

		for (int i_vp = index_begin; i_vp < index_end; i_vp += THREAD_COUNT)
		{
			uint3 vertex_indices = virtual_particle_indices[i_vp].xyz;
			float3 current_pos[3];
#if USE_SHARED_MEMORY
			current_pos[0] = sm_load_position(vertex_count, vertex_indices.x);
			current_pos[1] = sm_load_position(vertex_count, vertex_indices.y);
			current_pos[2] = sm_load_position(vertex_count, vertex_indices.z);
#else
			decode_position_ui2_to_flt3(current_positions[vertex_indices.x * 2 + 0 + positions_offset_], current_positions[vertex_indices.x * 2 + 1 + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[0]);
			decode_position_ui2_to_flt3(current_positions[vertex_indices.y * 2 + 0 + positions_offset_], current_positions[vertex_indices.y * 2 + 1 + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[1]);
			decode_position_ui2_to_flt3(current_positions[vertex_indices.z * 2 + 0 + positions_offset_], current_positions[vertex_indices.z * 2 + 1 + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[2]);
#endif 			
			float3 decoded_normals[3];
			uint current_normals[3];
			float vertex_areas[3];
#if USE_SHARED_MEMORY_FOR_NORMALS
			decoded_normals[0] = gs_global_buffer[vertex_indices.x].xyz;
			decoded_normals[1] = gs_global_buffer[vertex_indices.y].xyz;
			decoded_normals[2] = gs_global_buffer[vertex_indices.z].xyz;
#else
			current_normals[0] = vertex_normals[vertex_indices.x + normals_offset_];
			current_normals[1] = vertex_normals[vertex_indices.y + normals_offset_];
			current_normals[2] = vertex_normals[vertex_indices.z + normals_offset_];
			
			decoded_normals[0] = unpack_normal_ui_to_flt3(current_normals[0]);
			decoded_normals[1] = unpack_normal_ui_to_flt3(current_normals[1]);
			decoded_normals[2] = unpack_normal_ui_to_flt3(current_normals[2]);
#endif
			vertex_areas[0] = vertex_area_sums[vertex_indices.x + vertex_area_sums_offset_];
			vertex_areas[1] = vertex_area_sums[vertex_indices.y + vertex_area_sums_offset_];
			vertex_areas[2] = vertex_area_sums[vertex_indices.z + vertex_area_sums_offset_];
			float3 face_normal = cross(current_pos[1] - current_pos[0], current_pos[2] - current_pos[0]);
			float face_area = length(face_normal) * 0.5;
			face_normal = normalize(face_normal);
			decoded_normals[0] += (face_normal * (face_area * vertex_areas[0]));
			decoded_normals[1] += (face_normal * (face_area * vertex_areas[1]));
			decoded_normals[2] += (face_normal * (face_area * vertex_areas[2]));
#if USE_SHARED_MEMORY_FOR_NORMALS
			gs_global_buffer[vertex_indices.x].xyz = decoded_normals[0];
			gs_global_buffer[vertex_indices.y].xyz = decoded_normals[1];
			gs_global_buffer[vertex_indices.z].xyz = decoded_normals[2];
#else
			current_normals[0] = pack_normal_flt3_to_ui(decoded_normals[0]);
			current_normals[1] = pack_normal_flt3_to_ui(decoded_normals[1]);
			current_normals[2] = pack_normal_flt3_to_ui(decoded_normals[2]);
			vertex_normals[vertex_indices.x + normals_offset_] = current_normals[0];
			vertex_normals[vertex_indices.y + normals_offset_] = current_normals[1];
			vertex_normals[vertex_indices.z + normals_offset_] = current_normals[2];
#endif
		}
#if USE_SHARED_MEMORY_FOR_NORMALS
		GroupMemoryBarrierWithGroupSync();
#else
		DeviceMemoryBarrierWithGroupSync();
#endif
	}


#if USE_SHARED_MEMORY_FOR_NORMALS
	for (i_vertex = g_normal_update_start_index + thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		vertex_normals[i_vertex + normals_offset_] = pack_normal_flt3_to_ui(gs_global_buffer[i_vertex].xyz);
	}
#endif

#endif //COMPUTE_NORMALS


#endif //TELEPORT_MODE
}
#else

[numthreads(THREAD_COUNT, 1, 1)]
void main_cs(uint3 thread_id : SV_GroupThreadID, uint3 group_id : SV_GroupID)
{
	int i_vertex;
#if TELEPORT_MODE
	for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		uint x = rest_positions[i_vertex * 2 + 0 + rest_positions_offset_];
		uint y = rest_positions[i_vertex * 2 + 1 + rest_positions_offset_];

		float3 pos;
		decode_position_ui2_to_flt3(x, y, POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, pos);
		encode_position_flt3_to_ui2(pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, x, y);

		previous_positions[i_vertex * 2 + 0 + positions_offset_] = x;
		previous_positions[i_vertex * 2 + 1 + positions_offset_] = y;
		current_positions[i_vertex * 2 + 0 + positions_offset_] = x;
		current_positions[i_vertex * 2 + 1 + positions_offset_] = y;
		vertex_normals[i_vertex + normals_offset_] = rest_normals[i_vertex + (rest_positions_offset_ >> 1)];
	}
#else
	int vertex_count = g_vertex_count;
#if USE_SHARED_MEMORY	
	for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		const int x_index = i_vertex * 2 + 0;
		const int y_index = i_vertex * 2 + 1;
		float3 cur_pos;
		if (g_start_with_rest_state)
		{
			uint x = rest_positions[x_index + rest_positions_offset_];
			uint y = rest_positions[y_index + rest_positions_offset_];
			decode_position_ui2_to_flt3(x, y, POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, cur_pos);
			encode_position_flt3_to_ui2(cur_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, x, y);
			previous_positions[x_index + positions_offset_] = x;
			previous_positions[y_index + positions_offset_] = y;
		}
		else
		{
			decode_position_ui2_to_flt3(current_positions[x_index + positions_offset_], current_positions[y_index + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, cur_pos);
		}
		sm_store_position(vertex_count, cur_pos, i_vertex);
	}
	if (g_start_with_rest_state)
	{
		DeviceMemoryBarrierWithGroupSync();
	}
	GroupMemoryBarrierWithGroupSync();
#else
	if (g_start_with_rest_state)
	{
		for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
		{
			const int x_index = i_vertex * 2 + 0;
			const int y_index = i_vertex * 2 + 1;
			float3 cur_pos;
			uint x = rest_positions[i_vertex * 2 + 0 + rest_positions_offset_];
			uint y = rest_positions[i_vertex * 2 + 1 + rest_positions_offset_];
			decode_position_ui2_to_flt3(x, y, POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, cur_pos);
			encode_position_flt3_to_ui2(cur_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, x, y);
			previous_positions[i_vertex * 2 + 0 + positions_offset_] = x;
			previous_positions[i_vertex * 2 + 1 + positions_offset_] = y;
			current_positions[i_vertex * 2 + 0 + positions_offset_] = x;
			current_positions[i_vertex * 2 + 1 + positions_offset_] = y;
		}
		DeviceMemoryBarrierWithGroupSync();
	}
#endif

	for (int i_iteration = 0; i_iteration < iteration_count; i_iteration++)
	{
#if 1//INTEGRATE PARTICLES
		/*
		Integrate particles and apply max distance constraints
		*/
		for (i_vertex = thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
		{
			const int x_index = i_vertex * 2 + 0;
			const int y_index = i_vertex * 2 + 1;
			float3 prev_pos;
			float3 cur_pos;
			float3 expected_pos;
#if USE_SHARED_MEMORY
			cur_pos = sm_load_position(vertex_count, i_vertex);
#else
			decode_position_ui2_to_flt3(current_positions[x_index + positions_offset_], current_positions[y_index + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, cur_pos);
#endif		
			decode_position_ui2_to_flt3(rest_positions[x_index + rest_positions_offset_], rest_positions[y_index + rest_positions_offset_],
				POSITION_COMPRESSION_MAX * REST_POS, POSITION_COMPRESSION_MIN * REST_POS, expected_pos);
			decode_position_ui2_to_flt3(previous_positions[x_index + positions_offset_], previous_positions[y_index + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, prev_pos);
#if 1
			const float3 velocity = (cur_pos - prev_pos) * g_iteration_dt;
			float3 dV = g_wind_dir - velocity;
			float3 vertex_normal = unpack_normal_ui_to_flt3(vertex_normals[i_vertex + normals_offset_]);

			dV *= saturate(abs(dot(vertex_normal, normalize(dV))) * g_wind_alpha);
			const float3 dS = (cur_pos - prev_pos) * g_damping + accel.xyz + dV * g_iteration_dt * g_iteration_dt;
#else
			const float3 dS = (cur_pos - prev_pos) * g_damping + accel.xyz;
#endif
			float3 next_position = cur_pos + dS;
			float3 prev_position = cur_pos + prev_bias.xyz;
			uint encoded_x;
			uint encoded_y;
			encode_position_flt3_to_ui2(prev_position, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
			previous_positions[x_index + positions_offset_] = encoded_x;
			previous_positions[y_index + positions_offset_] = encoded_y;

			float max_distance = max_distances[i_vertex + max_distance_offset_] * max_distance_multiplier;
			float3 to_cur = next_position - expected_pos;
			float to_cur_len = length(to_cur);
			float valid_len = clamp(to_cur_len, 0, max_distance);
			next_position = expected_pos + (to_cur / (to_cur_len + 0.00001)) * valid_len;
#if USE_SHARED_MEMORY
			sm_store_position(vertex_count, next_position, i_vertex);
#else
			encode_position_flt3_to_ui2(next_position, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
			current_positions[x_index + positions_offset_] = encoded_x;
			current_positions[y_index + positions_offset_] = encoded_y;
#endif			
		}

#if USE_SHARED_MEMORY
		GroupMemoryBarrierWithGroupSync();
#else
		DeviceMemoryBarrierWithGroupSync();
#endif

#endif

#if 1//ANCHOR CONSTRAINTS
		if (g_anchor_stiffness > 0)
		{
			for (i_vertex = thread_id.x + simulation_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
			{
				uint anchor_data = anchor_constraints[i_vertex + g_anchor_constraints_offset];
				int anchor_index = (anchor_data & 0xFFFF0000) >> 16;
				float anchor_len = (anchor_data & 0x0000FFFF) * g_anchor_scale;
#if USE_SHARED_MEMORY
				float3 vertex_pos = sm_load_position(vertex_count, i_vertex);
				const float3 anchor_pos = sm_load_position(vertex_count, anchor_index);
#else
				float3 vertex_pos;
				float3 anchor_pos;
				int x1_index = i_vertex * 2 + 0 + positions_offset_;
				int y1_index = i_vertex * 2 + 1 + positions_offset_;

				int x2_index = anchor_index * 2 + 0 + positions_offset_;
				int y2_index = anchor_index * 2 + 1 + positions_offset_;
				decode_position_ui2_to_flt3(current_positions[x1_index], current_positions[y1_index],
					POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, vertex_pos);
				decode_position_ui2_to_flt3(current_positions[x2_index], current_positions[y2_index],
					POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, anchor_pos);
#endif
				float3 delta = vertex_pos - anchor_pos;
				float delta_len = length(delta) + 0.00000001;
				if (delta_len > anchor_len)
				{
					vertex_pos = vertex_pos - (delta / delta_len) * (delta_len - anchor_len) * g_anchor_stiffness;
				}
#if USE_SHARED_MEMORY
				sm_store_position(vertex_count, vertex_pos, i_vertex);
#else
				uint encoded_x;
				uint encoded_y;
				encode_position_flt3_to_ui2(vertex_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
				current_positions[x1_index] = encoded_x;
				current_positions[y1_index] = encoded_y;
#endif
			}
#if USE_SHARED_MEMORY
			GroupMemoryBarrierWithGroupSync();
#else
			DeviceMemoryBarrierWithGroupSync();
#endif
		}
#endif

#if 1//FABRIC CONSTRAINTS
		for (int i_const_set = 0; i_const_set < constraint_set_count; i_const_set++)
		{
			const Constraint_set cur_set = constraint_sets[i_const_set + constraint_sets_offset_];
			int constraint_count = cur_set.bending_count_ + cur_set.shearing_count_ + cur_set.stretching_count_;
			solve_constraint_range2(group_id, cur_set.stretching_start_ + thread_id.x + constraints_offset_, cur_set.stretching_start_ + constraint_count + constraints_offset_,
				cur_set.stretching_start_, stretching, cur_set.bending_start_, bending, cur_set.shearing_start_, shearing);
#if USE_SHARED_MEMORY
			GroupMemoryBarrierWithGroupSync();
#else
			DeviceMemoryBarrierWithGroupSync();
#endif
		}
#endif

#if 1
		if (g_capsule_count > 0)
		{
			for (i_vertex = thread_id.x + simulation_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
			{
				float3 cur_position;
#if USE_SHARED_MEMORY
				cur_position = sm_load_position(vertex_count, i_vertex);
#else
				const int x_index = i_vertex * 2 + 0;
				const int y_index = i_vertex * 2 + 1;
				decode_position_ui2_to_flt3(current_positions[x_index + positions_offset_], current_positions[y_index + positions_offset_],
					POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, cur_position);
#endif
				for (int i_capsule = 0; i_capsule < g_capsule_count; i_capsule++)
				{
					const Capsule3 cur_capsule = capsules[i_capsule + g_capsule_offset];
					const float3 rest_p0 = cur_capsule.point0_;
					const float3 rest_p1 = cur_capsule.point1_;
					cur_position = ensure_point_is_outside_of_cone(rest_p0, cur_capsule.radius0_, rest_p1, cur_capsule.radius1_, cur_position);
				}
#if USE_SHARED_MEMORY
				sm_store_position(vertex_count, cur_position, i_vertex);
#else
				uint encoded_x;
				uint encoded_y;
				encode_position_flt3_to_ui2(cur_position, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
				current_positions[x_index + positions_offset_] = encoded_x;
				current_positions[y_index + positions_offset_] = encoded_y;
#endif			
			}
#if USE_SHARED_MEMORY
			GroupMemoryBarrierWithGroupSync();
#else
			DeviceMemoryBarrierWithGroupSync();
#endif

#if DUMMY_COLLISION_PARTICLES
			for (int i_set = 0; i_set < dummy_particle_set_count; i_set++)
			{
				const Dummy_particle_set cur_set = dummy_particle_sets[i_set + dummy_particle_sets_offset_];
				int index_begin = cur_set.element_start_ + thread_id.x + dummy_particle_indices_offset_;
				int index_end = cur_set.element_start_ + cur_set.element_count_ + dummy_particle_indices_offset_;

				const float3 weights[4] = {
					{ 4.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0 },
					{ 4.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0 },
					{ 4.0 / 6.0, 1.0 / 6.0, 1.0 / 6.0 },
					{ 1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0 }
				};

				const float rcp_weights_sum_sq[] = {
					1.0 / dot(weights[0], weights[0]),
					1.0 / dot(weights[1], weights[1]),
					1.0 / dot(weights[2], weights[2]),
					1.0 / dot(weights[3], weights[3]),
				};

				for (int i_vp = index_begin; i_vp < index_end; i_vp += THREAD_COUNT)
				{
					uint3 vertex_indices = virtual_particle_indices[i_vp].xyz;
					uint3 swizzled_indices[4] = { vertex_indices.xyz, vertex_indices.zxy, vertex_indices.yzx, vertex_indices.xyz };
					for (uint i_swiz = 0; i_swiz < 4; i_swiz++)
					{
						uint2 first_indices = swizzled_indices[i_swiz].x * 2 + float2(0, 1);
						uint2 second_indices = swizzled_indices[i_swiz].y * 2 + float2(0, 1);
						uint2 third_indices = swizzled_indices[i_swiz].z * 2 + float2(0, 1);
						float3 current_pos[3];
#if USE_SHARED_MEMORY
						current_pos[0] = sm_load_position(vertex_count, swizzled_indices[i_swiz].x);
						current_pos[1] = sm_load_position(vertex_count, swizzled_indices[i_swiz].y);
						current_pos[2] = sm_load_position(vertex_count, swizzled_indices[i_swiz].z);
#else
						decode_position_ui2_to_flt3(current_positions[first_indices[0]], current_positions[first_indices[1]],
							POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[0]);
						decode_position_ui2_to_flt3(current_positions[second_indices[0]], current_positions[second_indices[1]],
							POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[1]);
						decode_position_ui2_to_flt3(current_positions[third_indices[0]], current_positions[third_indices[1]],
							POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[2]);
#endif					
						float3 virtual_position = current_pos[0] * weights[i_swiz].x + current_pos[1] * weights[i_swiz].y + current_pos[2] * weights[i_swiz].z;
						float3 ideal_position = virtual_position;
						for (int i_capsule = 0; i_capsule < g_capsule_count; i_capsule++)
						{
							const Capsule3 cur_capsule = capsules[i_capsule + g_capsule_offset];
							ideal_position = ensure_point_is_outside_of_cone(cur_capsule.point0_, cur_capsule.radius0_, cur_capsule.point1_, cur_capsule.radius1_, ideal_position);
						}

						float3 d_pos = ideal_position - virtual_position;
						uint encoded_x;
						uint encoded_y;

						current_pos[0] += d_pos * weights[i_swiz].x * rcp_weights_sum_sq[i_swiz];
						current_pos[1] += d_pos * weights[i_swiz].y * rcp_weights_sum_sq[i_swiz];
						current_pos[2] += d_pos * weights[i_swiz].z * rcp_weights_sum_sq[i_swiz];
#if USE_SHARED_MEMORY
						sm_store_position(vertex_count, current_pos[0], swizzled_indices[i_swiz].x);
						sm_store_position(vertex_count, current_pos[1], swizzled_indices[i_swiz].y);
						sm_store_position(vertex_count, current_pos[2], swizzled_indices[i_swiz].z);
#else
						encode_position_flt3_to_ui2(current_pos[0], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
						current_positions[first_indices[0]] = encoded_x;
						current_positions[first_indices[1]] = encoded_y;

						encode_position_flt3_to_ui2(current_pos[1], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
						current_positions[second_indices[0]] = encoded_x;
						current_positions[second_indices[1]] = encoded_y;

						encode_position_flt3_to_ui2(current_pos[2], POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
						current_positions[third_indices[0]] = encoded_x;
						current_positions[third_indices[1]] = encoded_y;
#endif
					}
				}
#if USE_SHARED_MEMORY
				GroupMemoryBarrierWithGroupSync();
#else
				DeviceMemoryBarrierWithGroupSync();
#endif
			}
#endif
		}
#endif
	}

#if USE_SHARED_MEMORY
	const int copy_start_index = g_start_with_rest_state ? thread_id.x : thread_id.x + simulation_start_index;
	for (i_vertex = copy_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		const int x_index = i_vertex * 2 + 0 + positions_offset_;
		const int y_index = i_vertex * 2 + 1 + positions_offset_;
#if PACKED_GS_POSITIONS
		current_positions[x_index] = gs_positions[i_vertex];
		current_positions[y_index] = gs_positions[i_vertex + vertex_count];
#else		
		float3 cur_pos = sm_load_position(vertex_count, i_vertex);
		uint encoded_x;
		uint encoded_y;
		encode_position_flt3_to_ui2(cur_pos, POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, encoded_x, encoded_y);
		current_positions[x_index] = encoded_x;
		current_positions[y_index] = encoded_y;
#endif		
	}
#endif

#if 1//COMPUTE_NORMALS
	//Set constant normals
	if (g_start_with_rest_state)
	{
		for (i_vertex = thread_id.x; i_vertex < g_normal_update_start_index; i_vertex += THREAD_COUNT)
		{
			vertex_normals[i_vertex + normals_offset_] = rest_normals[i_vertex + (rest_positions_offset_ >> 1)];
		}
	}

	//Reset simulated normals
	for (i_vertex = thread_id.x + g_normal_update_start_index; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
#if USE_SHARED_MEMORY_FOR_NORMALS
		gs_global_buffer[i_vertex].xyz = float3(0, 0, 0);
#else
		vertex_normals[i_vertex + normals_offset_] = pack_normal_flt3_to_ui(float3(0, 0, 0));
#endif
	}
#if USE_SHARED_MEMORY_FOR_NORMALS
	GroupMemoryBarrierWithGroupSync();
#else
	DeviceMemoryBarrierWithGroupSync();
#endif

	//Compute weighted normals
	for (int i_set = 0; i_set < dummy_particle_set_count; i_set++)
	{
		const Dummy_particle_set cur_set = dummy_particle_sets[i_set + dummy_particle_sets_offset_];
		int index_begin = cur_set.element_start_ + thread_id.x + dummy_particle_indices_offset_;
		int index_end = cur_set.element_start_ + cur_set.element_count_ + dummy_particle_indices_offset_;

		for (int i_vp = index_begin; i_vp < index_end; i_vp += THREAD_COUNT)
		{
			uint3 vertex_indices = virtual_particle_indices[i_vp].xyz;
			float3 current_pos[3];
#if USE_SHARED_MEMORY
			current_pos[0] = sm_load_position(vertex_count, vertex_indices.x);
			current_pos[1] = sm_load_position(vertex_count, vertex_indices.y);
			current_pos[2] = sm_load_position(vertex_count, vertex_indices.z);
#else
			decode_position_ui2_to_flt3(current_positions[vertex_indices.x * 2 + 0 + positions_offset_], current_positions[vertex_indices.x * 2 + 1 + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[0]);
			decode_position_ui2_to_flt3(current_positions[vertex_indices.y * 2 + 0 + positions_offset_], current_positions[vertex_indices.y * 2 + 1 + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[1]);
			decode_position_ui2_to_flt3(current_positions[vertex_indices.z * 2 + 0 + positions_offset_], current_positions[vertex_indices.z * 2 + 1 + positions_offset_],
				POSITION_COMPRESSION_MAX, POSITION_COMPRESSION_MIN, current_pos[2]);
#endif 			
			float3 decoded_normals[3];
			uint current_normals[3];
			float vertex_areas[3];
#if USE_SHARED_MEMORY_FOR_NORMALS
			decoded_normals[0] = gs_global_buffer[vertex_indices.x].xyz;
			decoded_normals[1] = gs_global_buffer[vertex_indices.y].xyz;
			decoded_normals[2] = gs_global_buffer[vertex_indices.z].xyz;
#else
			current_normals[0] = vertex_normals[vertex_indices.x + normals_offset_];
			current_normals[1] = vertex_normals[vertex_indices.y + normals_offset_];
			current_normals[2] = vertex_normals[vertex_indices.z + normals_offset_];
			decoded_normals[0] = unpack_normal_ui_to_flt3(current_normals[0]);
			decoded_normals[1] = unpack_normal_ui_to_flt3(current_normals[1]);
			decoded_normals[2] = unpack_normal_ui_to_flt3(current_normals[2]);
#endif
			vertex_areas[0] = vertex_area_sums[vertex_indices.x + vertex_area_sums_offset_];
			vertex_areas[1] = vertex_area_sums[vertex_indices.y + vertex_area_sums_offset_];
			vertex_areas[2] = vertex_area_sums[vertex_indices.z + vertex_area_sums_offset_];
			float3 face_normal = cross(current_pos[1] - current_pos[0], current_pos[2] - current_pos[0]);
			float face_area = length(face_normal) * 0.5;
			face_normal = normalize(face_normal);
			decoded_normals[0] += (face_normal * (face_area * vertex_areas[0]));
			decoded_normals[1] += (face_normal * (face_area * vertex_areas[1]));
			decoded_normals[2] += (face_normal * (face_area * vertex_areas[2]));
			//decoded_normals[0] = decoded_normals[1] = decoded_normals[2] = normalize(face_normal);
#if USE_SHARED_MEMORY_FOR_NORMALS
			gs_global_buffer[vertex_indices.x].xyz = decoded_normals[0];
			gs_global_buffer[vertex_indices.y].xyz = decoded_normals[1];
			gs_global_buffer[vertex_indices.z].xyz = decoded_normals[2];
#else
			current_normals[0] = pack_normal_flt3_to_ui(decoded_normals[0]);
			current_normals[1] = pack_normal_flt3_to_ui(decoded_normals[1]);
			current_normals[2] = pack_normal_flt3_to_ui(decoded_normals[2]);
			vertex_normals[vertex_indices.x + normals_offset_] = current_normals[0];
			vertex_normals[vertex_indices.y + normals_offset_] = current_normals[1];
			vertex_normals[vertex_indices.z + normals_offset_] = current_normals[2];
#endif
		}
#if USE_SHARED_MEMORY_FOR_NORMALS
		GroupMemoryBarrierWithGroupSync();
#else
		DeviceMemoryBarrierWithGroupSync();
#endif
	}


#if USE_SHARED_MEMORY_FOR_NORMALS
	for (i_vertex = g_normal_update_start_index + thread_id.x; i_vertex < g_vertex_count; i_vertex += THREAD_COUNT)
	{
		vertex_normals[i_vertex + normals_offset_] = pack_normal_flt3_to_ui(gs_global_buffer[i_vertex].xyz);
	}
#endif

#endif //COMPUTE_NORMALS

#endif //TELEPORT_MODE
}
#endif //SKINNED_MESH
