#ifndef DEFINITIONS_SHADER_RESOURCE_VIEWS_RSH
#define DEFINITIONS_SHADER_RESOURCE_VIEWS_RSH

#include "definitions_shader_structs.rsh"
#include "definitions_shader_resource_indices.rsh"

#if defined(USE_DIRECTX11) || defined(USE_GNM)
Texture2D texture0 : register(t_custom_0);
Texture2D<uint4> texture0Uint : register(t_custom_0);
Texture2D texture1 : register(t_custom_1);
Texture2D<uint4> texture1Uint : register(t_custom_1);
Texture2D texture2 : register(t_custom_2);
Texture2D texture3 : register(t_custom_3);
Texture2D texture4 : register(t_custom_4);
TextureCube texture5_cube : register(t_custom_5);
Texture2D texture6 : register(t_custom_6);
Texture2D texture7 : register(t_custom_7);
Texture2D texture8 : register(t_custom_8);
Texture2D texture9 : register(t_custom_9);
Texture2D texture10 : register(t_custom_10);
Texture2D texture11 : register(t_custom_11);
Texture2D texture12 : register(t_custom_12);
Texture2D texture13 : register(t_custom_13);
Texture2D texture14 : register(t_custom_14);
Texture2D<uint4> texture14Uint : register(t_custom_14);
Texture2D texture15 : register(t_custom_15);
Texture2D <uint4> textureUint : register(t_uint_texture);

Texture2D depth_texture : register(t_depth);
Texture2D colormap_diffuse_texture : register(t_terrain_color_map);
Texture2D colormap_specular_texture : register(t_terrain_specular_map);
Texture2D colormap_normal_texture : register(t_terrain_normal_map);
Texture2D shadowmap_texture : register(t_static_shadow);
Texture2DArray character_shadow_texture : register(t_dynamic_shadow);
Texture2D blood_texture : register(t_blood);
Texture2D skyaccess_texture : register(t_skyaccess);
Texture2D ssao_texture : register(t_ssao);
Texture2D brdf_texture : register(t_brdf);
Texture2D postfx_shadowmap_texture : register(t_shadowmap);
Texture2D ssr_texture : register(t_ssr);
Texture2D exposure_texture : register(t_exposure_texture);
Texture2D global_cloud_shadow_texture : register(t_cloud_shadow);
TextureCube texture_cube_global : register(t_cube_global);
TextureCubeArray texture_cube_array : register(t_cube_array);
Texture2D particle_shading_atlas_texture : register(t_particle_shading_atlas_texture);
Texture2D particle_shading_atlas_sky_vis_texture : register(t_particle_shading_atlas_texture_sky_vis);
Texture2D <uint4> stencil_texture : register(t_stencil);
Texture2D global_random_texture : register(t_global_random_texture);
Texture2D lights_shadow_texture : register(t_lights_shadow);
Texture2D<uint> overdrawSRV  : register(t_overdraw);
TextureCube scatter_cubemap : register(t_scatter_cubemap);
Texture2D raindrop_texture : register(t_rain_drop);
Texture2D topdown_depth_texture : register(t_topdown_depth_texture);
Texture2D terrain_height_texture : register(t_terrain_height_texture);
Texture2D terrain_shadow_texture : register(t_terrain_shadow_texture);
Texture2D<uint2> meshid_texture : register(t_mesh_id);
Texture2DArray vt_cache_texture_diffuse : register(t_vt_cache_texture_diffuse);
Texture2DArray vt_cache_texture_normal : register(t_vt_cache_texture_normal);
Texture2DArray vt_cache_texture_specular : register(t_vt_cache_texture_specular);
Texture2D vt_translation_texture : register(t_vt_translation_texture);
Texture2DArray terrain_diffuse_textures : register(t_terrain_diffuse_array);
Texture2DArray terrain_detail_normalmap_textures : register(t_terrain_detail_normalmap_array);
Texture2D<uint> terrain_materialmap_textures : register(t_terrain_materialmap_array);
Texture2DArray terrain_displacement_textures : register(t_terrain_displacement_array);
Texture2D snow_diffuse_texture : register(t_snow_diffuse);
Texture2D snow_normal_texture : register(t_snow_normal);
Texture2D snow_specular_texture : register(t_snow_spec);
Texture2D g_prt_diffuse_ambient_texture : register(t_prt_diffuse_ambient_texture);
Texture2D g_prt_visibility_depth_atlas : register(t_prt_visibility_depth_atlas);
Texture2D decal_atlas_texture : register(t_decal_atlas);
Texture2D grass_wind_texture : register(t_grass_wind_texture);

Buffer<uint> liveStatsSRV : register(t_livestats);
Buffer<uint> global_skinning_indirection_buffer : register(t_global_skinning_indirection_buffer);
Buffer<float4> global_skinning_buffer : register(t_global_skinning_buffer);
Buffer<float> global_skinned_position_buffer : register(t_global_skinned_position_buffer);
Buffer<uint> global_skinned_normal_buffer : register(t_global_skinned_normal_buffer);
Buffer<uint> global_skinned_tangent_buffer : register(t_global_skinned_tangent_buffer);
Buffer<float> prev_global_skinned_vertex_buffer : register(t_prev_global_skinned_vertex_buffer);
Buffer<uint> visible_env_map_probes : register(t_visible_env_map_probes);
StructuredBuffer<Particle_record> particle_records : register(t_particle_records);
StructuredBuffer<Particle_emitter_record> emitter_records : register(t_emitter_records);
StructuredBuffer<envmap_frame> visible_env_map_probes_inv_frames : register(t_visible_env_map_probes_inv_frames);
StructuredBuffer<meshf_0_struct> g_meshf0_buffer : register(t_meshf0_buffer);
StructuredBuffer<meshf_1_struct> g_meshf1_buffer : register(t_meshf1_buffer);
StructuredBuffer<ui_struct> g_ui_buffer : register(t_ui_buffer);
Buffer<uint> visible_lights : register(t_visible_lights);
Buffer<uint> visible_lights_wDepth : register(t_visible_lights_wDepth);
Buffer<float4> visible_lights_position_and_radius : register(t_visible_lights_position_and_radius);
StructuredBuffer<LightParams> visible_lights_params : register(t_visible_light_params);
StructuredBuffer<LightShadowParams> visible_light_shadow_params : register(t_visible_light_shadow_params);
Buffer<uint> light_faces : register(t_light_faces);
StructuredBuffer<SkinnedDecalParams> skinned_decals : register(t_skinned_decals);
StructuredBuffer<Prt_pgu_data> g_prt_probe_data : register(t_prt_probe_data);
StructuredBuffer<float4> g_prt_color_buffer : register(t_prt_color_buffer);
StructuredBuffer<Prt_visibility_data> g_prt_visibility_data : register(t_prt_visibility_data);
Buffer<uint> face_corner_to_vertex : register(t_face_corner_to_vertex);
Buffer<uint> simulated_positions : register(t_simulated_positions);
Buffer<uint> prev_simulated_positions : register(t_prev_simulated_positions);
Buffer<uint> simulated_normals : register(t_simulated_normals);
Buffer<uint> cloth_mapping_indices : register(t_cloth_mapping_indices);
Buffer<float> cloth_mapping_weights : register(t_cloth_mapping_weights);
Buffer<uint> visible_decals : register(t_tiled_decal_indices_buffer);
StructuredBuffer<DecalParams> visible_decal_render_params : register(t_tiled_decal_render_params_buffer);

#elif defined(USE_DIRECTX12) 

Texture2D Texture2D_table[] : register(t0, space0);
Texture2D<uint> Texture2D_uint_table[] : register(t0, space1);
Texture2D<uint2> Texture2D_uint2_table[] : register(t0, space2);
Texture2D<uint4> Texture2D_uint4_table[] : register(t0, space3);
Texture2D<float4> Texture2D_float4_table[] : register(t0, space4);
TextureCube TextureCube_table[] : register(t0, space5);
TextureCubeArray TextureCubeArray_table[] : register(t0, space6);
Texture2DArray Texture2DArray_table[] : register(t0, space7);
Buffer<uint> Buffer_uint_table[] : register(t0, space8);
Buffer<float> Buffer_float_table[] : register(t0, space9);
Buffer<float2> Buffer_float2_table[] : register(t0, space10);
Buffer<float3> Buffer_float3_table[] : register(t0, space11);
Buffer<float4> Buffer_float4_table[] : register(t0, space12);
StructuredBuffer<Particle_record> StructuredBuffer_Particle_record_table[] : register(t0, space13);
StructuredBuffer<Particle_emitter_record> StructuredBuffer_Particle_emitter_record_table[] : register(t0, space14);
StructuredBuffer<envmap_frame> StructuredBuffer_envmap_frame_table[] : register(t0, space15);
StructuredBuffer<meshf_0_struct> StructuredBuffer_meshf_0_struct_table[] : register(t0, space16);
StructuredBuffer<meshf_1_struct> StructuredBuffer_meshf_1_struct_table[] : register(t0, space17);
StructuredBuffer<ui_struct> StructuredBuffer_ui_struct_table[] : register(t0, space18);
StructuredBuffer<LightParams> StructuredBuffer_LightParams_table[] : register(t0, space19);
StructuredBuffer<LightShadowParams> StructuredBuffer_LightShadowParams_table[] : register(t0, space20);
StructuredBuffer<SkinnedDecalParams> StructuredBuffer_SkinnedDecalParams_table[] : register(t0, space21);
StructuredBuffer<Prt_pgu_data> StructuredBuffer_Prt_pgu_data_table[] : register(t0, space22);
StructuredBuffer<Prt_visibility_data> StructuredBuffer_Prt_visibility_data_table[] : register(t0, space23);
StructuredBuffer<DecalParams> StructuredBuffer_DecalParams_table[] : register(t0, space24);
StructuredBuffer<DecalFrameData> StructuredBuffer_DecalFrameData_table[] : register(t0, space25);
ByteAddressBuffer ByteAddressBuffer_table[] : register(t0, space26);
StructuredBuffer<float2> StructuredBuffer_float2_table[] : register(t0, space27);
StructuredBuffer<float> StructuredBuffer_float_table[] : register(t0, space28);
StructuredBuffer<WaterData> StructuredBuffer_WaterData_table[] : register(t0, space29);

StructuredBuffer<Constraint_set> StructuredBuffer_Constraint_set_table[] : register(t0, space30);
StructuredBuffer<Capsule3> StructuredBuffer_Capsule3_table[] : register(t0, space31);
StructuredBuffer<Dummy_particle_set> StructuredBuffer_Dummy_particle_set_table[] : register(t0, space32);
Buffer<uint2> Buffer_uint2_table[] : register(t0, space33);
Buffer<uint3> Buffer_uint3_table[] : register(t0, space34);
Buffer<uint4> Buffer_uint4_table[] : register(t0, space35);
StructuredBuffer<float4> StructuredBuffer_float4_table[] : register(t0, space36);
Texture2D<float> Texture2D_float_table[] : register(t0, space37);

#define texture0 (Texture2D_table[indices.t_custom_0])
#define texture0Uint (Texture2D_uint4_table[indices.t_custom_0])
#define texture1 (Texture2D_table[indices.t_custom_1])
#define texture1Uint (Texture2D_uint4_table[indices.t_custom_1])
#define texture2 (Texture2D_table[indices.t_custom_2])
#define texture3 (Texture2D_table[indices.t_custom_3])
#define texture4 (Texture2D_table[indices.t_custom_4])
#define texture5_cube (TextureCube_table[indices.t_custom_5])
#define texture6 (Texture2D_table[indices.t_custom_6])
#define texture7 (Texture2D_table[indices.t_custom_7])
#define texture8 (Texture2D_table[indices.t_custom_8])
#define texture9 (Texture2D_table[indices.t_custom_9])
#define texture10 (Texture2D_table[indices.t_custom_10])
#define texture11 (Texture2D_table[indices.t_custom_11])
#define texture12 (Texture2D_table[indices.t_custom_12])
#define texture13 (Texture2D_table[indices.t_custom_13])
#define texture14 (Texture2D_table[indices.t_custom_14])
#define texture14Uint (Texture2D_uint4_table[indices.t_custom_14])
#define texture15 (Texture2D_table[indices.t_custom_15])
#define textureUint (Texture2D_uint4_table[indices.t_uint_texture])

#define depth_texture (Texture2D_table[indices.t_depth])
#define colormap_diffuse_texture (Texture2D_table[indices.t_terrain_color_map])
#define colormap_specular_texture (Texture2D_table[indices.t_terrain_specular_map])
#define colormap_normal_texture (Texture2D_table[indices.t_terrain_normal_map])
#define shadowmap_texture (Texture2D_table[indices.t_static_shadow])
#define character_shadow_texture (Texture2DArray_table[indices.t_dynamic_shadow])
#define blood_texture (Texture2D_table[indices.t_blood])
#define skyaccess_texture (Texture2D_table[indices.t_skyaccess])
#define ssao_texture (Texture2D_table[indices.t_ssao])
#define brdf_texture (Texture2D_table[indices.t_brdf])
#define postfx_shadowmap_texture (Texture2D_table[indices.t_shadowmap])
#define ssr_texture (Texture2D_table[indices.t_ssr])
#define exposure_texture (Texture2D_table[indices.t_exposure_texture])
#define global_cloud_shadow_texture (Texture2D_table[indices.t_cloud_shadow])
#define texture_cube_global (TextureCube_table[indices.t_cube_global])
#define texture_cube_array (TextureCubeArray_table[indices.t_cube_array])
#define particle_shading_atlas_texture (Texture2D_table[indices.t_particle_shading_atlas_texture])
#define particle_shading_atlas_sky_vis_texture (Texture2D_table[indices.t_particle_shading_atlas_texture_sky_vis])
#define stencil_texture (Texture2D_uint4_table[indices.t_stencil])
#define global_random_texture (Texture2D_table[indices.t_global_random_texture])
#define lights_shadow_texture (Texture2D_table[indices.t_lights_shadow])
#define overdrawSRV (Texture2D_uint_table[indices.t_overdraw])
#define scatter_cubemap (TextureCube_table[indices.t_scatter_cubemap])
#define raindrop_texture (Texture2D_table[indices.t_rain_drop])
#define topdown_depth_texture (Texture2D_table[indices.t_topdown_depth_texture])
#define terrain_height_texture (Texture2D_table[indices.t_terrain_height_texture])
#define terrain_shadow_texture (Texture2D_table[indices.t_terrain_shadow_texture])
#define meshid_texture (Texture2D_uint2_table[indices.t_mesh_id])
#define vt_cache_texture_diffuse (Texture2DArray_table[indices.t_vt_cache_texture_diffuse])
#define vt_cache_texture_normal (Texture2DArray_table[indices.t_vt_cache_texture_normal])
#define vt_cache_texture_specular (Texture2DArray_table[indices.t_vt_cache_texture_specular])
#define vt_translation_texture (Texture2D_table[indices.t_vt_translation_texture])
#define terrain_diffuse_textures (Texture2DArray_table[indices.t_terrain_diffuse_array])
#define terrain_detail_normalmap_textures (Texture2DArray_table[indices.t_terrain_detail_normalmap_array])
#define terrain_materialmap_textures (Texture2D_uint_table[indices.t_terrain_materialmap_array])
#define terrain_displacement_textures (Texture2DArray_table[indices.t_terrain_displacement_array])
#define snow_diffuse_texture (Texture2D_table[indices.t_snow_diffuse])
#define snow_normal_texture (Texture2D_table[indices.t_snow_normal])
#define snow_specular_texture (Texture2D_table[indices.t_snow_spec])
#define g_prt_diffuse_ambient_texture (Texture2D_table[indices.t_prt_diffuse_ambient_texture])
#define g_prt_visibility_depth_atlas (Texture2D_table[indices.t_prt_visibility_depth_atlas])
#define decal_atlas_texture (Texture2D_table[indices.t_decal_atlas])
#define grass_wind_texture (Texture2D_table[indices.t_grass_wind_texture])

#define liveStatsSRV (Buffer_uint_table[indices.t_livestats])
#define global_skinning_indirection_buffer (Buffer_uint_table[indices.t_global_skinning_indirection_buffer])
#define global_skinning_buffer (Buffer_float4_table[indices.t_global_skinning_buffer])
#define global_skinned_position_buffer (Buffer_float_table[indices.t_global_skinned_position_buffer])
#define global_skinned_normal_buffer (Buffer_uint_table[indices.t_global_skinned_normal_buffer])
#define global_skinned_tangent_buffer (Buffer_uint_table[indices.t_global_skinned_tangent_buffer])
#define prev_global_skinned_vertex_buffer (Buffer_float_table[indices.t_prev_global_skinned_vertex_buffer])
#define visible_env_map_probes (Buffer_uint_table[indices.t_visible_env_map_probes])
#define particle_records (StructuredBuffer_Particle_record_table[indices.t_particle_records])
#define emitter_records (StructuredBuffer_Particle_emitter_record_table[indices.t_emitter_records])
#define visible_env_map_probes_inv_frames (StructuredBuffer_envmap_frame_table[indices.t_visible_env_map_probes_inv_frames])
#define g_meshf0_buffer (StructuredBuffer_meshf_0_struct_table[indices.t_meshf0_buffer])
#define g_meshf1_buffer (StructuredBuffer_meshf_1_struct_table[indices.t_meshf1_buffer])
#define g_ui_buffer (StructuredBuffer_ui_struct_table[indices.t_ui_buffer])
#define visible_lights (Buffer_uint_table[indices.t_visible_lights])
#define visible_lights_wDepth (Buffer_uint_table[indices.t_visible_lights_wDepth])
#define visible_lights_position_and_radius (Buffer_float4_table[indices.t_visible_lights_position_and_radius])
#define visible_lights_params (StructuredBuffer_LightParams_table[indices.t_visible_light_params])
#define visible_light_shadow_params (StructuredBuffer_LightShadowParams_table[indices.t_visible_light_shadow_params])
#define light_faces (Buffer_uint_table[indices.t_light_faces])
#define skinned_decals (StructuredBuffer_SkinnedDecalParams_table[indices.t_skinned_decals])
#define g_prt_probe_data (StructuredBuffer_Prt_pgu_data_table[indices.t_prt_probe_data])
#define g_prt_color_buffer (StructuredBuffer_float4_table[indices.t_prt_color_buffer])
#define g_prt_visibility_data (StructuredBuffer_Prt_visibility_data_table[indices.t_prt_visibility_data])
#define face_corner_to_vertex (Buffer_uint_table[indices.t_face_corner_to_vertex])
#define simulated_positions (Buffer_uint_table[indices.t_simulated_positions])
#define simulated_normals (Buffer_uint_table[indices.t_simulated_normals])
#define cloth_mapping_indices (Buffer_uint_table[indices.t_cloth_mapping_indices])
#define cloth_mapping_weights (Buffer_float_table[indices.t_cloth_mapping_weights])
#define visible_decals (Buffer_uint_table[indices.t_tiled_decal_indices_buffer])
#define visible_decal_render_params (StructuredBuffer_DecalParams_table[indices.t_tiled_decal_render_params_buffer])

#endif

#endif // DEFINITIONS_SHADER_RESOURCE_VIEWS_RSH
