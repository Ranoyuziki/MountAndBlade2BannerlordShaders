//
// This file is auto generated. Generate it with resources.shader.generate_shaders 
//

#ifndef DEFINITIONS_SHADER_RESOURCE_INDICES_RSH
#define DEFINITIONS_SHADER_RESOURCE_INDICES_RSH

#define il_regular 0
#define il_normal_map 1
#define il_skinning 2
#define il_normal_map_skinning 3
#define il_postfx 4
#define il_regular_doubleuv 5
#define il_normal_map_doubleuv 6
#define il_skinning_doubleuv 7
#define il_normal_map_skinning_doubleuv 8
#define il_empty 9
#define il_depth_only 10
#define il_depth_only_with_alpha 11
#define il_skinning_32bit 12
#define il_normal_map_skinning_32bit 13
#define il_skinning_32bit_doubleuv 14
#define il_normal_map_skinning_32bit_doubleuv 15

#define s_point s0
#define s_point_clamp s1
#define s_linear s2
#define s_linear_clamp s3
#define s_linear_mirror s4
#define s_anisotropic s5
#define s_compare_lequal s6
#define s_compare_gequal s7
#define s_compare_lequal_bordered s8

#if defined(USE_DIRECTX11) || defined(USE_GNM)

#define t_custom_0 t0
#define t_custom_1 t1
#define t_custom_2 t2
#define t_custom_3 t3
#define t_custom_4 t4
#define t_custom_5 t5
#define t_custom_6 t6
#define t_custom_7 t7
#define t_custom_8 t8
#define t_custom_9 t9
#define t_custom_10 t10
#define t_custom_11 t11
#define t_custom_12 t12
#define t_custom_13 t13
#define t_custom_14 t14
#define t_custom_15 t15
#define t_depth t16
#define t_terrain_color_map t17
#define t_terrain_specular_map t18
#define t_terrain_normal_map t19
#define t_static_shadow t20
#define t_dynamic_shadow t21
#define t_blood t22
#define t_skyaccess t23
#define t_ssao t24
#define t_brdf t25
#define t_shadowmap t26
#define t_ssr t27
#define t_exposure_texture t28
#define t_cloud_shadow t29
#define t_cube_global t30
#define t_cube_array t31
#define t_particle_shading_atlas_texture t32
#define t_stencil t33
#define t_global_random_texture t34
#define t_lights_shadow t35
#define t_overdraw t36
#define t_scatter_cubemap t37
#define t_rain_drop t38
#define t_topdown_depth_texture t39
#define t_terrain_height_texture t40
#define t_terrain_shadow_texture t41
#define t_mesh_id t42
#define t_uint_texture t43
#define t_vt_cache_texture_diffuse t44
#define t_vt_cache_texture_normal t45
#define t_vt_cache_texture_specular t46
#define t_vt_translation_texture t47
#define t_terrain_diffuse_array t48
#define t_terrain_detail_normalmap_array t49
#define t_terrain_materialmap_array t50
#define t_terrain_displacement_array t51
#define t_snow_diffuse t52
#define t_snow_normal t53
#define t_snow_spec t54
#define t_prt_diffuse_ambient_texture t55
#define t_prt_visibility_depth_atlas t56
#define t_face_corner_to_vertex t57
#define t_simulated_positions t58
#define t_prev_simulated_positions t59
#define t_simulated_normals t60
#define t_cloth_mapping_indices t61
#define t_cloth_mapping_weights t62
#define t_decal_atlas t63
#define t_grass_wind_texture t64
#define t_particle_shading_atlas_texture_sky_vis t65
#define t_livestats t66
#define t_global_skinning_indirection_buffer t67
#define t_global_skinning_buffer t68
#define t_global_skinned_position_buffer t69
#define t_global_skinned_normal_buffer t70
#define t_global_skinned_tangent_buffer t71
#define t_prev_global_skinned_vertex_buffer t72
#define t_visible_env_map_probes t73
#define t_particle_records t74
#define t_emitter_records t75
#define t_visible_env_map_probes_inv_frames t76
#define t_meshf0_buffer t77
#define t_meshf1_buffer t78
#define t_ui_buffer t79
#define t_visible_lights t80
#define t_visible_lights_wDepth t81
#define t_visible_lights_position_and_radius t82
#define t_visible_light_params t83
#define t_visible_light_shadow_params t84
#define t_light_faces t85
#define t_skinned_decals t86
#define t_prt_probe_data t87
#define t_prt_color_buffer t88
#define t_prt_visibility_data t89
#define t_tiled_decal_indices_buffer t90
#define t_tiled_decal_pos_radius_buffer t91
#define t_tiled_decal_render_params_buffer t92

#define u_output_0 u0
#define u_custom_0 u1
#define u_custom_1 u2
#define u_custom_2 u3
#define u_custom_3 u4
#define u_custom_4 u5
#define u_vt_resolve_texture u6

#endif

#define b_per_framef b0
#define b_terrain_meshf b1
#define b_postfxf b2
#define b_per_meshf_skinned b3
#define b_per_instance_buffer b4
#define b_clip_planes b5
#define b_per_dynamic_instance b6
#define b_custom b7
#define b_terrain_layer_data b8
#define b_per_vt_tileset b9
#define b_editor_terrain_per_node b10
#define b_custom_0 b11
#define b_custom_1 b12
#define b_custom_2 b13

#endif // DEFINITIONS_SHADER_RESOURCE_INDICES_RSH
