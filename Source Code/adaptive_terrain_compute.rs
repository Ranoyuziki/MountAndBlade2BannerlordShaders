#include "definitions.rsh"

#define max_culled_subd_index_count 0x80000
#define max_culled_subd_index_max (max_culled_subd_index_count - 1)

#define ADAPTIVE_TERRAIN_COMPUTE_PASS
#if SUBD_TERRAIN_INIT

#ifdef USE_DIRECTX12
#define subd_buffer_in (RWBuffer_uint_table[indices.u_custom_4])
#define subd_buffer_out (RWBuffer_uint_table[indices.u_custom_0])
#define culled_subd_buffer_out (RWBuffer_uint_table[indices.u_custom_1])
#define indirect_buffer (RWBuffer_uint_table[indices.u_custom_2])
#define counter_buffer_out (RWBuffer_uint_table[indices.u_custom_3])
#else
RWBuffer<uint> subd_buffer_in : register(u_custom_4);
RWBuffer<uint> subd_buffer_out : register(u_custom_0);
RWBuffer<uint> culled_subd_buffer_out : register(u_custom_1);
RWBuffer<uint> indirect_buffer : register(u_custom_2);
RWBuffer<uint> counter_buffer_out : register(u_custom_3);
#endif

#include "adaptive_terrain_common.rsh"

[numthreads(1, 1, 1)]
void main_cs(uint3 global_invocation_id : SV_DispatchThreadID)
{
	dispatch_indirect(indirect_buffer, 0, 1, 1, 1);

	subd_buffer_out[0] = 0;
	subd_buffer_out[1] = 1;
	subd_buffer_out[2] = 1;
	subd_buffer_out[3] = 1;

	culled_subd_buffer_out[0] = 0;
	culled_subd_buffer_out[1] = 1;
	culled_subd_buffer_out[2] = 1;
	culled_subd_buffer_out[3] = 1;

	subd_buffer_in[0] = 0;
	subd_buffer_in[1] = 1;
	subd_buffer_in[2] = 1;
	subd_buffer_in[3] = 1;

	uint tmp_original_value;

	InterlockedExchange(counter_buffer_out[0], 0, tmp_original_value);
	InterlockedExchange(counter_buffer_out[1], 0, tmp_original_value);
	InterlockedExchange(counter_buffer_out[2], 2, tmp_original_value);

	[unroll]
	for(uint i = 3; i < 8; ++i)
	{
		InterlockedExchange(counter_buffer_out[i], 0, tmp_original_value);
	}
}
#endif

#if SUBD_TERRAIN_UPDATE_INDIRECT

#ifdef USE_DIRECTX12
#define indirect_buffer (RWBuffer_uint_table[indices.u_custom_2])
#define counter_buffer_out (RWBuffer_uint_table[indices.u_custom_3])
#else
RWBuffer<uint> indirect_buffer : register(u_custom_2);
RWBuffer<uint> counter_buffer_out : register(u_custom_3);
#endif

#include "adaptive_terrain_common.rsh"

[numthreads(1, 1, 1)]
void main_cs(uint3 global_invocation_id : SV_DispatchThreadID)
{
	uint tmp;
	uint counter;
	InterlockedExchange(counter_buffer_out[0], 0, counter);
	InterlockedExchange(counter_buffer_out[1], 0, tmp);
	uint group_x = (counter / 2) / 128 + 1;
	InterlockedExchange(counter_buffer_out[2], (counter / 2), tmp);
	dispatch_indirect(indirect_buffer, 0, group_x, 1, 1);

	[unroll]
	for(uint i = 3; i < 8; ++i)
	{
		InterlockedExchange(counter_buffer_out[i], 0, tmp);
	}
}
#endif

#if SUBD_TERRAIN_LOD

#ifdef USE_DIRECTX12
#define counter_buffer_out (RWBuffer_uint_table[indices.u_custom_3])
#define subd_buffer_in (RWBuffer_uint_table[indices.u_custom_4])
#define subd_buffer_out (RWBuffer_uint_table[indices.u_custom_0])
#define culled_subd_buffer_out (RWBuffer_uint_table[indices.u_custom_1])
#else
RWBuffer<uint> counter_buffer_out : register(u_custom_3);
RWBuffer<uint> subd_buffer_in : register(u_custom_4);
RWBuffer<uint> subd_buffer_out : register(u_custom_0);
RWBuffer<uint> culled_subd_buffer_out : register(u_custom_1);
#endif

#include "adaptive_terrain_common.rsh"


struct Frustum
{
	float4 planes[6];
};


/**
 * Extract Frustum Planes from MVP Matrix
 *
 * Based on "Fast Extraction of Viewing Frustum Planes from the World-
 * View-Projection Matrix", by Gil Gribb and Klaus Hartmann.
 * This procedure computes the planes of the frustum and normalizes
 * them.
 */
float mtxGetElement(float4x4 mtx, uint row, uint col) 
{
	return mtx[col][row];
}

void loadFrustum(out Frustum f, float4x4 mvp)
{
	[unroll]
	for (int i = 0; i < 3; ++i)
	{
		[unroll]
		for (int j = 0; j < 2; ++j)
		{
			f.planes[i * 2 + j].x = mtxGetElement(mvp, 0, 3) + (j == 0 ? mtxGetElement(mvp, 0, i) : -mtxGetElement(mvp, 0, i));
			f.planes[i * 2 + j].y = mtxGetElement(mvp, 1, 3) + (j == 0 ? mtxGetElement(mvp, 1, i) : -mtxGetElement(mvp, 1, i));
			f.planes[i * 2 + j].z = mtxGetElement(mvp, 2, 3) + (j == 0 ? mtxGetElement(mvp, 2, i) : -mtxGetElement(mvp, 2, i));
			f.planes[i * 2 + j].w = mtxGetElement(mvp, 3, 3) + (j == 0 ? mtxGetElement(mvp, 3, i) : -mtxGetElement(mvp, 3, i));
			f.planes[i * 2 + j] *= length(f.planes[i * 2 + j].xyz);
		}
	}
}

/**
 * Negative Vertex of an AABB
 *
 * This procedure computes the negative vertex of an AABB
 * given a normal.
 * See the View Frustum Culling tutorial @ LightHouse3D.com
 * http://www.lighthouse3d.com/tutorials/view-frustum-culling/geometric-approach-testing-boxes-ii/
 */
float3 negativeVertex(float3 bmin, float3 bmax, float3 n)
{
	uint3 b = n > float3(0.0, 0.0, 0.0);
	return lerp(bmin, bmax, b);
}

/**
 * Frustum-AABB Culling Test
 *
 * This procedure returns true if the AABB is either inside, or in
 * intersection with the frustum, and false otherwise.
 * The test is based on the View Frustum Culling tutorial @ LightHouse3D.com
 * http://www.lighthouse3d.com/tutorials/view-frustum-culling/geometric-approach-testing-boxes-ii/
 */
bool frustumCullingTest(float4x4 mvp, float3 bmin, float3 bmax)
{
	float a = 1.0f;
	Frustum f;

	loadFrustum(f, mvp);
	for (int i = 0; i < 6 && a >= 0.0f; ++i)
	{
		float3 n = negativeVertex(bmin, bmax, f.planes[i].xyz);
		a = dot(float4(n, 1.0f), f.planes[i]);
	}

	return (a >= 0.0);
}

void frustumCullingTestAndWriteBuffer(float4x4 mvp, float3 bmin, float3 bmax, uint buffer_index, uint prim_id, uint prim_key, out bool result)
{
	result = false;
	if (frustumCullingTest(mvp, bmin, bmax))
	{
		uint idx = 0;
		InterlockedAdd(counter_buffer_out[3 + buffer_index], 2, idx);
		if(idx < max_culled_subd_index_max)
		{
			idx += max_culled_subd_index_count * buffer_index;
			culled_subd_buffer_out[idx] = prim_id;
			culled_subd_buffer_out[idx + 1] = prim_key;
			result = true;
		}
	}
}

[numthreads(128, 1, 1)]
void main_cs(uint3 global_invocation_id : SV_DispatchThreadID)
{
	// get threadID (each key is associated to a thread)
	uint threadID = global_invocation_id.x;
	if (threadID >= counter_buffer_out[2])
	{
		return;
	}

	threadID = threadID * 2;

	// get coarse triangle associated to the key
	uint primID = subd_buffer_in[threadID];
	uint key = subd_buffer_in[threadID + 1];

	float4 v_in[3];
	v_in[0] = adaptive_terrain_vertices[adaptive_terrain_indices[primID * 3 + 0]];
	v_in[1] = adaptive_terrain_vertices[adaptive_terrain_indices[primID * 3 + 1]];
	v_in[2] = adaptive_terrain_vertices[adaptive_terrain_indices[primID * 3 + 2]];

	float4 v[3];
	float4 vp[3];

	subd(key, v_in, v, vp);

	uint targetLod = uint(compute_lod(v));
	uint parentLod = uint(compute_lod(vp));
	if(adaptive_terrain.debug_freeze) 
	{
		targetLod = parentLod = firstbithigh(key);
	}

	update_subd_buffer(primID, key, targetLod, parentLod);
	uint current_lod = firstbithigh(key);

	// Cull invisible nodes

	float3 bmin = min(min(v[0], v[1]), v[2]).xyz;
	float3 bmax = max(max(v[0], v[1]), v[2]).xyz;
	bmin.z = 0;
	bmax.z = 1;

	bool result = false;
	frustumCullingTestAndWriteBuffer(adaptive_terrain.main_mvp, bmin, bmax, 0, primID, key, result);

	if(result)
	{
		uint idx = 0;
		InterlockedAdd(counter_buffer_out[1], 2, idx);
	}

	frustumCullingTestAndWriteBuffer(adaptive_terrain.shadow_mvp0, bmin, bmax, 1, primID, key, result);
	frustumCullingTestAndWriteBuffer(adaptive_terrain.shadow_mvp1, bmin, bmax, 2, primID, key, result);
	frustumCullingTestAndWriteBuffer(adaptive_terrain.shadow_mvp2, bmin, bmax, 3, primID, key, result);
	frustumCullingTestAndWriteBuffer(adaptive_terrain.shadow_mvp3, bmin, bmax, 4, primID, key, result);
}
#endif

#if SUBD_TERRAIN_UPDATE_DRAW

#ifdef USE_DIRECTX12
#define indirect_buffer (RWBuffer_uint_table[indices.u_custom_2])
#define counter_buffer_out (RWBuffer_uint_table[indices.u_custom_3])
#else
RWBuffer<uint> indirect_buffer : register(u_custom_2);
RWBuffer<uint> counter_buffer_out : register(u_custom_3);
#endif

#include "adaptive_terrain_common.rsh"

[numthreads(1, 1, 1)]
void main_cs(uint3 global_invocation_id : SV_DispatchThreadID)
{
	for(uint i = 3; i < 8; ++i)
	{
		uint counter = counter_buffer_out[i];
		counter = min(counter, max_culled_subd_index_max);
		draw_indexed_indirect(indirect_buffer, i - 2, 192, counter / 2, 0, 0, 0);
	}
}
#endif

