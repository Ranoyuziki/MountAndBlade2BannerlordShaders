#ifndef DEFINITIONS_HELPER_MACROS_RSH
#define DEFINITIONS_HELPER_MACROS_RSH

#define g_prt_grid_min g_prt_grid_info_1.xyz
#define g_prt_grid_max g_prt_grid_info_2.xyz
#define g_prt_grid_inv_size g_prt_grid_info_3.xyz
#define g_prt_grid_dims float3(g_prt_grid_info_1.w,g_prt_grid_info_2.w,g_prt_grid_info_3.w)

#define g_use_dynamic_shadows					(g_perscene_f_group1.x)
#define g_fog_falloff							(g_perscene_f_group1.y)
#define g_rain_density							(g_perscene_f_group1.z)
#define g_rayleigh_constant						(g_perscene_f_group1.w)

#define g_use_tiled_rendering					(g_perscene_f_group2.x)
#define g_mie_scatter_particle_size				(g_perscene_f_group2.y)
#define g_fog_falloff_min						(g_perscene_f_group2.z)
#define g_fog_falloff_offset					(g_perscene_f_group2.w)

#define g_time_var								(g_perscene_f_group3.x)
#define g_shadow_map_next_pixel					(g_perscene_f_group3.y)
#define g_shadow_map_size						(g_perscene_f_group3.z)
#define g_flora_detail							(g_perscene_f_group3.w)

#define g_far_clip								(g_perscene_f_group4.x)
#define g_far_clip_inv							(g_perscene_f_group4.y)
#define g_use_depth_effects						(g_perscene_f_group4.z)
#define g_use_refraction						(g_perscene_f_group4.w)

#define g_fog_start_distance					(g_perscene_f_group5.x)
#define g_camera_right							(g_perscene_f_group5.y)
#define g_camera_top							(g_perscene_f_group5.z)
#define g_winter_time_factor					(g_perscene_f_group5.w)

#define g_camera_near							(g_perscene_f_group6.x)
#define g_projection_matrix_22					(g_perscene_f_group6.y)
#define g_projection_matrix_32					(g_perscene_f_group6.z)
#define g_blended_env_map_count					(g_perscene_f_group6.w)

#define cloud_shadow_amount						(g_cloud_shadow_params.x)
#define cloud_shadow_contrast					(g_cloud_shadow_params.y)
#define cloud_shadow_begin_height				(g_cloud_shadow_params.z)
#define cloud_shadow_range_inv					(g_cloud_shadow_params.w)

#define cloud_shadow_scale						(g_cloud_shadow_params_2.x)
#define cloud_shadow_speed						(g_cloud_shadow_params_2.y)

#define g_fog_scatter							(g_perscene_f_group9.x)
#define g_scatter_strength						(g_perscene_f_group9.y)

#define g_terrain_normalmap_size 				(terrf_vargroup0.x)
#define g_terrain_heightmap_size 				(terrf_vargroup0.y)
#define g_edge_count 							(terrf_vargroup0.z)
#define g_edge_count_of_highest_detail_level 	(terrf_vargroup0.w)

#define g_world_space_edge_size 				(terrf_vargroup1.x)
#ifdef SUPPORT_TERRAIN_MORPHING
#define g_terrain_lod_morph_const 			(terrf_vargroup1.y)
#define g_terrain_lod_morph_difference 		(terrf_vargroup1.z)
#endif
#define g_node_weightmap_start_index 			(terrf_vargroup1.w)

#define g_instance_count						(terrf_vargroup2.x)
#define g_local_node_offset						(terrf_vargroup2.y)
#define g_vista_diffuse_blend_type				(terrf_vargroup2.z)
#define g_vista_diffuse_blend_amount			(terrf_vargroup2.w)

#define g_vista_layer_detail_distance			(terrf_vargroup3.x)
#define g_vista_albedo_multiplier				(terrf_vargroup3.y)
#define g_vista_detail_tile						(terrf_vargroup3.z)

//only enabled at edit mode
#define g_terrain_coloring_with_angle_threshold	(terrf_vargroup3.w)

#define g_terrain_size_inv						float2(g_terrain_size_inv_xy_colormap_size_inv_zw.x, g_terrain_size_inv_xy_colormap_size_inv_zw.y)
#define g_terrain_colormap_size_inv				float2(g_terrain_size_inv_xy_colormap_size_inv_zw.z, g_terrain_size_inv_xy_colormap_size_inv_zw.w)

#define g_global_wind_direction					float2(g_global_wind_params.x, g_global_wind_params.y)
#define g_global_wind_direction_power			g_global_wind_params.z

#define g_postfx_viewport_halfpixelsize			(g_postfxf_vargroup0.xy)
#define g_postfx_viewport_resolution			(1.0 / (2.0 * g_postfx_viewport_halfpixelsize))
#define g_postfx_texture0_pixelsize				(g_postfxf_vargroup0.zw)
#define g_postfx_texture0_halfpixelsize			(g_postfx_texture0_pixelsize * 0.5)
#define g_postfx_texture0_resolution			(1.0 / g_postfx_texture0_pixelsize)

#define g_hdr_frame_time 						(g_postfxf_vargroup1.x)
#define g_dof_focus 							(g_postfxf_vargroup1.y)
#define g_dof_focus_end 						(g_postfxf_vargroup1.z)
#define g_middle_gray 							(g_postfxf_vargroup1.w)

#define g_sunshafts_strength 					(g_postfxf_vargroup2.x)
#define g_sun_camera_constant 					(g_postfxf_vargroup2.y)
#define g_screen_space_light_position_xy 		(g_postfxf_vargroup2.zw)

#define g_postfx_brightpass_threshold			(g_postfxf_vargroup3.x)	
#define g_postfx_exposure_deprecated			(g_postfxf_vargroup3.y)	
#define g_postfx_min_exposure					(g_postfxf_vargroup3.z)	
#define g_postfx_max_exposure					(g_postfxf_vargroup3.w)	

#define g_postfx_bloom_strength					(g_postfxf_vargroup4.x)	
#define g_postfx_bloom_amount					(g_postfxf_vargroup4.y)	
#define g_postfx_grain_amount					(g_postfxf_vargroup4.z)	
#define g_dof_focus_start						(g_postfxf_vargroup4.w)	

#define g_showing_cubic_texture					(g_postfxf_vargroup5.x)	
#define g_show_color_mask						(g_postfxf_vargroup5.y)	
#define g_is_dof_vignette_on					(g_postfxf_vargroup5.z)	
#define g_is_dof_on								(g_postfxf_vargroup5.w)

#define g_min_percent							(g_postfxf_vargroup6.x)	
#define g_max_percent							(g_postfxf_vargroup6.y)	
#define g_camera_fovy							(g_postfxf_vargroup6.z)	
#define g_color_grade_blend_alpha				(g_postfxf_vargroup6.w)

#define g_taa_resolve_jitter_x					(g_postfxf_vargroup20.x)	
#define g_taa_resolve_jitter_y					(g_postfxf_vargroup20.y)	
#define g_sao_rotation							(g_postfxf_vargroup20.z)	
#define g_anti_banding_noise_amount				(g_postfxf_vargroup20.w)	

#define g_postfx_envmap_blend_amount			(g_postfxf_vargroup8.x)	
#define g_postfx_streak_strength				(g_postfxf_vargroup8.y)	
#define g_postfx_lens_flare_amount				(g_postfxf_vargroup8.z)	
#define g_postfx_lens_flare_threshold			(g_postfxf_vargroup8.w)

#define g_postfx_streak_amount					(g_postfxf_vargroup9.x)
#define g_postfx_streak_stretch					(g_postfxf_vargroup9.y)	
#define g_postfx_streak_intensity				(g_postfxf_vargroup9.z)	
#define g_postfx_streak_threshold				(g_postfxf_vargroup9.w)	

#define g_postfx_streak_tint 					(g_postfxf_vargroup10)

#define g_postfx_lens_flare_blur_sigma			(g_postfxf_vargroup11.x)
#define g_postfx_lens_flare_blur_size			(g_postfxf_vargroup11.y)
#define g_postfx_lens_flare_halo_weight			(g_postfxf_vargroup11.z)
#define g_postfx_lens_flare_ghost_weight		(g_postfxf_vargroup11.w)

#define g_postfx_lens_flare_halo_width			(g_postfxf_vargroup12.x)
#define g_postfx_lens_flare_ghost_samples		(g_postfxf_vargroup12.y)
#define g_postfx_lens_flare_aberration_offset	(g_postfxf_vargroup12.z)
#define g_postfx_lens_flare_dirt_weight			(g_postfxf_vargroup12.w)

#define g_postfx_lens_flare_diffraction_weight	(g_postfxf_vargroup13.x)
#define g_postfx_lens_flare_strength			(g_postfxf_vargroup13.y)
#define g_postfx_vignette_inner_radius			(g_postfxf_vargroup13.z)	
#define g_postfx_vignette_outer_radius			(g_postfxf_vargroup13.w)

#define g_postfx_aberration_offset				(g_postfxf_vargroup14.x)	
#define g_postfx_aberration_size				(g_postfxf_vargroup14.y)	
#define g_postfx_aberration_smooth				(g_postfxf_vargroup14.z)	
#define g_postfx_lens_distortion				(g_postfxf_vargroup14.w)	

#define g_postfx_vignette_opacity				(g_postfxf_vargroup15.x)	
#define g_postfx_sharpen_strength				(g_postfxf_vargroup15.y)
#define g_postfx_target_exposure				(g_postfxf_vargroup15.z)
#define g_contour_blur_saturation_distance		(g_postfxf_vargroup15.w)

#define g_postfx_hexagon_vignette_color 		(g_postfxf_vargroup17.xyz)
#define g_postfx_hexagon_vignette_alpha 		(g_postfxf_vargroup17.w)

#define g_shadowmap_size						(g_postfxf_vargroup18.x)
#define g_frame_index_module 					(g_postfxf_vargroup18.y)
#define g_sky_rotation							(g_postfxf_vargroup18.z)
#define g_exposure_factor						(g_postfxf_vargroup18.w)

#define g_cas_0									(cas_0.xyzw)
#define g_cas_1									(cas_1.xyzw)

#define g_fsr_0									(fsr_0.xyzw)
#define g_fsr_1									(fsr_1.xyzw)
#define g_fsr_2									(fsr_2.xyzw)
#define g_fsr_3									(fsr_3.xyzw)

#define g_postfx_rc_scale						(g_postfxf_vargroup19.xy)
#define g_postfx_prev_rc_scale					(g_postfxf_vargroup19.zw)

#define g_viewport_clamp						(g_postfxf_vargroup21.xy)

#define g_fog_color 							(g_fog_color_and_density.xyz)
#define g_fog_density							(g_fog_color_and_density.w)	

#define g_output_gamma							(g_output_gamma_and_inv.x)
#define g_output_gamma_inv						(g_output_gamma_and_inv.y)
#define g_output_brightness						(g_output_gamma_and_inv.z)

#define g_sun_direction_inv						(-g_sun_direction.xyz)

#define g_sun_size_inv 							(g_sun_params.w)
#define g_sun_color								(g_sun_params.rgb)

#define g_sky_brightness						(g_perscene_f_group7.x)
#define g_dryness_factor						(g_perscene_f_group7.y)
#define g_application_viewport_size				float2(g_perscene_f_group7.z, g_perscene_f_group7.w)

#define g_water_probe_index						(g_perscene_f_group8.x)
#define g_shadow_cascade_0_far					(g_perscene_f_group8.y)
#define g_water_level							(g_perscene_f_group8.z)
#define g_number_of_terrain_mesh_blend_layers	(g_perscene_f_group8.w)

#define g_jitter_x								(g_perscene_f_group9.z)
#define g_jitter_y								(g_perscene_f_group9.w)

#define g_use_pre_exposure						(g_perscene_f_group10.x)
#define g_particle_atlas_width					(g_perscene_f_group10.y)
#define g_particle_atlas_height					(g_perscene_f_group10.z)
#define g_scene_scale							(g_perscene_f_group10.w)

#define g_shadow_opacity						(g_perscene_f_group11.x)
#define g_painted_mesh_count					(g_perscene_f_group11.y)
#define g_texture_density_threshold0			(g_perscene_f_group11.z)
#define g_texture_density_threshold1			(g_perscene_f_group11.w)

#define g_texture_density_threshold2			(g_perscene_f_group12.x)
#define g_use_tiled_decal_rendering				(g_perscene_f_group12.y)
#define g_decal_atlas_texture_dim				(g_perscene_f_group12.zw)

#define g_tiled_lights_overdraw_visualize_limit	(g_perscene_f_group13.x)
#define g_tiled_decals_overdraw_visualize_limit	(g_perscene_f_group13.y)
#define g_water_amplitude						(g_perscene_f_group13.z)
#define g_minimum_ambient						(g_perscene_f_group13.w)

#define g_rc_scale								(g_perscene_f_group14.xy)
#define g_rc_offset								(g_perscene_f_group14.zw)

#define g_brightness_min						(g_perscene_f_group15.x)
#define g_brightness_max						(g_perscene_f_group15.y)
#define g_is_gi_enabled							(g_perscene_f_group15.z)
#define g_noise_enabled							(g_perscene_f_group15.w)

#define g_target_exposure						(g_perscene_f_group16.x)
#define g_output_target_exposure				(g_perscene_f_group16.y)
#define g_exposure_compensation					(g_perscene_f_group16.z)
#define g_use_tiled_envmaps						(g_perscene_f_group16.w)

#define g_prev_rc_scale							(g_perscene_f_group17.xy)
#define g_halfpixel_size_of_render_target		(g_perscene_f_group17.zw)

/************************************************************************/
/*                    Material Flags                                    */
/************************************************************************/

#define g_mf_do_not_use_alpha							0x00000001
#define g_mf_disable_vertex_color_alpha					0x00000002
#define g_mf_use_specular								0x00000004
#define g_mf_dont_use_albedo_texture					0x00000008

#define g_mf_separate_displacement_map					0x00000010
#define g_mf_use_vertex_color_green_modified_parallax	0x00000020
#define g_mf_do_not_use_vertex_color_as_occlusion		0x00000040
#define g_mf_use_atlas_shading							0x00000080

#define HAS_MATERIAL_FLAG(flag) bool(g_material_flags & flag)

#ifdef SUPPORT_DEBUG_VECTOR
#define g_debug_vector g_debug_vectors_imp[0]
#define g_debug_vectors g_debug_vectors_imp
#endif

#define g_first_time_taa taa_0.x
#define g_jitter taa_1.xy

#if ENABLE_DYNAMIC_INSTANCING && !defined(USE_DECAL_RENDERING)
#if PIXEL_SHADER
#define VAR_OFFSET_VALUE (uint)In.world_position.w
#else
#define VAR_OFFSET_VALUE In.instanceID
#endif
#else
#define VAR_OFFSET_VALUE 0
#endif

#ifndef TWO_DIMENSIONAL_UI

#define g_world									(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].world)
#define g_permeshf_vargroup1					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].permeshf_vargroup1)
#define g_permeshf_vargroup1_w					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].permeshf_vargroup1_w)
#define g_texture_scalers						(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].texture_scalers)
#define g_permeshf_vargroup2 					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].permeshf_vargroup2)
#define g_permeshf_vargroup3 					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].permeshf_vargroup3)
#define g_bone_buffer_offset 					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].bone_buffer_offset)
#define g_prev_bone_buffer_offset				(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].prev_bone_buffer_offset)
#define g_entity_id								(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].entity_id)
#define g_mesh_id								(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].mesh_id)
#define g_cloth_face_corner_to_vertex_offset	(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].cloth_face_corner_to_vertex_offset_)
#define g_cloth_mapping_offset					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].cloth_mapping_offset_)
#define g_cloth_vertex_offset					(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].cloth_vertex_offset_)
#define g_cloth_simulation_start_offset			(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].cloth_simulation_start_offset_)
#define g_parallax_offset						(g_meshf0_buffer[g_meshf0_offset + VAR_OFFSET_VALUE].parallax_offset)

#define g_mesh_factor_color						(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].mesh_factor_color)
#define g_mesh_factor2_color 					(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].mesh_factor2_color)
#define g_mesh_vector_argument 					(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].mesh_vector_argument)
#define g_mesh_vector_argument_2				(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].mesh_vector_argument_2)
#define g_world_inverse                         (g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].world_inverse)
#define g_mesh_prev_frame_transform				(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].mesh_prev_frame_transform)
#define g_permeshf_vargroup0					(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].permeshf_vargroup0)
#define g_contour_color                         (g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].contour_color)
#define g_mesh_bbox_min                         (g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].bbox_min)
#define g_mesh_bbox_max                         (g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].bbox_max)
#define g_cloth_bone_frame_z_displacement       (g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].cloth_bone_frame_z_displacement_)
#define g_additional_bone_frame_offset			(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].permeshf_vargroup0.x)
#define g_clipping_plane_position				(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].clipping_plane_position)
#define g_clipping_plane_normal					(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].clipping_plane_normal)
#define g_bounding_radius						(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].bounding_radius)
#define g_is_stationary							(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].is_stationary)
#define g_material_exposure_compensation		(g_meshf1_buffer[g_meshf1_offset + VAR_OFFSET_VALUE].material_exposure_compensation)

#else

#define g_ui_world								(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].world)
#define g_ui_mesh_factor_color 					(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].mesh_factor_color)
#define g_ui_clip_circle						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].clip_circle_params)
#define g_ui_clip_rect 							(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].clip_rect_params)
#define g_ui_hsv_factors						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].hsv_factors)
#define g_ui_overlay_texture_params				(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].overlay_texture_params)
#define g_ui_overlay_texture_params_2			(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].overlay_texture_params_2)
#define g_ui_draw_position						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].draw_position)
#define g_ui_color_factors						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].color_factors)
#define g_ui_glow_color							(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].glow_color)
#define g_ui_outline_color						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].outline_color)
#define g_ui_glow_params						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].glow_params)
#define g_ui_font_params						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].font_params)
#define g_ui_custom_vec4_0						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].custom_vec4_0)
#define g_ui_custom_vec4_1 						(g_ui_buffer[g_ui_offset + VAR_OFFSET_VALUE].custom_vec4_1)

#endif

#define g_areamap_scale							(g_texture_scalers.x)
#define g_areamap_amount						(g_texture_scalers.y)
#define g_detailmap_scale						(g_texture_scalers.z)
#define g_normalmap_power						(g_texture_scalers.w)

#define g_spotlight_hotspot_angle				(g_mesh_factor2_color.x)
#define g_spotlight_falloff_angle				(g_mesh_factor2_color.y)

#define g_alpha_ref								(g_permeshf_vargroup1.y)
#define g_apply_gpu_face_animations				(g_permeshf_vargroup1_w)

#define g_specular_coef							(g_permeshf_vargroup2.x)
#define g_gloss_coef							(g_permeshf_vargroup2.y)
#define g_mesh_parallax_amount					(g_permeshf_vargroup2.z)
#define g_ambient_occlusion_coef				(g_permeshf_vargroup2.w)

#define g_skinned_decal_index					(g_permeshf_vargroup3.x)
#define g_skinned_decal_count					(g_permeshf_vargroup3.y)

#define g_fade_out_distance 					(g_mesh_vector_argument.w)

#define g_skinned_vertex_buffer_offset			(g_permeshf_vargroup3.z)
#define g_prev_skinned_vertex_buffer_offset		(g_permeshf_vargroup3.w)

// rglDecalModeFlags
#define rgl_decal_flag_modify_albedo				0x00000001
#define rgl_decal_flag_modify_normal				0x00000002
#define rgl_decal_flag_modify_spec					0x00000004
#define rgl_decal_flag_modify_occlusion				0x00000008
#define rgl_decal_flag_hardlight_blend				0x00000010
#define rgl_decal_flag_height_masked				0x00000020
#define rgl_decal_flag_use_parallax					0x00000040
#define rgl_decal_flag_render_on_objects			0x00000080
#define rgl_decal_flag_render_on_terrain			0x00000100
#define rgl_decal_flag_render_on_grass				0x00000200
#define rgl_decal_flag_do_not_blend_normals			0x00000400
#define rgl_decal_flag_override_visibility_checks	0x00000800
#define rgl_decal_flag_is_road						0x00001000
#define rgl_decal_flag_road_tile_side				0x00002000

#endif
