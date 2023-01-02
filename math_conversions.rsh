#ifndef MATH_CONVERSIONS_RSH
#define MATH_CONVERSIONS_RSH

/*
ONLY INCLUDES CONTEXT UNAWARE FUNCTIONS INPUTING AND OUTPUTTING PRIMITIVE TYPES.
PLEASE DO NOT INCLUDE VERTEX & PIXEL SHADER, TESSELLATION, DEPTH ONLY PASS DEPENDENDENT IFDEFS ETC.
*/


float3x3 to_float3x3(float4x4 mat)
{
	return (float3x3)mat;
}

float4 get_column(float4x4 mat, int i)
{
	return float4(mat[0][i], mat[1][i], mat[2][i], mat[3][i]);
}


float3 get_column(float3x3 mat, int i)
{
	return float3(mat[0][i], mat[1][i], mat[2][i]);
}

float4 unpack_position_ui2_to_float4(uint2 p)
{
	float4 unpacked_pos;
	unpacked_pos.x = f16tof32(p.x & 0x0000FFFF);
	unpacked_pos.y = f16tof32((p.x & 0xFFFF0000) >> 16);
	unpacked_pos.z = f16tof32(p.y & 0x0000FFFF);
	unpacked_pos.w = f16tof32((p.y & 0xFFFF0000) >> 16);
	return unpacked_pos;
}

uint2 pack_position_float4_to_ui2(float4 u)
{
	uint2 packed_pos;
	uint4 comps = f32tof16(u);
	packed_pos.x = 0;
	packed_pos.x |= comps.x & 0x0000FFFF;
	packed_pos.x |= (comps.y & 0x0000FFFF) << 16;
	packed_pos.y = 0;
	packed_pos.y |= comps.z & 0x0000FFFF;
	packed_pos.y |= (comps.w & 0x0000FFFF) << 16;
	return packed_pos;
}

uint pack_normal_flt3_to_ui(float3 normal)
{
	uint encoded_normal;
	normal = saturate(normal * 0.5 + 0.5);
	encoded_normal =
		((((uint)(normal.x * 0x7FF)) << 21) & 0xFFE00000) |
		((((uint)(normal.y * 0x7FF)) << 10) & 0x001FFC00) |
		(((uint)(normal.z * 0x3FF)) & 0x000003FF);
	return encoded_normal;
}

uint pack_tangent_flt3_to_ui(float3 tangent, uint binormal_bit)
{
	uint encoded_tangent;
	tangent = saturate(tangent * 0.5 + 0.5);
	encoded_tangent =
		binormal_bit |
		((((uint)(tangent.x * 0x3FF)) << 21) & 0x7FE00000) |
		((((uint)(tangent.y * 0x7FF)) << 10) & 0x001FFC00) |
		(((uint)(tangent.z * 0x3FF)) & 0x000003FF);
	return encoded_tangent;
}

uint pack_unorm_float4_to_uint(float4 value)
{
	int4 packed_value = int4(round(value * 255.0)) & 0xFF;
	return uint(packed_value.x | (packed_value.y << 8) | (packed_value.z << 16) | (packed_value.w << 24));
}

float4 unpack_unorm_float4_from_uint(uint value)
{
	int4 packed_value = (int4(value << 24, value << 16, value << 8, value) >> 24) & 0xFF;
	return saturate(float4(packed_value) / 255.0);
}

float3 unpack_normal_ui_to_flt3(uint normal)
{
	float3 decoded_normal;
	const float rcp_max_10 = 1.0 / float(0x3FF);
	const float rcp_max_11 = 1.0 / float(0x7FF);
	decoded_normal.x = ((normal & 0xFFE00000) >> 21) * rcp_max_11;
	decoded_normal.y = ((normal & 0x001FFC00) >> 10) * rcp_max_11;
	decoded_normal.z = (normal & 0x000003FF) * rcp_max_10;
	decoded_normal = decoded_normal * 2.0 - 1.0;
	return decoded_normal;
}

float4 unpack_tangent_ui_to_flt3(uint packed_tangent)
{
	float4 decoded_tangent;
	const float rcp_max_10 = 1.0 / float(0x3FF);
	const float rcp_max_11 = 1.0 / float(0x7FF);
	decoded_tangent.x = ((packed_tangent & 0x7FE00000) >> 21) * rcp_max_10;
	decoded_tangent.y = ((packed_tangent & 0x001FFC00) >> 10) * rcp_max_11;
	decoded_tangent.z = (packed_tangent & 0x000003FF) * rcp_max_10;
	decoded_tangent.xyz = decoded_tangent.xyz * 2.0 - 1.0;
	decoded_tangent.w = packed_tangent & 0x80000000 ? -1.0 : 1.0;
	return decoded_tangent;
}

float4x3 unpack_skinning_matrix(const float4 row0, const float4 row1, const float4 row2)
{
	float4x3 unpacked_mat;
	unpacked_mat[0] = row0.xyz;
	unpacked_mat[1] = row1.xyz;
	unpacked_mat[2] = row2.xyz;
	unpacked_mat[3] = float3(row0.w, row1.w, row2.w);
	return unpacked_mat;
}


float4x4 unpack_skinning_matrix_4x4(const float4 row0, const float4 row1, const float4 row2)
{
	float4x4 unpacked_mat;
	unpacked_mat[0] = row0;
	unpacked_mat[1] = row1;
	unpacked_mat[2] = row2;
	unpacked_mat[3] = float4(unpacked_mat[0].w, unpacked_mat[1].w, unpacked_mat[2].w, 1.0);
	unpacked_mat[0].w = 0;
	unpacked_mat[1].w = 0;
	unpacked_mat[2].w = 0;
	return unpacked_mat;
}

float3 quat_to_mat_xAxis(float4 quat)
{
	return float3(2.0f * (quat.x*quat.z + quat.w * quat.y), 2.0f * (quat.y*quat.z - quat.w * quat.x), 1.0f - 2.0f * (quat.x*quat.x + quat.y * quat.y));
}

float3 quat_to_mat_yAxis(float4 quat)
{
	return float3(2.0f * (quat.x*quat.y - quat.z * quat.w), 1.0f - 2.0f * (quat.x*quat.x + quat.z * quat.z), 2.0f * (quat.y*quat.z + quat.x * quat.w));
}

float3 quat_to_mat_zAxis(float4 quat)
{
	return float3(1.0f - 2.0f * (quat.y*quat.y + quat.z * quat.z), 2.0f * (quat.x*quat.y + quat.w * quat.z), 2.0f * (quat.x*quat.z - quat.w * quat.y));
}

#endif
