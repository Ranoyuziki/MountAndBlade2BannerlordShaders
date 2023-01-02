
#ifndef MODULAR_STRUCT_DEFINITIONS_RSH
#define MODULAR_STRUCT_DEFINITIONS_RSH

#include "definitions.rsh"

#define MATERIAL_ID_DEFAULT 0
#define MATERIAL_ID_STANDART 1
#define MATERIAL_ID_METALLIC 2
#define MATERIAL_ID_TERRAIN 3
#define MATERIAL_ID_DEFERRED 4
#define MATERIAL_ID_FACE 5
#define MATERIAL_ID_FLORA 6
#define MATERIAL_ID_FLORA_BILLBOARD 7
#define MATERIAL_ID_GRASS 8
#define MATERIAL_ID_FLORA_BILLBOARD_DYNAMIC_SHADOWED 9
#define MATERIAL_ID_SKYBOX 10
#define MATERIAL_ID_TRANSLUCENT_FACE 11
#define MATERIAL_ID_NONE 12

#if VDECL_HAS_DOUBLEUV || TATTOOED_FACE
	#define TEXCOORD_FORMAT float4
#else
	#define TEXCOORD_FORMAT float2
#endif

#if (VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS))
struct VS_OUTPUT_GRASS
{
		precise float4 position	 : RGL_POSITION;	
		float4 tex_coord : TEXCOORD0; //texcoord_distance_vertexalpha
		RGL_NO_INTERPOLATION uint instanceID : TEXCOORD2;
		float4 world_position : TEXCOORD3;
#ifdef POINTLIGHT_SHADOWMAP_PASS
		float4 clip_distances : SV_ClipDistance0;
#endif
	};

#else

	struct VS_OUTPUT_GRASS
	{
		precise float4 position : RGL_POSITION;
	float4 tex_coord : TEXCOORD0; //texcoord_distance_lod
	float4 world_normal : TEXCOORD1;
	RGL_NO_INTERPOLATION uint instanceID : TEXCOORD2;
	float4 world_position : TEXCOORD3;
};
	
#endif

struct VS_OUTPUT_WATER
{
	float4 position          			: RGL_POSITION;
	float2 tex_coord         			: TEXCOORD0;
	float4 PosWater						: TEXCOORD1; //position according to the water camera
			
	float4 projCoord 					: TEXCOORD2;
	float4 world_position		   		: TEXCOORD3; 
	float4 vertex_color   				: TEXCOORD4; 
			
	float4 world_tangent    			: TEXCOORD5;
	float4 world_binormal   			: TEXCOORD6;
	float4 world_normal    				: TEXCOORD7;
			
	float4 ClipSpacePos					: TEXCOORD10;
	
		
	#if USE_TESSELATION
		float vertex_distance_factor 	:TEXCOORD8;
	#endif

#if ENABLE_DYNAMIC_INSTANCING
	RGL_NO_INTERPOLATION int instanceID : TEXCOORD9;
#endif

};
struct VS_OUTPUT_GLASS
{
	float4 position : RGL_POSITION;
	float2 tex_coord : TEXCOORD0;

	float4 projCoord : TEXCOORD2;
	float4 world_position : TEXCOORD3;
	float4 vertex_color : TEXCOORD4;

	float4 world_tangent : TEXCOORD5;
	float4 world_binormal : TEXCOORD6;
	float4 world_normal : TEXCOORD7;

	float4 ClipSpacePos : TEXCOORD10;

	float4 resolve_output : TEXCOORD11;

#if USE_TESSELATION
	float vertex_distance_factor : TEXCOORD8;
#endif

#if ENABLE_DYNAMIC_INSTANCING
	RGL_NO_INTERPOLATION int instanceID : TEXCOORD9;
#endif

};

struct VS_OUT_GBUFFER_SKYBOX
{
	float4 position			: RGL_POSITION;
	float2 tex_coord		: TEXCOORD0;
	float4 world_position	: TEXCOORD1;

#if ENABLE_DYNAMIC_INSTANCING
	RGL_NO_INTERPOLATION int instanceID : TEXCOORD2;
#endif
};

struct VS_OUTPUT_STANDART
{
	precise float4 position : RGL_POSITION;

#if !defined(SHADOWMAP_PASS) || ALPHA_TEST || PIXEL_SHADER || defined(HAS_MODIFIER) || USE_TESSELATION
	float4 vertex_color				: COLOR0;
	TEXCOORD_FORMAT tex_coord		: TEXCOORD2;
	float4 world_position : TEXCOORD0;
#endif

#if !defined(SHADOWMAP_PASS) || USE_TESSELATION
	float4 world_normal				: TEXCOORD1;

	#if USE_OBJECT_SPACE_TANGENT
		float4 world_tangent		: TEXCOORD3;
	#endif // VDECL_HAS_TANGENT_DATA

	#if VDECL_HAS_SKIN_DATA && SYSTEM_WRITE_MOTION_VECTORS
		float3 object_space_position : TEXCOORD12;
		float3 prev_object_space_position : TEXCOORD11;
	#endif

	#if USE_TESSELATION
		float vertex_distance_factor :TEXCOORD5;
	#endif

		#if SYSTEM_BLOOD_LAYER || TRIPLANAR_PROTOTYPE_MATERIAL
			float3 local_position : TEXCOORD6;
			float3 local_normal : TEXCOORD7;
		#endif

	#ifdef USE_MOTION_BLUR_ARROW
		float arrow_mb_alpha_multiplier : TEXCOORD9;
	#endif

#if (my_material_id == MATERIAL_ID_FLORA)
			float3 albedo_multiplier_center_position :TEXCOORD9;
	#endif
#endif

	#if defined(POINTLIGHT_SHADOWMAP_PASS) || SYSTEM_USE_CUSTOM_CLIPPING
			float4 clip_distances : SV_ClipDistance0;
	#endif


#if defined(OVERDRAW_PASS)
			uint instanceID : TEXCOORD10;
#endif

#if defined(PIXEL_SHADER) && SYSTEM_TWO_SIDED_RENDER
			bool is_fronface : SV_IsFrontFace;
#endif
};

struct GS_OUTPUT_STANDART
{
	float4 position					: RGL_POSITION;
	float4 vertex_color				: COLOR0;
	float4 world_position			: TEXCOORD0;
	float4 world_normal				: TEXCOORD1;
	TEXCOORD_FORMAT tex_coord		: TEXCOORD2;

#if VDECL_HAS_TANGENT_DATA
	float4 world_tangent		: TEXCOORD3;
#endif // VDECL_HAS_TANGENT_DATA

#if USE_TESSELATION
	float vertex_distance_factor :TEXCOORD5;
#endif

#if SYSTEM_BLOOD_LAYER || TRIPLANAR_PROTOTYPE_MATERIAL
	float3 local_position : TEXCOORD6;
	float3 local_normal : TEXCOORD7;
#endif

#ifdef USE_MOTION_BLUR_ARROW
	float arrow_mb_alpha_multiplier : TEXCOORD9;
#endif

#if ALBEDO_MULTIPLIER_PROJECTION 
	float3 albedo_multiplier_center_position :TEXCOORD9;
#endif

#ifdef POINTLIGHT_SHADOWMAP_PASS
	uint viewport_array_index : SV_ViewportArrayIndex;
#endif

};

struct water_shading_values
{
	float4 diffuse_sample;
	float3 normal_sample;
	float3 specular_sample;
	float early_alpha_value;
	float3 world_space_normal;
	float3 vertex_normal;
	float3 tangent_space_normal;
	float2 specularity;
	float3 albedo_color;
	float4 resolve;
	float3 refraction_world_position;
	float skyacces_depth;
	float gbuffer_depth;
	float depth_distance;
	float3 depth_effect_factor;
	float4 flow_vector;
	float albedo_alpha;
	float ambient_ao_factor;
	float translucency;
	float shadow;
	float4 resolve_output;
};

struct glass_shading_values
{
	float4 diffuse_sample;
	float4 diffuse2_sample;
	float3 normal_sample;
	float3 normal2_sample;
	float3 specular_sample;
	float early_alpha_value;
	float3 world_space_normal;
	float3 tangent_space_normal;
	float2 specularity;
	float3 albedo_color;
	float3 refraction_world_position;
	float gbuffer_depth;
	float depth_distance;
	float3 depth_effect_factor;
	float albedo_alpha;
	float ambient_ao_factor;
	float diffuse_ao_factor;
	float translucency;
	float shadow;
	float3 vertex_normal;
	float4 resolve_output;
};

struct pbr_shading_values
{
	float4 diffuse_sample;
	float4 diffuse2_sample;
	float3 normal_sample;
	float3 normal2_sample;
	float3 specular_sample;

	float early_alpha_value;
	float3 world_space_normal;
	float2 specularity;
	float3 albedo_color;
	float ambient_ao_factor;
    float diffuse_ao_factor;
	float occlusion;
	float translucency;
	float shadow;
	float3 vertex_normal;
	float3 secondary_normal; // for eye
	float4 resolve_output;
};

struct particle_shading_values
{
	float4 diffuse_sample;
	float4 diffuse2_sample;
	float4 normal_sample;
	float3 specular_sample;

	float early_alpha_value;
	float3 world_space_normal;
	float2 specularity;
	float3 albedo_color;
	float ambient_ao_factor;
	float diffuse_ao_factor;
	float occlusion;
	float translucency;
	float shadow;
	float3 vertex_normal;
	float3 secondary_normal; // for eye
	float4 resolve_output;
};

struct decal_auxiliary_values
{
	float2 atlassed_texture_coord;
	float3 pixel_normal_in_ws;
	float4 pixel_pos_in_ws;
		float wetness_value;
};

struct standart_auxiliary_values
{
	float wetness_value;
	float4 decal_albedo_alpha;
	float3 decal_normal;
	float2 decal_specularity;
	float3 albedo_color_without_effects;
	float2 parallax_texcoord;
	
	#ifdef WORLDMAP_TREE
		float worldmap_snow_mask;
	#endif

	#if PROCEDURAL_TERRAIN_BLEND
		//TODO_MURAT0 : fix occlusion calculation technique to reduce register pressure
		float occlusion_from_terrain;
		float terrain_blend_amount;
	#endif
};

struct hair_auxiliary_values
{
	float wetness_value;
	float4 decal_albedo_alpha;
	float3 decal_normal;
	float2 decal_specularity;
	float4 diffuse_texture_color;
	float3 world_fur_direction;
};

struct terrain_auxiliary_values
{
	float wetness_amount;
	float3 node_normal;
	float3 terrain_point_color;
	float _materialmap_weight;
	float2 _specular_info;
};

struct VS_OUTPUT_SIMPLE_HAIR
{
	float4 position					: RGL_POSITION;
	float4 Color					: COLOR0;
	float4 vertex_color				: COLOR1;
	float2 tex_coord				: TEXCOORD0;
	float4 SunLight					: TEXCOORD1;
	float4 world_position			: TEXCOORD4;
#if ENABLE_DYNAMIC_INSTANCING || defined(OVERDRAW_PASS)
	uint instanceID : SV_InstanceID;
#endif

#if VDECL_HAS_SKIN_DATA
	float3 prev_object_space_position : TEXCOORD11;
#endif
};

struct VS_OUTPUT_HAIR
{
	float4 position				: RGL_POSITION;
	float2 tex_coord			: TEXCOORD0;
	float4 world_position		: TEXCOORD5;

#if !defined(SHADOWMAP_PASS)
	float4 vertex_color			: TEXCOORD2;
	float3 world_normal			: TEXCOORD3;
	float4 world_tangent		: TEXCOORD4;

#if SYSTEM_BLOOD_LAYER || TRIPLANAR_PROTOTYPE_MATERIAL
	float3 local_position : TEXCOORD7;
	float3 local_normal : TEXCOORD8;
#endif

#if VDECL_HAS_SKIN_DATA
	float3 prev_object_space_position : TEXCOORD11;
	float3 object_space_position : TEXCOORD12;
#endif
#endif

#if defined(POINTLIGHT_SHADOWMAP_PASS) ||SYSTEM_USE_CUSTOM_CLIPPING
	float4 clip_distances : SV_ClipDistance0;
#endif

#if !defined(SHADOWMAP_PASS)
#if defined(PIXEL_SHADER) && SYSTEM_TWO_SIDED_RENDER
	bool is_fronface : SV_IsFrontFace;
#endif
#endif
};

#if USE_TESSELATION

struct HS_CONSTANT_DATA_OUTPUT_STANDART
{
	float edges[3]	: SV_TessFactor;
	float inside	: SV_InsideTessFactor;

	#ifdef PN_TRIANGLES
		float3 WorldPos_B030: TEXCOORD10;
		float3 WorldPos_B021: TEXCOORD11;
		float3 WorldPos_B012: TEXCOORD12;
		float3 WorldPos_B003: TEXCOORD13;
		float3 WorldPos_B102: TEXCOORD14;
		float3 WorldPos_B201: TEXCOORD15;
		float3 WorldPos_B300: TEXCOORD16;
		float3 WorldPos_B210: TEXCOORD17;
		float3 WorldPos_B120: TEXCOORD18;
		float3 WorldPos_B111: TEXCOORD19;
	#endif

	uint instanceID : TEXCOORD09;

};

struct HS_CONSTANT_DATA_OUTPUT_TERRAIN
{
    float edges[3]	: SV_TessFactor;
    float inside	: SV_InsideTessFactor;
};

struct HS_CONTROL_POINT_OUTPUT
{
	float3 world_position						: POSITION;
	float2 material_tex_coord					: TEXCOORD0;
	float2 shadowmap_tex_coord					: TEXCOORD1;
	float4 material_node_tex_coord_side_front 	: TEXCOORD2;
	float vertex_distance_factor 				: TEXCOORD3;
};

struct DS_OUTPUT
{
    float4 position								: SV_POSITION;
	float3 world_position						: POSITION;
	float2 material_tex_coord					: TEXCOORD0;
	float2 shadowmap_tex_coord					: TEXCOORD1;
	float4 material_node_tex_coord_side_front 	: TEXCOORD2;
	float  clip_space_distance					: TEXCOORD3;

#if VDECL_HAS_SKIN_DATA
	float3 prev_object_space_position			: TEXCOORD4;
#endif
};

#endif

struct VS_OUTPUT_TERRAIN	//TODO_GOKHAN2: code cleanup required for terrain tessellation 
{ 
#if USE_TESSELATION
	float3 world_position			: POSITION;
#else
	float4 position					: RGL_POSITION;
#endif

	float2 material_tex_coord		: TEXCOORD0;
	float2 shadowmap_tex_coord		: TEXCOORD1;	
	float4 material_node_tex_coord_side_front : TEXCOORD2;

#if USE_TESSELATION
	float  vertex_distance_factor	: TEXCOORD3;
#else
	float4 world_position			: TEXCOORD3;
	#endif

	float  clip_space_distance	: TEXCOORD7;
#ifdef POINTLIGHT_SHADOWMAP_PASS
	float4 clip_distances : SV_ClipDistance0;
#endif
};

struct VS_OUTPUT_FLORA_SPEEDTREE_BILLBOARD
{
	float4 position : RGL_POSITION;
	float4 world_position : TEXCOORD0;
	float4 world_normal : TEXCOORD1;
	TEXCOORD_FORMAT tex_coord : TEXCOORD2;
	float2 opacity_fadeout : TEXCOORD3;
	float4 vertex_color : TEXCOORD5;
	float4 albedo_multiplier_center_position_and_topdown : TEXCOORD9;
	
};


struct VS_OUTPUT_FLORA_GPU_BILLBOARD
{
	float4 position					: RGL_POSITION;	
	float4 world_position			: TEXCOORD0;
	float4 world_normal				: TEXCOORD1;
	TEXCOORD_FORMAT tex_coord		: TEXCOORD2;
	float4 shadow_world_position	: TEXCOORD3;
	RGL_NO_INTERPOLATION float3 sample_data	: TEXCOORD4;
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	float4 vertex_color				: TEXCOORD5;
#endif
#if ALBEDO_MULTIPLIER_PROJECTION 
	float3 albedo_multiplier_center_position :TEXCOORD6;
#endif
	RGL_NO_INTERPOLATION float fadeout_constant : TEXCOORD7;	
};

struct Per_pixel_static_variables
{
	float3 world_space_position;	
	float2 screen_space_position;
	float3 view_vector_unorm;
	float view_length;
	float3 view_vector;
};

struct Per_vertex_modifiable_variables
{
	float4 object_position;
	float3 object_normal;
	float4 object_tangent;
	float3 object_binormal;
	float3 prev_object_position;

	float4 world_position;
	float4 world_normal;	
	
	float4 tex_coord_1;
	float4 tex_coord_2;
	
	float4 vertex_color;
};

struct VS_OUTPUT_PARTICLE
{
	float4 position					: RGL_POSITION;
	float4 vertex_color				: COLOR0;
	float4 world_position			: TEXCOORD0;
	float4 world_normal				: TEXCOORD1; //xyz: normal | w: Exposure compensation
	float4 tex_coord				: TEXCOORD2;
	float4 world_tangent			: TEXCOORD4;
#if PARTICLE_SHADING
#if SPRITE_BLENDING
	float3 tex_coord_2 : TEXCOORD3;
#endif
	nointerpolation uint particle_index : PARTICLE_INDEX;
	nointerpolation uint emitter_index  : EMITTER_INDEX;
#endif
	nointerpolation uint instanceID		: INSTANCE_ID;
};

struct VS_OUTPUT_TD
{
	float4 Pos : RGL_POSITION;
	float4 Color : COLOR0;
	float2 Tex0 : TEXCOORD0;
	float4 world_position : TEXCOORD1;
};

struct VS_OUT_POSTFX
{
	float4 position : RGL_POSITION;
	float4 Color : COLOR0;
	float2 Tex : TEXCOORD0;
};

struct VS_OUTPUT_NOTEXTURE
{
	float4 position : RGL_POSITION;
	float4 color : COLOR0;
};

struct VS_OUTPUT_FULLSCREEN_QUAD
{
	float4 position : RGL_POSITION;
	float2 tex_coord : TEXCOORD0;
};

struct VS_OUTPUT_FONT
{
	float4 Pos : RGL_POSITION;
	float4 Color : COLOR0;
	float2 Tex0 : TEXCOORD0;
	float3 Dist : COLOR1;
};

struct VS_OUTPUT_DEFERRED_DECAL
{
	float4 position : RGL_POSITION;
	float4 ClipSpacePos : TEXCOORD0;
	float4 world_position : TEXCOORD1;
	float4 vertex_color : TEXCOORD2;
	float4 tex_coord : TEXCOORD3;
	float4 world_normal : TEXCOORD4;
};

struct VS_OUTPUT_PLANE
{
	float4 position : RGL_POSITION;
	float2 DistanceAndCrest : COLOR0;
	float4 OriginalWorldPos : COLOR1;
	float3 WorldPos : COLOR2;
};

struct VS_OUTPUT_HORIZON
{
	float4 Pos : RGL_POSITION;
	float4 Color : COLOR0;
	float2 Tex0 : TEXCOORD0;
	float3 world_position : TEXCOORD1;

};

struct HS_CONSTANT_DATA_OUTPUT_PLANE
{
	float edges[3]: SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct PS_OUTPUT
{
	float4 RGBColor : RGL_COLOR0;
};

struct PS_OUTPUT_BAKE_HEIGHT_TERRAIN_DATA
{
	float height : RGL_COLOR0;
};

struct PS_OUTPUT_BAKE_COLOR_TERRAIN_DATA
{
	float shadow : RGL_COLOR0;

#if !USE_VISTA_DIFFUSE
	float4 baked_data : RGL_COLOR1;
#endif
};

struct PS_OUTPUT_GBUFFER
{
	float4 gbuffer_albedo_thickness : RGL_COLOR0;
	float4 gbuffer_spec_gloss_ao_shadow : RGL_COLOR1;
	float4 gbuffer_normal_xy_dummy_alpha : RGL_COLOR2;
	float2 gbuffer_vertex_normal_xy : RGL_COLOR3;

#if SYSTEM_WRITE_MOTION_VECTORS
	float2 gbuffer_motion_vector : RGL_COLOR4; 	// rg = screen space motion vector, ba = empty for now
#endif

#if USE_VIRTUAL_TEXTURING
	float4 vt_resolve : RGL_COLOR5;
#endif

#if SYSTEM_DRAW_ENTITY_IDS
	uint2 entity_id : RGL_COLOR6;
#endif

#if defined(SPEEDTREE_BILLBOARD)
#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(CONSTANT_OUTPUT_PASS)
	float depth : SV_Depth;
#endif
#endif
};

struct PS_OUTPUT_WATER
{
#if DEPTH_ONLY_INTERNAL
	float4 gbuffer_normal_xy_dummy_alpha : RGL_COLOR0;
#else
	float4 RGBColor : RGL_COLOR0;
#endif
};

struct PS_OUTPUT_DECAL
{
	float4 color1 : RGL_COLOR0;	//normal.xy, depth
	float4 albedo : RGL_COLOR1;	//albedo.rgba
	float4 specularity : RGL_COLOR2;	//specular color, gloss, materialID, alpha
};

struct VS_OUTPUT_MISSILE_TRAIL
{
	float4 Pos : RGL_POSITION;
	float2 Tex0 : TEXCOORD0;

	float4 WorldPos : WorldPos;
	float4 CamDirWS : CamDir;
	float4 CamPosW : CamPos;
};

struct VS_OUTPUT_MISSILE
{
	float4 ScrPos : RGL_POSITION;
	float2 Tex0 : TEXCOORD0;

	float4 WorldPos : WorldPos;
	float4 CamDirWS : CamDir;
};

struct VS_OUTPUT_HELPERICON
{
	float4 position : RGL_POSITION;
	float4 vertex_color : COLOR0;
	float2 tex_coord : TEXCOORD0;
	float4 world_position : TEXCOORD1;
};

struct VS_OUTPUT_STANDART_CONTOUR
{
	float4 position						: RGL_POSITION;	

	float4 vertex_color					: COLOR0;
	float4 world_position				: TEXCOORD0;
	float4 world_normal					: TEXCOORD1;

	float2 tex_coord					: TEXCOORD2;
	
	#if USE_TESSELATION
		float vertex_distance_factor 	:TEXCOORD7;
	#endif

	float4 object_space					: TEXCOORD8;
};

struct VS_OUTPUT_STANDART_GPU_PARTICLE
{
	float4 position					: RGL_POSITION;	
	float4 vertex_color				: COLOR0;
	float4 world_position			: TEXCOORD0;
	float4 world_normal				: TEXCOORD1;
	#if VDECL_HAS_DOUBLEUV
	float4 tex_coord				: TEXCOORD2;
	#else
	float2 tex_coord				: TEXCOORD2;
	#endif
	float4 shadow_tex_coord			: TEXCOORD3;
	float4 dynamic_shadow_tex_coord	: TEXCOORD4;

	#if VDECL_HAS_TANGENT_DATA
	float4 world_tangent			: TEXCOORD5;	//TODO_SHADERS: float3 is enough
	float4 world_binormal			: TEXCOORD6;
	#endif // VDECL_HAS_TANGENT_DATA
};
struct VS_OUTPUT_SHADOWMAP
{
	float4 Pos          : RGL_POSITION;
	float2 Tex0			: TEXCOORD0;
	float3 WorldPos		: TEXCOORD1;
};

struct VS_OUTPUT_DEFERRED_LIGHT
{
	float4 Pos          : RGL_POSITION;
	float4 ClipSpacePos		: TEXCOORD0;
	float4 WorldSpacePos	: TEXCOORD1;
};

struct VS_OUTPUT_SKYBOX
{
	float4 Pos				: RGL_POSITION;
	float4 Color			: COLOR0;
	float2 Tex0				: TEXCOORD0;
	float4 fog_position		: TEXCOORD1;
	float4 render_position	: TEXCOORD2;
#if ENABLE_DYNAMIC_INSTANCING || defined(OVERDRAW_PASS)
	uint instanceID : SV_InstanceID;
#endif
};

struct VS_OUTPUT_TEXTURE_BAKE
{
	float4 position			:	RGL_POSITION;
	float2 tex_coord		:	TEXCOORD0;
	float3 world_normal		:	TEXCOORD1;
	float4 vertex_color		:	COLOR0;
	float alpha_ref			: TEXCOORD5;

#if VDECL_HAS_TANGENT_DATA
	float4 world_tangent			: TEXCOORD2;
#endif 

#if ENABLE_DYNAMIC_INSTANCING
	RGL_NO_INTERPOLATION int instanceID : TEXCOORD10;
#endif

#if defined(PIXEL_SHADER) && SYSTEM_TWO_SIDED_RENDER
	bool is_fronface : SV_IsFrontFace;
#endif
};

struct VS_OUTPUT_FALLBACK 
{
	float4 position_					: RGL_POSITION;	
};

#endif // MODULAR_STRUCT_DEFINITIONS_RSH
