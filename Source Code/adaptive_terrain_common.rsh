#ifndef RGL_ADAPTIVE_TERRAIN_UTILS_RSH_
#define RGL_ADAPTIVE_TERRAIN_UTILS_RSH_

#include "../shader_configuration.h"

#ifdef USE_GNM
#include "hlsl_to_pssl.rsh"
#endif
#include "definitions.rsh"


#ifdef USE_DIRECTX12
//#define sector_data_texture (Texture2D_uint2_table[indices.t_custom_3])
#define sector_height_texture (Texture2D_float_table[indices.t_custom_4])
#else
//Texture2D<uint2> sector_data_texture : register(t_custom_3);
Texture2D<float> sector_height_texture : register(t_custom_4);
#endif


static const float4 adaptive_terrain_vertices[] =
{
	float4(0.0f, 0.0f, 0.0f, 1.0f),
	float4(1.0f, 0.0f, 0.0f, 1.0f),
	float4(1.0f, 1.0f, 0.0f, 1.0f),
	float4(0.0f, 1.0f, 0.0f, 1.0f),
};

static const uint adaptive_terrain_indices[] = { 0, 1, 3, 2, 3, 1 };

struct AdaptiveTerrainUniforms 
{
	float4x4 model;
	float4x4 main_mvp;
	float4x4 shadow_mvp0;
	float4x4 shadow_mvp1;
	float4x4 shadow_mvp2;
	float4x4 shadow_mvp3;

	uint node_dims_x;
	float node_size;
	float heightmap_scale;
	float lod_factor;

	float debug_freeze;
	uint max_subd_level;
	uint index_offset;
	float planar_scale;

	float high_quality;
	float detail_uv_scale;
	float _pad_0;
	float _pad_1;

	float3 camera_pos;
	float _pad_2;

	GraniteTilesetConstantBuffer tileset_data;
	GraniteStreamingTextureConstantBuffer tileset_texture_data;
};

cbuffer AdaptiveTerrainUniformBuffer_t : register(b_custom_0)
{
	AdaptiveTerrainUniforms adaptive_terrain;
};


float3 get_matrix_row(float3x3 mat, int i)
{
	return mat[i];
}

float4 get_matrix_row(float3x4 mat, int i)
{
	return mat[i];
}

float get_dmap(float2 uv)
{
	uv.y = 1 - uv.y;
	return sector_height_texture.SampleLevel(linear_clamp_sampler, uv, 0).r * adaptive_terrain.heightmap_scale;
	//uint2 sector_data = sector_data_texture.Load(uint3(world_position.xy / adaptive_terrain.sector_size, 0)); 
	//float scale = 1 << sector_data.y;
	//float2 height_uv = frac((world_position.xy / scale) / adaptive_terrain.sector_size);
	//return sector_height_texture.SampleLevel(linear_clamp_sampler, float3(height_uv, sector_data.x), 0).r * adaptive_terrain.heightmap_scale;
}

float distance_to_lod(float z, float lod_factor)
{
	// Note that we multiply the result by two because the triangles
	// edge lengths decreases by half every two subdivision steps.
	return -log2(clamp(z * lod_factor, 0.0f, 1.0f));
}

float compute_lod(float3 v1, float3 v2)
{
	v1 = mul(adaptive_terrain.model, float4(v1.xyz, 1)).xyz;
	v2 = mul(adaptive_terrain.model, float4(v2.xyz, 1)).xyz;
	float3 c = (v1 + v2) / 2.0f;
	float3 camera_pos = adaptive_terrain.camera_pos;
	float z = distance(camera_pos, c);
	return distance_to_lod(z / adaptive_terrain.planar_scale, adaptive_terrain.lod_factor);
}

float compute_lod(in float4 v[3])
{
	return clamp(compute_lod(v[1].xyz, v[2].xyz), 0, adaptive_terrain.max_subd_level);
}

float compute_lod(in float3 v[3])
{
	return clamp(compute_lod(v[1].xyz, v[2].xyz), 0, adaptive_terrain.max_subd_level);
}

uint parent_key(in uint key)
{
	return (key >> 1u);
}

void children_keys(in uint key, out uint children[2])
{
	children[0] = (key << 1u) | 0u;
	children[1] = (key << 1u) | 1u;
}

bool is_root_key(in uint key)
{
	return (key == 1u);
}

bool is_leaf_key(in uint key)
{
	return firstbithigh(key) >= 31;
}

bool is_child_zero_key(in uint key)
{
	return ((key & 1u) == 0u);
}

#if SUBD_TERRAIN_INIT || SUBD_TERRAIN_LOD
void write_key(uint primID, uint key)
{
	uint idx = 0;
	InterlockedAdd(counter_buffer_out[0], 2, idx);
	subd_buffer_out[idx] = primID;
	subd_buffer_out[idx + 1] = key;
}

void update_subd_buffer(uint prim_id, uint key, uint target_lod, uint parent_lod, bool is_visible)
{
	uint keyLod = firstbithigh(key);
	if (keyLod < target_lod && !is_leaf_key(key) && is_visible)
	{
		uint children[2]; 
		children_keys(key, children);
		write_key(prim_id, children[0]);
		write_key(prim_id, children[1]);
	}
	else if (keyLod < (parent_lod + 1) && is_visible)
	{
		write_key(prim_id, key);
	}
	else
	{
		if (is_root_key(key))
		{
			write_key(prim_id, key);
		}
		else if (is_child_zero_key(key))
		{
			write_key(prim_id, parent_key(key));
		}
	}
}

void update_subd_buffer(uint prim_id, uint key, uint target_lod, uint parent_lod)
{
	update_subd_buffer(prim_id, key, target_lod, parent_lod, true);
}
#endif

float3x4 mtxFromRows(float4 a, float4 b, float4 c)
{
	return float3x4(a, b, c);
}

float3x3 mtxFromRows(float3 a, float3 b, float3 c)
{
	return float3x3(a, b, c);
}

// get xform from bit value
float3x3 bit_to_transform(in uint bit)
{
	float b = float(bit);
	float c = 1.0f - b;

	float3 c1 = float3(0.0f, 0.5, 0.5);
	float3 c2 = float3(c, b, 0.0f);
	float3 c3 = float3(b, 0.0f, c);

	return mtxFromRows(c1, c2, c3);
}


// get xform from key
float3x3 key_to_transform(in uint key)
{
	float3 c1 = float3(1.0f, 0.0f, 0.0f);
	float3 c2 = float3(0.0f, 1.0f, 0.0f);
	float3 c3 = float3(0.0f, 0.0f, 1.0f);

	float3x3 xf = mtxFromRows(c1, c2, c3);

	while (key > 1u) 
	{
		xf = mul(xf, bit_to_transform(key & 1u));
		key = key >> 1u;
	}

	return xf;
}

// get xform from key as well as xform from parent key
float3x3 key_to_transform(in uint key, out float3x3 xfp)
{
	xfp = key_to_transform(parent_key(key));
	return key_to_transform(key);
}

// subdivision routine (vertex position only)
void subd(in uint key, in float4 v_in[3], out float4 v_out[3])
{
	float3x3 xf = key_to_transform(key);

	float3x4 m = mtxFromRows(v_in[0], v_in[1], v_in[2]);
	float3x4 v = mul(xf, m);

	v_out[0] = get_matrix_row(v, 0);
	v_out[1] = get_matrix_row(v, 1);
	v_out[2] = get_matrix_row(v, 2);
}

// subdivision routine (vertex position only)
// also computes parent position
void subd(in uint key, in float4 v_in[3], out float4 v_out[3], out float4 v_out_p[3])
{
	float3x3 xfp; 
	float3x3 xf = key_to_transform(key, xfp);

	float3x4 m = mtxFromRows(v_in[0], v_in[1], v_in[2]);

	float3x4 v = mul(xf, m);
	float3x4 vp = mul(xfp, m);

	v_out[0] = get_matrix_row(v, 0);
	v_out[1] = get_matrix_row(v, 1);
	v_out[2] = get_matrix_row(v, 2);

	v_out_p[0] = get_matrix_row(vp, 0);
	v_out_p[1] = get_matrix_row(vp, 1);
	v_out_p[2] = get_matrix_row(vp, 2);
}

#ifdef ADAPTIVE_TERRAIN_DRAW_PASS
#ifdef VERTEX_SHADER
float4 berp_front(in float4 v[3], in float2 u)
{
	return v[0] + u.x * (v[1] - v[0]) + u.y * (v[2] - v[0]);
}

float4 berp_back(in float4 v[3], in float2 u)
{
	return v[0] + u.x * (v[2] - v[0]) + u.y * (v[1] - v[0]);
}

float4 calculate_vertex_position(uint threadID, float2 vertex_pos)
{
	uint primID = culled_subd_buffer[threadID];
	uint key = culled_subd_buffer[threadID + 1];
	uint lod = firstbithigh(key);
	float4 v_in[3];
	v_in[0] = adaptive_terrain_vertices[adaptive_terrain_indices[primID * 3 + 0]];
	v_in[1] = adaptive_terrain_vertices[adaptive_terrain_indices[primID * 3 + 1]];
	v_in[2] = adaptive_terrain_vertices[adaptive_terrain_indices[primID * 3 + 2]];
	float4 v[3];
	subd(key, v_in, v);
	float4 final_vertex = (lod & 1) ? berp_back(v, vertex_pos) : berp_front(v, vertex_pos);
	return final_vertex;
}
#endif
#endif

#endif // RGL_ADAPTIVE_TERRAIN_UTILS_RSH_

