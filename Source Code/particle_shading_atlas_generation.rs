#pragma warning(disable : 4714) // error X4714: sum of temp registers and indexable temp registers times 1024 threads exceeds the recommended total 16384. Performance may be reduced
#pragma warning(disable : 7203)

#include "../shader_configuration.h"

#define PARTICLE_ATLAS_GENERATION_CS

#include "definitions.rsh"
#include "ambient_functions.rsh"


#include "particle_shading.rsh"

cbuffer Generation_params : register(b_custom_0)
{
	float4 g_sun_dir;
	uint g_particle_offset;
	uint g_quad_count;
	uint color;
	uint padding2;
	float4 g_cam_pos;
}

/*
First group which process one particle per compute thread need special handling because of shared memory limitations.
Normally we run 32x32 thread per group but the case we process one quad per thread requires quad specific data for every thread which
in turn exceeds shared memory limitation(32kb). We divide 32x32 group into 4 16x16 groups for GROUP_BATCH_COUNT_32 flag
*/


#if GROUP_BATCH_COUNT_2
#define GROUP_BATCH_COUNT 2
#elif GROUP_BATCH_COUNT_4
#define GROUP_BATCH_COUNT 4
#elif GROUP_BATCH_COUNT_8
#define GROUP_BATCH_COUNT 8
#elif GROUP_BATCH_COUNT_16
#define GROUP_BATCH_COUNT 16
#elif GROUP_BATCH_COUNT_32
#define GROUP_BATCH_COUNT 16
#define GROUP_SIZE 16
#else
#define GROUP_BATCH_COUNT 1
#endif

#ifndef GROUP_SIZE
#define GROUP_SIZE 32
#endif

#define QUAD_SIZE (GROUP_SIZE/GROUP_BATCH_COUNT)
#define PARTICLE_COUNT_PER_GROUP (GROUP_BATCH_COUNT * GROUP_BATCH_COUNT)

#ifdef USE_DIRECTX12
#define particle_indices (Buffer_uint_table[indices.t_custom_1])
#define atlas (RWTexture2D_float3_table[indices.u_custom_0])
#define sky_visibility_texture (RWTexture2D_float_table[indices.u_custom_1])
#else
Buffer<uint> particle_indices				: register(t_custom_1);
RWTexture2D<float3> atlas					: register(u_custom_0);
RWTexture2D<float> sky_visibility_texture	: register(u_custom_1);
#endif


#if QUAD_SIZE != 1
groupshared uint gs_particle_indices[PARTICLE_COUNT_PER_GROUP];
groupshared uint gs_atlas_data[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_position0[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_position1[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_position2[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_position3[PARTICLE_COUNT_PER_GROUP];

groupshared float3 gs_quad_normals0[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_normals1[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_normals2[PARTICLE_COUNT_PER_GROUP];
groupshared float3 gs_quad_normals3[PARTICLE_COUNT_PER_GROUP];

groupshared float gs_sun_amount[GROUP_SIZE][GROUP_SIZE];
groupshared float gs_sun_amount_blurred[GROUP_SIZE][GROUP_SIZE];
#endif

static const float2 quad_positions[4] =
{
	float2(-1,1),
	float2(-1,-1),
	float2(1,-1),
	float2(1,1)
};

static const float rcp_sqrt3 = 0.57735026f;
static const float3 quad_spherical_normals[4] =
{
	float3(-rcp_sqrt3, rcp_sqrt3, rcp_sqrt3),
	float3(-rcp_sqrt3, -rcp_sqrt3, rcp_sqrt3),
	float3(rcp_sqrt3, -rcp_sqrt3, rcp_sqrt3),
	float3(rcp_sqrt3, rcp_sqrt3, rcp_sqrt3)
};

[numthreads(GROUP_SIZE, GROUP_SIZE, 1)]
void main_cs(uint3 gi : SV_GroupID, uint3 gti : SV_GroupThreadID, uint gtid : SV_GroupIndex)
{
	const uint2 local_quad_index = gti.xy / QUAD_SIZE;
	const uint local_quad_index_flattened = local_quad_index.y * GROUP_BATCH_COUNT + local_quad_index.x;
	const uint dispatch_particle_index = gi.x * PARTICLE_COUNT_PER_GROUP + local_quad_index_flattened;
#if QUAD_SIZE != 1
	if ((gi.x * PARTICLE_COUNT_PER_GROUP + gtid) < g_quad_count && gtid < PARTICLE_COUNT_PER_GROUP)
	{
		const uint particle_index = particle_indices[gi.x * PARTICLE_COUNT_PER_GROUP + g_particle_offset + gtid];
		gs_particle_indices[gtid] = particle_index;
		gs_atlas_data[gtid] = particle_records[particle_index].atlas_data;

		const float3 particle_position = particle_records[particle_index].position;
		const int emitter_index = particle_records[particle_index].emitter_index_;
		const float3 particle_displacement = particle_records[particle_index].displacement;
		const uint emitter_misc_flags = emitter_records[emitter_index].misc_flags;
		const float2 emitter_quad_scale = emitter_records[emitter_index].quad_scale;
		const float2 emitter_quad_bias = emitter_records[emitter_index].quad_bias;

		float4x4 particle_frame = get_particle_frame(emitter_misc_flags, particle_position, particle_displacement, particle_records[particle_index].fixed_billboard_direction, particle_records[particle_index].rotation, 1, 0);

		gs_quad_position0[gtid] = mul(particle_frame, float4((quad_positions[0] * emitter_quad_scale + emitter_quad_bias) * particle_records[particle_index].size, 0, 1.0)).xyz;
		gs_quad_position1[gtid] = mul(particle_frame, float4((quad_positions[1] * emitter_quad_scale + emitter_quad_bias) * particle_records[particle_index].size, 0, 1.0)).xyz;
		gs_quad_position2[gtid] = mul(particle_frame, float4((quad_positions[2] * emitter_quad_scale + emitter_quad_bias) * particle_records[particle_index].size, 0, 1.0)).xyz;
		gs_quad_position3[gtid] = mul(particle_frame, float4((quad_positions[3] * emitter_quad_scale + emitter_quad_bias) * particle_records[particle_index].size, 0, 1.0)).xyz;
		if (emitter_misc_flags & gpumf_spherical_normals)
		{
			gs_quad_normals0[gtid] = mul(to_float3x3(particle_frame), quad_spherical_normals[0]).xyz;
			gs_quad_normals1[gtid] = mul(to_float3x3(particle_frame), quad_spherical_normals[1]).xyz;
			gs_quad_normals2[gtid] = mul(to_float3x3(particle_frame), quad_spherical_normals[2]).xyz;
			gs_quad_normals3[gtid] = mul(to_float3x3(particle_frame), quad_spherical_normals[3]).xyz;
		}
		else
		{
			gs_quad_normals0[gtid] = particle_frame._m02_m12_m22;
			gs_quad_normals1[gtid] = particle_frame._m02_m12_m22;
			gs_quad_normals2[gtid] = particle_frame._m02_m12_m22;
			gs_quad_normals3[gtid] = particle_frame._m02_m12_m22;
		}
	}
	GroupMemoryBarrierWithGroupSync();
#endif

	float3 position = float3(0.0, 0.0, 0.0);
	float2 uv = float2(0.0, 0.0);
	uint2 local_quad_coord = uint2(0, 0);
	uint2 offset = uint2(0, 0);

	if (dispatch_particle_index < g_quad_count)
	{
		local_quad_coord = gti.xy % QUAD_SIZE;
#if QUAD_SIZE == 1
		const uint particle_index = particle_indices[gi.x * PARTICLE_COUNT_PER_GROUP + g_particle_offset + gtid];
		position = particle_records[particle_index].position;
		uv = 0.5;
		const uint atlas_data = particle_records[particle_index].atlas_data;
		offset = uint2((atlas_data & 0x00FFF000) >> 12, atlas_data & 0x00000FFF);
#else
		uv = float2(local_quad_coord.x / (float)(QUAD_SIZE - 1), local_quad_coord.y / (float)(QUAD_SIZE - 1));
		float3 position03 = lerp(gs_quad_position0[local_quad_index_flattened], gs_quad_position3[local_quad_index_flattened], uv.x);
		float3 position12 = lerp(gs_quad_position1[local_quad_index_flattened], gs_quad_position2[local_quad_index_flattened], uv.x);
		position = lerp(position03, position12, uv.y);

		const float sun_amount = compute_sun_amount_for_texture_no_blend(position);
		gs_sun_amount[gti.x][gti.y] = sun_amount;

		const uint atlas_data = gs_atlas_data[local_quad_index_flattened];// particle_records[particle_index].atlas_data;
		offset = uint2((atlas_data & 0x00FFF000) >> 12, atlas_data & 0x00000FFF);
#endif	
	}
	GroupMemoryBarrierWithGroupSync();

#if QUAD_SIZE != 1
	if (dispatch_particle_index < g_quad_count)
	{
		int dx = local_quad_coord.x == 0 || local_quad_coord.x == QUAD_SIZE - 1 ? 0 : 1;
		gs_sun_amount_blurred[gti.y][gti.x] = (gs_sun_amount[gti.x - dx][gti.y] + gs_sun_amount[gti.x][gti.y] + gs_sun_amount[gti.x + dx][gti.y]) / 3.0;
	}
	GroupMemoryBarrierWithGroupSync();

	if (dispatch_particle_index < g_quad_count)
	{
		int dy = local_quad_coord.y == 0 || local_quad_coord.y == QUAD_SIZE - 1 ? 0 : 1;
		gs_sun_amount[gti.x][gti.y] = (gs_sun_amount_blurred[gti.y - dy][gti.x] + gs_sun_amount_blurred[gti.y][gti.x] + gs_sun_amount_blurred[gti.y + dy][gti.x]) / 3.0;
	}
	GroupMemoryBarrierWithGroupSync();
#endif

	if (dispatch_particle_index < g_quad_count)
	{
#if QUAD_SIZE == 1
		const uint particle_index = particle_indices[gi.x * PARTICLE_COUNT_PER_GROUP + g_particle_offset + gtid];
		const uint emitter_misc_flags = emitter_records[particle_records[particle_index].emitter_index_].misc_flags;
		const float3 particle_position = particle_records[particle_index].position;
		const float3 particle_displacement = particle_records[particle_index].displacement;

		float4x4 particle_frame = get_particle_frame(emitter_misc_flags, particle_position, particle_displacement, particle_records[particle_index].fixed_billboard_direction,
			particle_records[particle_index].rotation, 1, 0);
		float3 normal = normalize(particle_frame._m02_m12_m22);
#else
		const uint particle_index = gs_particle_indices[local_quad_index_flattened];// particle_indices[particle_buffer_index + g_particle_offset];		
		const uint emitter_misc_flags = emitter_records[particle_records[particle_index].emitter_index_].misc_flags;
		float3 normal03 = lerp(gs_quad_normals0[local_quad_index_flattened], gs_quad_normals3[local_quad_index_flattened], uv.x);
		float3 normal12 = lerp(gs_quad_normals1[local_quad_index_flattened], gs_quad_normals2[local_quad_index_flattened], uv.x);
		float3 normal = normalize(lerp(normal03, normal12, uv.y));
#endif
		const float backlight_multiplier = emitter_records[particle_records[particle_index].emitter_index_].backlight_multiplier;

		float4 particle_color = extract_particle_color(particle_records[particle_index].particle_color);

		if (emitter_misc_flags & gpumf_use_terrain_albedo)
		{
			float2 colormap_uv;
			colormap_uv.x = ((particle_records[particle_index].colormap_uv_ & 0xFFFF0000) >> 16) / ((float)0xFFFF);
			colormap_uv.y = ((particle_records[particle_index].colormap_uv_ & 0x0000FFFF) >> 0) / ((float)0xFFFF);			
			float3 colormap = sample_texture_level(colormap_diffuse_texture, linear_sampler, colormap_uv, 0).rgb;
			particle_color.rgb *= colormap * colormap;
		}
		
#if QUAD_SIZE == 1
		const float sun_amount = compute_sun_amount_for_texture_no_blend(position);
#else
		const float sun_amount = gs_sun_amount[gti.x][gti.y];// compute_sun_amount_for_texture_no_blend(position);
#endif

		const float3 view_vec = normalize(g_root_camera_position.xyz - position.xyz);
		float3 sun_light = compute_lighting_particle(0, particle_color.rgb, g_sun_color, sun_amount, normal, view_vec, g_sun_direction_inv, 0, backlight_multiplier);
		float4 ps_pos = mul(g_view_proj, float4(position, 1.0));
		ps_pos.xy /= ps_pos.w;
		ps_pos.xy = ps_pos.xy * 0.5 + 0.5;
		ps_pos.y = 1.0 - ps_pos.y;
		float3 diffuse_ambient_term = 1;
		float3 dummy_specular_ambient_term = 1;
		float sky_visibility = 1;
		get_ambient_terms(position, normal, normal, ps_pos.xy, view_vec, 0, color, sun_amount, dummy_specular_ambient_term, diffuse_ambient_term, sky_visibility);

		#if SYSTEM_USE_PRT
			sky_visibility_texture[local_quad_coord + offset] = sky_visibility;
		#endif

		#if ENABLE_POINTLIGHTS
		[branch]
		if (g_use_tiled_rendering > 0.0)
		{
			float3 total_color = 0;
			int2 tile_counts = ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
			int2 tile_index = (ps_pos.xy * g_application_viewport_size / g_rc_scale) / RGL_TILED_CULING_TILE_SIZE;
			tile_index = min(max(0, tile_index), tile_counts - 1);
			uint start_index = MAX_LIGHT_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
			uint probe_index = visible_lights[start_index];
			while (probe_index != 0xFFFF)
			{
				total_color += compute_point_light_contribution_particle(probe_index, float2(0, 0),
					particle_color.rgb, normal, view_vec,
					position, ps_pos.xy, backlight_multiplier);
				//total_color += 1;

				start_index++;
				probe_index = visible_lights[start_index];
			}

			sun_light.rgb += total_color;
		}
		#endif
		atlas[local_quad_coord + offset] = (particle_color.rgb * diffuse_ambient_term + sun_light) * get_pre_exposure();
	}
}
