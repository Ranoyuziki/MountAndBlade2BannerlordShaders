#include "../shader_configuration.h"

#include "ui_shaders.rsh"

VS_OUT_POSTFX main_vs(RGL_VS_INPUT In)
{
	VS_OUT_POSTFX result = (VS_OUT_POSTFX)0;
	//In.position.z = 0.0f;
	
	result.position = mul(g_view_proj, mul(g_world, float4(In.position.xyz, 1)));
	result.Color = In.color;
	result.Tex.x = In.position.x;
	result.Tex.y = 1.0 - In.position.y;
	
	return result;
}

PS_OUTPUT main_ps(VS_OUT_POSTFX In)
{	
	PS_OUTPUT result;

	float tex_left = 0;
	float tex_top = 0;
	float tex_right = 1; 
	float tex_bottom = 1;
	float2 viewport_size = 1.0 / g_application_halfpixel_viewport_size_inv.zw;
	float2 video_res = float2(1920, 1080);
	In.Tex = (In.position.xy - 0.5) / float2(viewport_size.x - 1, viewport_size.y - 1);
	In.Tex = (In.Tex / video_res) * float2(video_res.x - 1, video_res.y - 1);
	In.Tex += 0.5 / video_res;

	if (In.Tex.x < tex_left || In.Tex.y < tex_top || In.Tex.x > tex_right || In.Tex.y > tex_bottom) {
		result.RGBColor = float4(1.0f, 0.0f, 1.0f, 1.0f);
	}
	else {
		// Used to prevent pixel bleeding from bilinear sampling of cropped pixels
		float2 uv2 = In.Tex;

		float3 ycbcr =
			float3(texture0.Sample(linear_sampler, uv2).x - 0.0625,
				texture1.Sample(linear_sampler, uv2).x - 0.5,
				texture1.Sample(linear_sampler, uv2).y - 0.5);

		result.RGBColor =
			float4(dot(float3(1.1644f, 0.0f, 1.7927f), ycbcr), // R
				dot(float3(1.1644f, -0.2133f, -0.5329f), ycbcr), // G
				dot(float3(1.1644f, 2.1124f, 0.0f), ycbcr), // B
				1.0f);
	}

	return result;
}

