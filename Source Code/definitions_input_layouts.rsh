#ifndef DEFINITIONS_INPUT_LAYOUTS_RSH
#define DEFINITIONS_INPUT_LAYOUTS_RSH

#include "definitions_shader_resource_indices.rsh"

#define VDECL_REGULAR					il_regular
#define VDECL_BUMP						il_normal_map
#define VDECL_SKINNING					il_skinning
#define VDECL_SKINNING_BUMP				il_normal_map_skinning
#define VDECL_REGULAR_DOUBLEUV			il_regular_doubleuv
#define VDECL_BUMP_DOUBLEUV				il_normal_map_doubleuv
#define VDECL_SKINNING_DOUBLEUV			il_skinning_doubleuv
#define VDECL_SKINNING_BUMP_DOUBLEUV	il_normal_map_skinning_doubleuv
#define VDECL_POSTFX					il_postfx
#define VDECL_DEPTH_ONLY				il_depth_only
#define VDECL_DEPTH_ONLY_WITH_ALPHA		il_depth_only_with_alpha
#define VDECL_EMPTY						il_empty

#ifndef VERTEX_DECLARATION
	#error "VERTEX_DECLARATION is not defined!"
#endif

#define VDECL_HAS_SKIN_DATA ((VERTEX_DECLARATION == VDECL_SKINNING) || (VERTEX_DECLARATION == VDECL_SKINNING_BUMP) \
							|| (VERTEX_DECLARATION == VDECL_SKINNING_DOUBLEUV) || (VERTEX_DECLARATION == VDECL_SKINNING_BUMP_DOUBLEUV))

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS)
#define VDECL_HAS_TANGENT_DATA ((VERTEX_DECLARATION == VDECL_BUMP) || (VERTEX_DECLARATION == VDECL_SKINNING_BUMP)  \
								|| (VERTEX_DECLARATION == VDECL_BUMP_DOUBLEUV) || (VERTEX_DECLARATION == VDECL_SKINNING_BUMP_DOUBLEUV))
#else
#define VDECL_HAS_TANGENT_DATA 0
#endif

#define VDECL_HAS_NORMAL_DATA ((VERTEX_DECLARATION != VDECL_DEPTH_ONLY) && (VERTEX_DECLARATION != VDECL_DEPTH_ONLY_WITH_ALPHA) \
	&& (VERTEX_DECLARATION != VDECL_POSTFX) && (VERTEX_DECLARATION != VDECL_EMPTY)) && (VERTEX_DECLARATION != VDECL_SKINNING)

#define VDECL_IS_DEPTH_ONLY ((VERTEX_DECLARATION == VDECL_DEPTH_ONLY_WITH_ALPHA) || (VERTEX_DECLARATION == VDECL_DEPTH_ONLY))

#if VDECL_IS_DEPTH_ONLY
#undef VDECL_HAS_TANGENT_DATA
#define VDECL_HAS_TANGENT_DATA 0
#endif

#define VDECL_HAS_DOUBLEUV ((VERTEX_DECLARATION == VDECL_REGULAR_DOUBLEUV) || (VERTEX_DECLARATION == VDECL_BUMP_DOUBLEUV) || (VERTEX_DECLARATION == VDECL_SKINNING_DOUBLEUV) || (VERTEX_DECLARATION == VDECL_SKINNING_BUMP_DOUBLEUV))

struct Vertex_elements_regular
{
	float3 position : POSITION;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD;
	float4 qtangent : TANGENT;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_empty
{
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_normal_map
{
	float3 position : POSITION;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD;
	float4 qtangent : TANGENT;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_skinning
{
	float4 position : POSITION;
	uint normal : NORMAL;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_normal_map_skinning
{
	float4 position : POSITION;
	uint normal : NORMAL;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD;
	float4 qtangent : TANGENT;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_regular_doubleuv
{
	float3 position : POSITION;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD0;
	float2 tex_coord2 : TEXCOORD1;
	float4 qtangent : TANGENT;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_normal_map_doubleuv
{
	float3 position : POSITION;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD0;
	float2 tex_coord2 : TEXCOORD1;
	float4 qtangent : TANGENT;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_skinning_doubleuv
{
	float4 position : POSITION;
	uint normal : NORMAL;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD0;
	float2 tex_coord2 : TEXCOORD1;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_normal_map_skinning_doubleuv
{
	float4 position : POSITION;
	uint normal : NORMAL;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD0;
	float2 tex_coord2 : TEXCOORD1;
	float4 qtangent : TANGENT;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_terrain
{
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_postfx
{
	float3 position : POSITION;
	float4 color : COLOR0;
	uint vertex_id : SV_VertexID;
};

struct Vertex_elements_debug_font
{
	float4 position : POSITION;
	float4 color : COLOR0;
	uint vertex_id : SV_VertexID;
};

struct Vertex_elements_depth_only
{
	float3 position : POSITION;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct Vertex_elements_depth_only_with_alpha
{
	float3 position : POSITION;
	float2 tex_coord : TEXCOORD0;
	uint vertex_id : SV_VertexID;
	uint instanceID : SV_InstanceID;
};

struct VS_Output
{
	float4 position : RGL_POSITION;
	float3 normal : NORMAL;
	float4 color : COLOR0;
	float2 tex_coord : TEXCOORD;
};

#if (VERTEX_DECLARATION == VDECL_REGULAR)
#define RGL_VS_INPUT Vertex_elements_regular
#elif (VERTEX_DECLARATION == VDECL_BUMP)
#define RGL_VS_INPUT Vertex_elements_normal_map
#elif (VERTEX_DECLARATION == VDECL_SKINNING)
#define RGL_VS_INPUT Vertex_elements_skinning
#elif (VERTEX_DECLARATION == VDECL_SKINNING_BUMP)
#define RGL_VS_INPUT Vertex_elements_normal_map_skinning
#elif (VERTEX_DECLARATION == VDECL_REGULAR_DOUBLEUV)
#define RGL_VS_INPUT Vertex_elements_regular_doubleuv
#elif (VERTEX_DECLARATION == VDECL_BUMP_DOUBLEUV)
#define RGL_VS_INPUT Vertex_elements_normal_map_doubleuv
#elif (VERTEX_DECLARATION == VDECL_SKINNING_DOUBLEUV)
#define RGL_VS_INPUT Vertex_elements_skinning_doubleuv
#elif (VERTEX_DECLARATION == VDECL_SKINNING_BUMP_DOUBLEUV)
#define RGL_VS_INPUT Vertex_elements_normal_map_skinning_doubleuv
#elif (VERTEX_DECLARATION == VDECL_POSTFX)
#define RGL_VS_INPUT Vertex_elements_postfx
#elif (VERTEX_DECLARATION == VDECL_DEPTH_ONLY)
#define RGL_VS_INPUT Vertex_elements_depth_only
#elif (VERTEX_DECLARATION == VDECL_DEPTH_ONLY_WITH_ALPHA)
#define RGL_VS_INPUT Vertex_elements_depth_only_with_alpha
#elif (VERTEX_DECLARATION == VDECL_EMPTY)
#define RGL_VS_INPUT Vertex_elements_empty
#endif

#endif // DEFINITIONS_INPUT_LAYOUTS_RSH
