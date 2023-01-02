#include "definitions.rsh"

struct VS_OUTPUT_TEST
{
	float4 position : RGL_POSITION;
	float4 Color : COLOR0;
	float2 Tex0 : TEXCOORD0;
	float3 WorldPos : COLOR1;
	float3 Normal : COLOR2;
};

#define Pixel_shader_input_type VS_OUTPUT_TEST
#include "math_conversions.rsh"
#include "ambient_functions.rsh"
#include "atmosphere_functions.rsh"
#include "shared_pixel_functions.rsh"

VS_OUTPUT_TEST main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_TEST Out;

	float4 world_pos = float4(In.position, 1);
	Out.WorldPos = world_pos.xyz;
	Out.position = mul(g_view_proj, mul(g_world, world_pos));
	Out.Color = float4(1, 1, 1, 1);
	Out.Normal = float3(0, 0, 1);
	Out.Tex0 = In.tex_coord;
	return Out;
}

float3 get_world_pos(in float hw_depth, in float2 uv)
{
	float x = uv.x * 2 - 1;
	float y = (1.0 - uv.y) * 2.0 - 1.0;

	float4 position_ws = mul(g_view_proj_inverse, float4(x, y, hw_depth, 1.0));
	position_ws.xyz /= position_ws.w;

	return position_ws.xyz;
}


PS_OUTPUT main_ps(VS_OUTPUT_TEST In)
{
	PS_OUTPUT Output = (PS_OUTPUT)0;

	float2 ss_pos = In.position.xy * g_application_halfpixel_viewport_size_inv.zw;
	float hw_depth = depth_texture.SampleLevel(point_sampler, In.position.xy / g_application_viewport_size.xy, 0).r;
	
	float3 world_pos = get_world_pos(hw_depth, ss_pos);
	float2 base_uv = world_pos.xy / g_mesh_vector_argument.zw;
	clip(base_uv.x);
	clip(1 - base_uv.x);
	clip(base_uv.y);
	clip(1 - base_uv.y);
	base_uv.y = 1-base_uv.y;

	float index = texture0.SampleLevel(point_sampler, base_uv, 0).r;
	float index_unorm = frac(index * 255.0 * 1.618);
	float4 color = float4(hsv2rgb(float3(index_unorm, 0.8, 0.5 + frac(1 - (index * 8)) * 0.5)), g_mesh_vector_argument.x);

	uint cur_frame = (uint)(index * 255);
	if (cur_frame == 255) clip(-1);
	uint cur_frame_x = cur_frame % 16;
	uint cur_frame_y = cur_frame / 16;
	float2 uv = base_uv * g_mesh_vector_argument_2.x;
	uv = fmod(uv, 1.0f / 16.0f);
	float2 finuv = uv + float2(cur_frame_x / 16.0f, cur_frame_y / 16.0f);

	float enum_color = texture1.Sample(anisotropic_sampler, finuv).r * g_mesh_vector_argument.y;
	color = lerp(color, 1, enum_color);

	INPUT_TEX_GAMMA(color.xyz);

	Output.RGBColor.xyzw = color;
	return Output;
}
