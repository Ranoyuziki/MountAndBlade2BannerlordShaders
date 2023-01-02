
#ifndef DEFINITIONS_SHADER_STRUCTS_RSH
#define DEFINITIONS_SHADER_STRUCTS_RSH

#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING)
struct Instance_data
{
	float3 position;
	uint color;
	uint tangent0;
	uint tangent1;
	float scale;
	float alpha;
};
#else
struct Instance_data
{
	float4x4 frame;
};
#endif

struct DynamicTerrainLayerDesc
{
	float4x4 dt_layer_tc_transformation;
	float4x4 dt_layer_tc_transformation_ortho;

	// layer_tc_transformation can have floating point precision issues..
	// To counter that, this block is used for shader cache validation, only being sent to gpu at editor scenes
	float4 pitch_roll_yaw_padding;
	float4 scale_shear;
	float4 position_offset_padding2;

	int4 dt_layer_flags0;
	int4 dt_layer_flags1;
	int4 dt_layer_flags2;
	int4 dt_layer_flags3;
	float4 dt_layer_bigdetail_scalebias;
	float4 dt_layer_vargroup1;
	float4 dt_layer_vargroup2;
	int4 diffuse_layer_texture_locations;
	int4 areamap_layer_texture_locations;
	int4 normalmap_layer_texture_locations;
	int4 specular_layer_texture_locations;
	int4 splattingmap_layer_texture_locations;
	int4 displacement_layer_texture_locations;
	float4 heightmap_texture_resolutions;
	float4 albedo_factor_color;
};

struct envmap_frame
{
	float4x4 inverse_frame;
	float4 position;
	float4 dimension;
};

// Per-mesh1 floats
struct meshf_0_struct
{
	float4x4 world;

	float2 permeshf_vargroup1;
	int mesh_id; //permeshf_vargroup1 z
	float permeshf_vargroup1_w;

	float4 texture_scalers; // {1, 1, 1, 1};
	float4 permeshf_vargroup2;
	int4 permeshf_vargroup3;
	int bone_buffer_offset;
	int prev_bone_buffer_offset;
	int entity_id;
	float parallax_offset;
	int cloth_face_corner_to_vertex_offset_;
	int cloth_mapping_offset_;
	int cloth_vertex_offset_;
	int cloth_simulation_start_offset_;
};

struct meshf_1_struct
{
	float4 mesh_factor_color; // {255.f/255.f, 230.f/255.f, 200.f/255.f, 1.0f}
	float4 mesh_factor2_color;
	float4 mesh_vector_argument;
	float4 mesh_vector_argument_2; // {0, 0, 0, 0};
	float4x4 world_inverse;
	float4x4 mesh_prev_frame_transform;
	float4 permeshf_vargroup0;
	float4 contour_color;
	float3 bbox_min;
	float cloth_max_distance_multiplier_;
	float3 bbox_max;
	float cloth_bone_frame_z_displacement_;

	float bounding_radius;
	float is_stationary;
	float material_exposure_compensation, pad1;

	float4 clipping_plane_position;
	float4 clipping_plane_normal;
};

struct ui_struct
{
	float4x4 world;
	float4 mesh_factor_color;
	float4 clip_circle_params;
	float4 clip_rect_params;
	float4 hsv_factors;
	float4 overlay_texture_params;
	float4 overlay_texture_params_2;
	float4 draw_position;
	float4 color_factors;
	float4 glow_color;
	float4 outline_color;
	float4 glow_params;
	float4 font_params;
	float4 custom_vec4_0;
	float4 custom_vec4_1;
};

struct LightParams
{
	float4 position;
	float4 color;
	float4 shadowradius_and_attenuation_and_invsize_and_shadowed;
	float4 spotlight_and_direction;
	float4 spotlight_hotspot_angle_and_falloff_angle_and_clip_plane_and_volumetric;
	float4 spotlight_proj22_and_proj32;

	uint shadow_params_index;
	float pad0;
	float pad1;
	float pad2;
};

struct LightShadowParams
{
	float4 shadow_offset_and_bias[6];
	float4x4 shadow_view_proj[6];
};

struct SkinnedDecalParams
{
	float4 position_and_radius;
	float4 direction_and_atlas_index;
};

struct Prt_pgu_data
{
	uint packed_data;		//flags, color index, visibility_index
};

struct Prt_visibility_data
{
	float4 visibility_uv_scale_bias[6];
};

struct Particle_record
{
	float3 position;
	float rotation;

	float2 uv_bias;
	float size;
	uint emitter_index_;

	uint particle_color;
	float3 displacement;

	//8:size, 12:x offset, 12:y offset
	uint atlas_data;
	float3 fixed_billboard_direction;
	float exposure_compensation;

	uint colormap_uv_;
};

struct Particle_emitter_record
{
	float fadeout_distance;
	float fadeout_coef;
	float2 uv_scale;

	float backlight_multiplier;
	float skew_with_particle_velocity_coef_;
	float scale_with_emitter_velocity_coef_;
	float diffuse_multiplier;

	float2 quad_scale;
	float2 quad_bias;

	float camera_fadeout_coef;
	uint misc_flags;
	float skew_with_particle_velocity_limit_;
	float emissive_multiplier;

	float heatmap_multiplier_;
	float pad0;
	float pad1;
	float pad2;
};

struct DecalParams
{
	float4x4 frame_inv;
	float4x4 frame;
	float4 atlas_uv; // scale_x, scale_y, offset_x, offset_y
	float4 d_atlas_uv_d;
	float4 d_atlas_uv_s;
	float4 d_atlas_uv_n;

	float specular_coef;
	float mip_level;
	float parallax_amount;
	float normalmap_power;

	float4 factor_color_1;

	float emission_amount;
	float gloss_coef;
	uint decal_flags;
	uint entity_id;

	float4 contour_color;

	float2 boundary_p0;
	float2 boundary_p1;
	float2 boundary_p2;
	float2 boundary_p3;

	float4 path_p0;
	float4 path_p1;
	float4 path_p2;

	float width;
	float height;

	float road_start_phase;
	float road_start_offset;

	float4x4 path_cumulative_distances;

	float start_fadeout;
	float end_fadeout;

	float mip_multiplier;
	float pad0;
};

struct DecalFrameData
{
	float4 position_radius;
	float4x4 frame_inv;
};

struct BokehPoint
{
	float3 Position;
	float Blur;
	float3 Color;
};

struct WaterData
{
	float4 pos_radius;
};


//GPU CLOTH SOLVER

struct Constraint_set
{
	int stretching_start_;
	int stretching_count_;
	int shearing_start_;
	int shearing_count_;
	int bending_start_;
	int bending_count_;
};

struct Dummy_particle_set
{
	int element_count_;
	int element_start_;
};

struct Constraint
{
	int vertex_index_0;
	int vertex_index_1;
};

struct Capsule3
{
	float3 point0_;
	float radius0_;
	float3 point1_;
	float radius1_;
	int2 point0_bone_indices_;
	float2 point0_bone_weights_;
	int2 point1_bone_indices_;
	float2 point1_bone_weights_;
};


#endif
