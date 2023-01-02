
#define GBUFFER_PASS
#define Vertex_shader_output_type VS_OUT_GBUFFER_SKYBOX
#define Pixel_shader_input_type VS_OUT_GBUFFER_SKYBOX

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "definitions_samplers.rsh"
#include "modular_struct_definitions.rsh"
#include "gbuffer_functions.rsh"
#include "motion_vector.rsh"

#if VERTEX_SHADER
VS_OUT_GBUFFER_SKYBOX main_vs(RGL_VS_INPUT In)
{
	VS_OUT_GBUFFER_SKYBOX Output;
	float4x4 cam_origined_world_mat = g_world;
	cam_origined_world_mat[0][3] = g_camera_position.x;
	cam_origined_world_mat[1][3] = g_camera_position.y;
	cam_origined_world_mat[2][3] = g_camera_position.z;

	float4 fog_world_position = mul(cam_origined_world_mat, float4(In.position, 1.0f));

	float4 render_world_position = fog_world_position;
	/**/
	{
		//render_world_position = float4(g_camera_position.xyz + In.position, 1.0f); -> we should apply g_world rotation to support sun heading!
		float4x4 render_frame = g_world;
		render_frame._m00_m10_m20 = normalize(render_frame._m00_m10_m20);
		render_frame._m01_m11_m21 = normalize(render_frame._m01_m11_m21);
		render_frame._m02_m12_m22 = normalize(render_frame._m02_m12_m22);
		render_frame._m03_m13_m23 = g_camera_position.xyz;

		render_world_position = mul(render_frame, float4(In.position, 1.0f));	
	}

	Output.position = mul(g_view_proj, render_world_position);
	Output.world_position = render_world_position;
	
	#if USE_DEPTH_BUFFER_FLIPPING
		Output.position.z = 1e-30;
	#else
		Output.position.z = Output.position.w;
	#endif
	
	Output.tex_coord = In.tex_coord;
	if(In.position.z < 0)
	{
		Output.tex_coord.y = 1;
	}

#if ENABLE_DYNAMIC_INSTANCING
	Output.instanceID = In.instanceID;
#endif

	return Output;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT_GBUFFER main_ps(Pixel_shader_input_type In)
{
	PS_OUTPUT_GBUFFER Output = (PS_OUTPUT_GBUFFER)0.0;

	float cloud_rotation = g_mesh_vector_argument_2.x;
	float4 albedo = sample_diffuse2_texture(In.tex_coord.xy + float2(cloud_rotation, 0));
	INPUT_TEX_GAMMA(albedo.rgb);
	float cloud_val = albedo.a;
	
	set_gbuffer_values(Output, float3(0,0,1), 1, albedo.xyz, float2(0, 0), 1, float3(0,0,1), 0, 0);
	
	set_gbuffer_camera_motion_vector(In, Output);

	return Output;
}
#endif
