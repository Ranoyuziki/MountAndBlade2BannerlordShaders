#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"
#include "shared_pixel_functions.rsh"

struct VS_OUTPUT_GIZMO
{
	float4 Pos : RGL_POSITION;
	float4 Color : COLOR0;
	float3 Normal : COLOR1;
	float2 Tex0 : TEXCOORD0;
	float3 ViewPos : COLOR2;
};


VS_OUTPUT_GIZMO main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_GIZMO Out = (VS_OUTPUT_GIZMO)0;

	Out.Pos = mul(g_view_proj, mul(g_world, float4(In.position * g_mesh_vector_argument.y, 1)));
	Out.ViewPos = mul(g_view, mul(g_world, float4(In.position, 0))).xyz;
	float4 qtangent = normalize(In.qtangent);
	float3 normal = quat_to_mat_zAxis(qtangent);
	Out.Normal = mul(g_view, mul(g_world, float4(normal, 0))).xyz;
	Out.Tex0 = In.tex_coord;
	Out.Color = get_vertex_color(In.color) * g_mesh_factor_color;
	INPUT_TEX_GAMMA(Out.Color);

	return Out;
}


PS_OUTPUT main_ps(VS_OUTPUT_GIZMO In)
{
	PS_OUTPUT Output;

#if SPHERE
	float3 color = In.Color.xyz;
	float ndotl = min(saturate(dot(In.Normal, normalize(float3(1, 0, 1)))) + 0.7, 1.0);
	color = saturate(color * ndotl);
	Output.RGBColor = float4(color, In.Color.w);
#elif PLANE
	Output.RGBColor = float4(In.Color.xyz, 0.3);
	//dithered_fade_out(In.Pos.xy * g_application_halfpixel_viewport_size_inv.xy * 2, 0.5);
#else
	float3 color = In.Color.rgb;
	if (g_mesh_vector_argument.x < 0.5)
	{
		if (In.ViewPos.z < 0) clip(-1);
	}
	if (g_mesh_vector_argument.z > 0.5)
	{
		float ndotl = min(saturate(dot(In.Normal, normalize(float3(1, 0, 1)))) + 0.5, 1.0);
		color = saturate(color * ndotl);
	}

	Output.RGBColor = float4(color, 1);
#endif
	return Output;
}
