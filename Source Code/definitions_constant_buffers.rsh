
#ifndef DEFINITIONS_CONSTANT_BUFFERS_RSH
#define DEFINITIONS_CONSTANT_BUFFERS_RSH

#include "../shader_configuration.h"
#include "../shader_resource_indices_struct.h"
#include "definitions_shader_resource_indices.rsh"

cbuffer per_framef : register(b_per_framef)
{
	float4 g_camera_position;
	float4 g_root_camera_position;
	float4 g_sun_direction;

	float4x4 g_water_view_proj;
	float4x4 g_view;
	float4x4 g_proj;
	float4x4 g_view_proj;
	float4x4 g_viewproj_unjittered;
	float4x4 g_dynamic_sun_view_proj_arr[shadow_cascade_count];
	float4x4 g_sun_view_proj;
	float4x4 g_view_proj_inverse;

	float4x4 g_curr_to_prev_frame_ss_matrix;

	float4 g_fog_color_and_density;	// {1, 1, 1, 0.05f}
	float4 g_sun_params;
	float4 g_real_sun_color;
	float4 g_ambient_color;	// {64.f/255.f, 64.f/255.f, 64.f/255.f, 1.0f}
	float4 g_fog_ambient_color;	// {64.f/255.f, 64.f/255.f, 64.f/255.f, 1.0f}

	float4 g_perscene_f_group1;
	float4 g_perscene_f_group2;

	float4x4 g_inverse_view;
	float4 g_terrain_size_inv_xy_colormap_size_inv_zw;
	float4 g_global_wind_params;
	float4 g_dynamic_terrain_params;

	float4 g_application_halfpixel_viewport_size_inv;
	float4 g_output_gamma_and_inv;	// {2.2f, 1.0f / 2.2f, 1.0f, 1.0f}
	float4 g_debug_vectors_imp[RGL_NUM_DEBUG_VECTORS];	// {0,0,0,1}

	float4 g_perscene_f_group3;
	float4 g_perscene_f_group4;
	float4 g_perscene_f_group5;

	float4 g_cloud_shadow_params;
	float4 g_cloud_shadow_params_2;

	float4 g_clip_plane;
	float4 g_vertex_color_mask;
	float4 g_ambient_multiplier;
	float4 g_perscene_f_group6;

	float4 g_perscene_f_group7;
	float4 g_perscene_f_group8;

#ifdef USE_INTEGER16_HEIGHTMAP
	float4 g_global_terrain_min_max;	// {0,10,0,0}	//.x = min_height .y = max_height
#endif

	float4 g_shadow_center;
	float4 g_shadow_side;

	float4 g_prt_grid_info_1;
	float4 g_prt_grid_info_2;
	float4 g_prt_grid_info_3;
	float4 g_prt_grid_info_4;
	float4 g_prt_grid_info_5;

	float4 g_prt_sky_color_0;
	float4 g_prt_sky_color_1;
	float4 g_prt_sky_color_2;
	float4 g_prt_sky_color_3;
	float4 g_prt_sky_color_4;
	float4 g_prt_sky_color_5;

	float4 g_perscene_f_group9;
	float4 g_perscene_f_group10;
	float4 g_perscene_f_group11;
	float4 g_perscene_f_group12;
	float4 g_perscene_f_group13;
	float4 g_perscene_f_group14;
	float4 g_perscene_f_group15;
	float4 g_perscene_f_group16;
	float4 g_perscene_f_group17;
};

cbuffer terrain_meshf : register(b_terrain_meshf)
{
	float4x4 g_world_terrain;
	float4 terrf_vargroup0;
	float4 g_lod_edge_mask;
	float4 terrf_vargroup1;

#ifdef USE_INTEGER16_HEIGHTMAP
	float4 g_terrain_min_max;	// {0,10,0,0}	//.x = min_height .y = max_height
#endif

	float4 terrf_vargroup2;
	float4 terrf_vargroup3;

#ifdef RGL_USE_VIRTUAL_TEXTURING
	GraniteTilesetConstantBuffer g_vista_streaming_tile_data;
	GraniteStreamingTextureConstantBuffer g_vista_streaming_texture_data;
#endif

	int4 layer_weightmap_indices[8];
	float4 weightmap_half_pixel_size_per_layer[4];
};

cbuffer postfxf : register(b_postfxf)
{
	float4 g_postfxf_vargroup0;
	float4 g_postfxf_vargroup1;
	float4 g_postfxf_vargroup2;
	float4 g_postfxf_vargroup3;
	float4 g_postfxf_vargroup4;
	float4 g_world_frustum_depth_definition_right;
	float4 g_world_frustum_depth_definition_up;
	float4 g_postfxf_vargroup5;
	float4 g_postfxf_vargroup6;
	float last_mip;
	int g_tonemap_type;
	int g_exposure_type;
	float g_manual_exposure;
	float4 g_postfxf_vargroup20;
	float4 taa_0;
	float4 taa_1;
	float4 taa_2;
	float4 taa_3;
	float4 g_projection_info;
	float4 g_postfxf_vargroup8;
	float4 g_postfxf_vargroup9;
	float4 g_postfxf_vargroup10;
	float4 g_postfxf_vargroup11;
	float4 g_postfxf_vargroup12;
	float4 g_postfxf_vargroup13;
	float4 g_postfxf_vargroup14;
	float4 g_postfxf_vargroup15;
	float4 g_postfxf_vargroup16;
	float4 g_postfxf_vargroup17;
	float4 g_postfxf_vargroup18;
	uint4 cas_0;
	uint4 cas_1;
	uint4 fsr_0;
	uint4 fsr_1;
	uint4 fsr_2;
	uint4 fsr_3;
	float4 g_postfxf_vargroup19;
	float4 g_postfxf_vargroup21;
}

cbuffer per_mesh_skinnedf : register(b_per_meshf_skinned)
{
	float4x4 g_world_array[RGL_MAX_WORLD_MATRICES];
};

cbuffer per_instance_buffer : register(b_per_instance_buffer)
{
	Instance_data g_instance_data[RGL_MAX_FLORA_INSTANCE_COUNT];
}

cbuffer clip_planes : register(b_clip_planes)
{
	float4 g_clip_planes[64][6][4];
}

cbuffer per_dynamic_instance : register(b_per_dynamic_instance)
{
	int g_light_face_id;
	int g_meshf0_offset;
	int g_meshf1_offset;
	int g_zero_constant_output;
	int g_ui_offset;
	int g_material_flags;
	int pad1, pad2;

#ifdef RGL_USE_VIRTUAL_TEXTURING
	GraniteStreamingTextureConstantBuffer g_streaming_texture_data[2];
	int g_streaming_tileset_index;
	float pad3, pad4, pad5;
#endif
};

cbuffer custom_params : register(b_custom)
{
	float4x4 g_custom_matrix;
	float4 g_custom_vec0;
	float4 g_custom_vec1;
	float4 g_custom_vec2;
	float4 g_custom_vec3;
};

cbuffer terrain_layer_data : register(b_terrain_layer_data)
{
	DynamicTerrainLayerDesc dynamic_terrain_layer_descs[rgl_max_terrain_layers];
}

cbuffer editor_terrain_per_node : register(b_editor_terrain_per_node)
{
	int4 layer_usages[4];
	int4 weightmap_layer_texture_locations[16];
}
	

#ifdef RGL_USE_VIRTUAL_TEXTURING
cbuffer vt_tileset_params : register(b_per_vt_tileset)
{
	GraniteTilesetConstantBuffer g_streaming_tile_data[4];
	float g_secondary_texture_dither;
	float _pad0;
	float _pad1;
	float _pad2;
}
#endif

#ifdef USE_DIRECTX12
ConstantBuffer<resource_indices> indices : register(b_custom_2);
#endif

#define g_prt_grid_min g_prt_grid_info_1.xyz
#define g_prt_grid_max g_prt_grid_info_2.xyz
#define g_prt_grid_inv_size g_prt_grid_info_3.xyz
#define g_prt_grid_dims float3(g_prt_grid_info_1.w,g_prt_grid_info_2.w,g_prt_grid_info_3.w)

#define g_first_time_taa taa_0.x
#define g_jitter taa_1.xy

#endif // DEFINITIONS_CONSTANT_BUFFERS_RSH
