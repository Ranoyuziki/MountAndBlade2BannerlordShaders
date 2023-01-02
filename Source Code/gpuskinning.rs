
#include "definitions.rsh"

#include "math_conversions.rsh"
#include "definitions_shader_resource_indices.rsh"
#include "definitions_samplers.rsh"

#define GPU_SKINNING_MAX_BATCH_SIZE 512
#define GROUP_SIZE 256
//#define INDIRECT_SKINNING
//#define IDENTITY_SKINNING

struct Skinning_info
{
	int vertex_count_;
	int bone_frame_buffer_offset_;
	int position_offset_;
	int bone_index_offset_;

	int uv_offset_;
	int tangent_offset_;
	int morph_delta_offset_;
	int morph_normal_offset_;

	float2 uv_scale_;
	float2 uv_bias_;

	int bone_weights_offset_;
	int normals_offset_;
	int skinned_position_offset_;
	uint bone_count_;

	int num_vertex_per_key_;
	int cur_num_morph_targets_;
	int morph_param_offset_;
	int morph_mapping_offset_;
};

#ifdef USE_DIRECTX12

#define g_position (ByteAddressBuffer_table[indices.t_custom_0])
#define g_normal (ByteAddressBuffer_table[indices.t_custom_1])
#define g_bone_weight (ByteAddressBuffer_table[indices.t_custom_2])
#define g_bone_index (ByteAddressBuffer_table[indices.t_custom_3])
#define g_uv (ByteAddressBuffer_table[indices.t_custom_4])
#define gpu_morph_mapping_buffer (Buffer_uint_table[indices.t_custom_5])
#define gpu_morph_key_buffer (Buffer_float2_table[indices.t_custom_6])
#if TANGENT_SKINNING
#define g_tangent (ByteAddressBuffer_table[indices.t_custom_7])
#endif
#define skinning_displacement_texture (Texture2D_float4_table[indices.t_custom_8])
#define gpu_morph_delta_buffer (Buffer_float_table[indices.t_custom_9])
#define gpu_morph_normal_buffer (Buffer_float_table[indices.t_custom_10])
#define g_out_position (RWBuffer_float_table[indices.u_custom_0])
#define g_out_normal (RWBuffer_uint_table[indices.u_custom_1])
#define g_out_tangent (RWBuffer_uint_table[indices.u_custom_2])

#else

ByteAddressBuffer g_position : register(t_custom_0);
ByteAddressBuffer g_normal : register(t_custom_1);
ByteAddressBuffer g_bone_weight : register(t_custom_2);
ByteAddressBuffer g_bone_index : register(t_custom_3);
ByteAddressBuffer g_uv : register(t_custom_4);
Buffer<uint> gpu_morph_mapping_buffer						: register(t_custom_5);
Buffer<float2> gpu_morph_key_buffer					: register(t_custom_6);
#if TANGENT_SKINNING
ByteAddressBuffer g_tangent : register(t_custom_7);
#endif
Texture2D<float4> skinning_displacement_texture		: register(t_custom_8);
Buffer<float> gpu_morph_delta_buffer				: register(t_custom_9);
Buffer<float> gpu_morph_normal_buffer				: register(t_custom_10);
RWBuffer<float> g_out_position						: register(u_custom_0);
RWBuffer<uint> g_out_normal							: register(u_custom_1);
RWBuffer<uint> g_out_tangent						: register(u_custom_2);

#endif

cbuffer skinning_info : register(b_custom_0)
{
	Skinning_info g_params[GPU_SKINNING_MAX_BATCH_SIZE];
};

groupshared float4x3 gs_bone_frames[64];

[numthreads(GROUP_SIZE, 1, 1)]
void main_cs(uint3 grid : SV_GroupID, uint3 gtid : SV_GroupThreadID)
{
	const Skinning_info local_info = g_params[grid.x];
#if IDENTITY_SKINNING
	for (int i_vertex = gtid.x; i_vertex < local_info.vertex_count_; i_vertex += GROUP_SIZE)
	{
		uint pos_write_index = (local_info.skinned_position_offset_ + i_vertex) * 3;
		uint normal_write_index = local_info.skinned_position_offset_ + i_vertex;
#if PRECISE_SKINNING
		float3 local_position = asfloat(g_position.Load3((local_info.position_offset_ + i_vertex) * 12));
#else
		float3 local_position = unpack_position_ui2_to_float4(g_position.Load2((local_info.position_offset_ + i_vertex) * 8)).xyz;
#endif
		g_out_position[pos_write_index + 0] = local_position.x;
		g_out_position[pos_write_index + 1] = local_position.y;
		g_out_position[pos_write_index + 2] = local_position.z;
		g_out_normal[normal_write_index] = g_normal.Load((local_info.normals_offset_ + i_vertex) * 4);
#if TANGENT_SKINNING
		g_out_tangent[normal_write_index] = g_tangent.Load((local_info.tangent_offset_ + i_vertex) * 4);
#endif
	}
#else
	if (gtid.x < local_info.bone_count_)
	{
#if INDIRECT_SKINNING
		int bone_buffer_offset = global_skinning_indirection_buffer[local_info.bone_frame_buffer_offset_ + gtid.x] * 3;
#else
		int bone_buffer_offset = (local_info.bone_frame_buffer_offset_ + gtid.x) * 3;
#endif
		float4x4 unpacked_mat;
		unpacked_mat[0] = global_skinning_buffer[bone_buffer_offset + 0];
		unpacked_mat[1] = global_skinning_buffer[bone_buffer_offset + 1];
		unpacked_mat[2] = global_skinning_buffer[bone_buffer_offset + 2];
		unpacked_mat[3] = float4(unpacked_mat[0].w, unpacked_mat[1].w, unpacked_mat[2].w, 1.0);
		unpacked_mat[0].w = 0;
		unpacked_mat[1].w = 0;
		unpacked_mat[2].w = 0;
		gs_bone_frames[gtid.x] = unpack_skinning_matrix(
			global_skinning_buffer[bone_buffer_offset + 0],
			global_skinning_buffer[bone_buffer_offset + 1],
			global_skinning_buffer[bone_buffer_offset + 2]
		);
	}

	GroupMemoryBarrierWithGroupSync();

	for (int i_vertex = gtid.x; i_vertex < local_info.vertex_count_; i_vertex += GROUP_SIZE)
	{
#if PRECISE_SKINNING
		float3 position = asfloat(g_position.Load3((local_info.position_offset_ + i_vertex) * 12));
#else
		float3 position = unpack_position_ui2_to_float4(g_position.Load2((local_info.position_offset_ + i_vertex) * 8)).xyz;
#endif

		float4 normal = float4(unpack_normal_ui_to_flt3(g_normal.Load((local_info.normals_offset_ + i_vertex) * 4)), 0);
#if MORPHED_SKINNING
		int num_vertex_per_key = local_info.num_vertex_per_key_;
		int cur_num_morph_targets = local_info.cur_num_morph_targets_;
		int morph_param_offset = local_info.morph_param_offset_;
		int morph_mapping_offset = local_info.morph_mapping_offset_;

#if MORPHED_NORMALS
		float4 blended_normal = 0;
#endif

		[loop]
		for (int i_mtarget = 0; i_mtarget < cur_num_morph_targets; i_mtarget++)
		{
			float2 morph_key = gpu_morph_key_buffer[morph_param_offset + i_mtarget];
			const int cur_key = morph_key.x;
			const int mapping_buffer_index = morph_mapping_offset + i_vertex;
			uint vertex_index = gpu_morph_mapping_buffer[mapping_buffer_index];
			uint delta_index = num_vertex_per_key * cur_key * 3 + vertex_index * 3 + local_info.morph_delta_offset_;
				position.x += gpu_morph_delta_buffer[delta_index + 0] * morph_key.y;
				position.y += gpu_morph_delta_buffer[delta_index + 1] * morph_key.y;
				position.z += gpu_morph_delta_buffer[delta_index + 2] * morph_key.y;
#if MORPHED_NORMALS
			uint normal_index = local_info.morph_normal_offset_ + local_info.vertex_count_ * 3 * cur_key + i_vertex * 3;

			blended_normal.xyz += float3(gpu_morph_normal_buffer[normal_index + 0], gpu_morph_normal_buffer[normal_index + 1], gpu_morph_normal_buffer[normal_index + 2]);
			blended_normal.w += morph_key.y;
#endif
		}

#if MORPHED_NORMALS
		blended_normal.xyz = normalize(blended_normal.xyz);
		float weight = blended_normal.w / (float)cur_num_morph_targets;
		normal.xyz = normalize(normal.xyz * saturate(1.0 - weight) + blended_normal.xyz * weight);
#endif
#endif
		uint packed_bone_indices = g_bone_index.Load((local_info.bone_index_offset_ + i_vertex) * 4);
		uint4 bone_indices;
		bone_indices.x = (packed_bone_indices & 0x000000FF) >> 0;
		bone_indices.y = (packed_bone_indices & 0x0000FF00) >> 8;
		bone_indices.z = (packed_bone_indices & 0x00FF0000) >> 16;
		bone_indices.w = (packed_bone_indices & 0xFF000000) >> 24;
		uint packed_bone_weights = g_bone_weight.Load((local_info.bone_weights_offset_ + i_vertex) * 4);
		float4 bone_weights;
		bone_weights.x = ((packed_bone_weights & 0x000000FF) >> 0) / 255.0;
		bone_weights.y = ((packed_bone_weights & 0x0000FF00) >> 8) / 255.0;
		bone_weights.z = ((packed_bone_weights & 0x00FF0000) >> 16) / 255.0;
		bone_weights.w = 1.0 - bone_weights.x - bone_weights.y - bone_weights.z;

#if USE_POSITION_DISPLACEMENT
		float2 uv = asfloat(g_uv.Load2((local_info.uv_offset_ + i_vertex) * 8)) * local_info.uv_scale_ + local_info.uv_bias_;
		float disp = skinning_displacement_texture.SampleLevel(linear_sampler, uv, 0).a;
		position.xyz += normal * disp;
#endif
		float3 pos_result;
		pos_result = (mul(position.xyz, (float3x3)gs_bone_frames[bone_indices.x]).xyz + gs_bone_frames[bone_indices.x][3]) * bone_weights.x;
		pos_result += (mul(position.xyz, (float3x3)gs_bone_frames[bone_indices.y]).xyz + gs_bone_frames[bone_indices.y][3]) * bone_weights.y;
		pos_result += (mul(position.xyz, (float3x3)gs_bone_frames[bone_indices.z]).xyz + gs_bone_frames[bone_indices.z][3]) * bone_weights.z;
		pos_result += (mul(position.xyz, (float3x3)gs_bone_frames[bone_indices.w]).xyz + gs_bone_frames[bone_indices.w][3]) * bone_weights.w;

		float3 normal_result;
		normal_result = mul(normal.xyz, (float3x3)gs_bone_frames[bone_indices.x]).xyz * bone_weights.x;
		normal_result += mul(normal.xyz, (float3x3)gs_bone_frames[bone_indices.y]).xyz * bone_weights.y;
		normal_result += mul(normal.xyz, (float3x3)gs_bone_frames[bone_indices.z]).xyz * bone_weights.z;
		normal_result += mul(normal.xyz, (float3x3)gs_bone_frames[bone_indices.w]).xyz * bone_weights.w;

#if TANGENT_SKINNING
		uint packed_tangent = g_tangent.Load((local_info.tangent_offset_ + i_vertex) * 4);
		float3 tangent = normalize(unpack_tangent_ui_to_flt3(packed_tangent).xyz);
		float3 tangent_result;
		tangent_result = mul(tangent, (float3x3)gs_bone_frames[bone_indices.x]).xyz * bone_weights.x;
		tangent_result += mul(tangent, (float3x3)gs_bone_frames[bone_indices.y]).xyz * bone_weights.y;
		tangent_result += mul(tangent, (float3x3)gs_bone_frames[bone_indices.z]).xyz * bone_weights.z;
		tangent_result += mul(tangent, (float3x3)gs_bone_frames[bone_indices.w]).xyz * bone_weights.w;
#endif

		//uint2 packed_pos = pack_position_float4_to_ui2(float4(pos_result, 1));
		uint pos_write_index = (local_info.skinned_position_offset_ + i_vertex) * 3;
		g_out_position[pos_write_index + 0] = pos_result.x;
		g_out_position[pos_write_index + 1] = pos_result.y;
		g_out_position[pos_write_index + 2] = pos_result.z;

		uint normal_write_index = local_info.skinned_position_offset_ + i_vertex;
		g_out_normal[normal_write_index] = pack_normal_flt3_to_ui(normalize(normal_result));
#if TANGENT_SKINNING
		g_out_tangent[normal_write_index] = pack_tangent_flt3_to_ui(normalize(tangent_result), packed_tangent & 0x80000000);
#endif
	}
#endif
}
