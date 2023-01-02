
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"

struct VS_OUTPUT_MAP_BORDER
{
	float4 Pos					: RGL_POSITION;	
	float4 Color				: COLOR0;
	float2 Tex0					: TEXCOORD0;
	float4 WorldPos				: TEXCOORD1;
	float3 WorldNormal			: NORMAL;
};

#if VERTEX_SHADER
VS_OUTPUT_MAP_BORDER main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_MAP_BORDER Out;


	Out.Tex0 = In.tex_coord;
	Out.Color = get_vertex_color(In.color) * g_mesh_factor_color;
	Out.WorldPos = mul(g_world, float4(In.position,1));
	Out.Pos = mul(g_view_proj, Out.WorldPos);
	float4 qtangent = normalize(In.qtangent);
	float3 normal = quat_to_mat_zAxis(qtangent);
	Out.WorldNormal = mul(to_float3x3(g_world), normal.xyz).xyz;

	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_MAP_BORDER In)
{ 
	PS_OUTPUT Output;
	float3 dist_vec = g_camera_position.xyz - In.WorldPos.xyz;
	dist_vec.z *= 4;
	float dist_to_cam_sq = dot(dist_vec, dist_vec);
	float camera_normal = dot(In.WorldNormal, dist_vec);
	if(camera_normal > 0 || dist_to_cam_sq < (g_mesh_vector_argument.x * g_mesh_vector_argument.x))
	{
		float dist_to_cam = sqrt(dist_to_cam_sq);
		
		float2 tex_coord = In.Tex0;
		tex_coord.y -= sin(g_time_var * 0.015f);
		tex_coord.x += cos(g_time_var * 0.015f);
		float4 tex_col = sample_diffuse_texture(linear_sampler, tex_coord * 16);
		tex_coord = In.Tex0;
		tex_coord.x -= (g_time_var % 100) / 100;
		tex_coord.y += (g_time_var % 150) / 150;
		float4 tex_col2 = sample_diffuse_texture(linear_sampler, tex_coord * 20);
		//INPUT_TEX_GAMMA(tex_col.rgb);
		
		Output.RGBColor =  In.Color * tex_col * tex_col2;
		
		float visible_distance = g_mesh_vector_argument.x;
		float dist_alpha = camera_normal > 0 ? 1 : smoothstep(0.0, 0.8, (visible_distance - dist_to_cam) / visible_distance);
		
		const float max_height = 200.0f;
		float avg_height = g_mesh_vector_argument.y;

		float height_alpha = smoothstep(0.0, 0.8, (max_height - abs(avg_height - In.WorldPos.z)) / max_height);
		
		Output.RGBColor.a = height_alpha * dist_alpha * .9;

		Output.RGBColor.rgb = Output.RGBColor.grb;
		Output.RGBColor.rgb *= 2.0f;
		
		Output.RGBColor.rgb += 1.0f-Output.RGBColor.a;	//using multiply-mode blending..
		Output.RGBColor.rgb = saturate(Output.RGBColor.rgb);
	}
	else
	{
		Output.RGBColor = float4(0,0,0,0);
		clip(-1);
	}

	return Output;
}
#endif

