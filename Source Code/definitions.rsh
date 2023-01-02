#ifndef DEFINITIONS_RSH
#define DEFINITIONS_RSH

#ifdef __PSSL__
#pragma warning (disable: 20087) // unreferenced formal parameter
#pragma warning (disable: 20088) // unreferenced local variable
#endif

#include "../shader_configuration.h"	// source code dependent configuration definitions..

#ifdef RGL_USE_VIRTUAL_TEXTURING

#define GRA_TEXTURE_ARRAY_SUPPORT 1
#define GRA_PACK_RESOLVE_OUTPUT 0
#define GRA_RWTEXTURE2D_SCALE 16
#define GRA_NUM_LAYERS 4	// This sample only uses 1 layer
#define GRA_BGRA 0			// We use RGBA format
#define GRA_ROW_MAJOR 1		// We use row major matrices
#define GRA_DEBUG 0	// Disable debug output
#define GRA_DEBUG_TILES 0	// Disable visual debug output

#ifdef USE_64_BIT_RESOLVER_GRANITE
#define GRA_64BIT_RESOLVER 1
#endif

#ifdef USE_GNM
#include "GraniteShaderLibPSSL.h"
#else
#define GRA_HLSL_5 1		// Enable HLSL 5 syntax
#include "GraniteShaderLib3_src.h"
#endif

#endif

#ifdef __PSSL__
#include "hlsl_to_pssl.rsh"
#endif

#include "flagDefs.rsh"

#ifdef USE_DIRECTX12
#include "root_signature.rsh"
#endif

#define INDEX_EPSILON 0.1f

#if !defined(USE_DIRECTX11) && !defined(USE_DIRECTX12) && !defined(USE_GNM)
#error "Build target is not specified!"
#endif

#define rgl_max_terrain_layers 16

#if BAKE_TERRAIN_COLOR
		#define PS_OUTPUT_TO_USE PS_OUTPUT_BAKE_COLOR_TERRAIN_DATA

		#ifdef __PSSL__
			#pragma PSSL_target_output_format(target 0 FMT_FP16_ABGR)
			#pragma PSSL_target_output_format(target 1 FMT_FP16_ABGR)
		#endif
#elif BAKE_TERRAIN_HEIGHT
		#define PS_OUTPUT_TO_USE PS_OUTPUT_BAKE_HEIGHT_TERRAIN_DATA

		#ifdef __PSSL__
			#pragma PSSL_target_output_format(target 0 FMT_UNORM16_ABGR)
		#endif
#else
	#define PS_OUTPUT_TO_USE PS_OUTPUT	
#endif

#define USE_OBJECT_SPACE_TANGENT (VDECL_HAS_TANGENT_DATA && !SYSTEM_CLOTH_SIMULATION_ENABLED)

#define PACK_DEPTH_CONSTANT (300.0)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// API SPECIFIC STUFF 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#if defined(USE_DIRECTX11) || defined(USE_DIRECTX12)

#define RGL_POSITION SV_POSITION
#define RGL_COLOR0 SV_TARGET0
#define RGL_COLOR1 SV_TARGET1
#define RGL_COLOR2 SV_TARGET2
#define RGL_COLOR3 SV_TARGET3
#define RGL_COLOR4 SV_TARGET4
#define RGL_COLOR5 SV_TARGET5
#define RGL_COLOR6 SV_TARGET6 // used in editor mode only, for entity IDs
#define RGL_NO_INTERPOLATION nointerpolation

#elif defined(USE_GNM)

#define RGL_POSITION S_POSITION
#define RGL_COLOR0 S_TARGET_OUTPUT0
#define RGL_COLOR1 S_TARGET_OUTPUT1
#define RGL_COLOR2 S_TARGET_OUTPUT2
#define RGL_COLOR3 S_TARGET_OUTPUT3
#define RGL_COLOR4 S_TARGET_OUTPUT4
#define RGL_COLOR5 S_TARGET_OUTPUT5
#define RGL_COLOR6 S_TARGET_OUTPUT6
#define RGL_NO_INTERPOLATION nointerp

#else

#error "Not supported"

#endif



#define INITIALIZE_OUTPUT(structure, var)	structure var = (structure)0;

#define CONSTANT_IF if
#define CONSTANT_ELSE else
#define DYNAMIC_IF if
#define DYNAMIC_ELSE else

static const float MAX_SKYACCESS_HEIGHT = 30.0;
static const float MAX_HEIGHTMAP_VALUE = 500.0;
static const float MIN_HEIGHTMAP_VALUE = -100.0;

static const float3 LUMINANCE_WEIGHTS = float3(0.27f, 0.67f, 0.06f);

static const float RGL_TWO_PI = 6.28318530;
static const float RGL_PI = 3.14159265;
static const float RGL_PI_OVER_TWO = 1.57079632;
static const float RGL_PI_OVER_FOUR = 0.78539816;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/* Shared Macros */

//using gamma 2.0 for textures..
#define INPUT_TEX_GAMMA(col_rgb) (col_rgb) = ((col_rgb) * ((col_rgb) * ((col_rgb) * 0.305306011 + 0.682171111) + 0.012522878));

#if RENDERING_TO_SCREEN
#define OUTPUT_GAMMA(col_rgb) (col_rgb) = pow(col_rgb, g_output_gamma_inv)	
#else
void OUTPUT_GAMMA(inout float3 col_rgb)
{
	float3 S1 = sqrt(col_rgb);
	float3 S2 = sqrt(S1);
	float3 S3 = sqrt(S2);
	col_rgb.xyz = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * col_rgb.xyz;
}

void OUTPUT_GAMMA(inout float4 col_rgb)
{
	float4 S1 = sqrt(col_rgb);
	float4 S2 = sqrt(S1);
	float4 S3 = sqrt(S2);
	col_rgb.xyzw = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * col_rgb.xyzw;
}

void OUTPUT_GAMMA(inout float2 col_rgb)
{
	float2 S1 = sqrt(col_rgb);
	float2 S2 = sqrt(S1);
	float2 S3 = sqrt(S2);
	col_rgb = 0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * col_rgb;
}

#endif

float3 output_gamma_smaa(float3 col_rgb)
{
	float3 S1 = sqrt(col_rgb);
	float3 S2 = sqrt(S1);
	float3 S3 = sqrt(S2);
	return (0.662002687 * S1 + 0.684122060 * S2 - 0.323583601 * S3 - 0.0225411470 * col_rgb.xyz);
}

#define dispatch_indirect(buf, offset, num_x, num_y, num_z) \
								{ \
									uint data_offset = (offset) * 8; \
									buf[data_offset + 0] = num_x; \
									buf[data_offset + 1] = num_y; \
									buf[data_offset + 2] = num_z; \
									buf[data_offset + 3] = 0; \
									buf[data_offset + 4] = 0; \
									buf[data_offset + 5] = 0; \
									buf[data_offset + 6] = 0; \
									buf[data_offset + 7] = 0; \
								}

#define draw_indirect(buf, offset, num_vert, num_inst, first_vert, first_inst) \
								{ \
									uint data_offset = (offset) * 8; \
									buf[data_offset + 0] = num_vert; \
									buf[data_offset + 1] = num_inst; \
									buf[data_offset + 2] = first_vert; \
									buf[data_offset + 3] = first_inst; \
									buf[data_offset + 4] = 0; \
									buf[data_offset + 5] = 0; \
									buf[data_offset + 3] = 0; \
									buf[data_offset + 7] = 0; \
								}

#define draw_indexed_indirect(buf, offset, num_indices, num_inst, first_index, first_vert, first_inst) \
								{ \
									uint data_offset = (offset) * 8; \
									buf[data_offset + 0] = num_indices; \
									buf[data_offset + 1] = num_inst; \
									buf[data_offset + 2] = first_index; \
									buf[data_offset + 3] = first_vert; \
									buf[data_offset + 4] = first_inst; \
									buf[data_offset + 5] = 0; \
									buf[data_offset + 6] = 0; \
									buf[data_offset + 7] = 0; \
								}


#include "definitions_input_layouts.rsh"
#include "definitions_helper_macros.rsh"
#include "definitions_shader_resource_views.rsh"
#include "definitions_unordered_access_views.rsh"
#include "definitions_constant_buffers.rsh"
#include "definitions_samplers.rsh"

#endif // DEFINITIONS_RSH
