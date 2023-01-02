
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "modular_struct_definitions.rsh"

#include "shared_functions.rsh"
#include "system_postfx.rs"

#if VERTEX_SHADER
VS_OUT_POSTFX main_vs(RGL_VS_INPUT In)
{
	return main_vs_postfx(In);
}
#endif

#if PIXEL_SHADER
float4 BlurFunction(inout float totalweight, float d0, float d, float4 prt)
{
	float w = abs(d - d0) < (0.3) ? 1 : 0;
	totalweight += w;

	return prt * w;
}

float4 main_ps(VS_OUT_POSTFX In) : RGL_COLOR0
{
	float center_depth = hw_depth_to_linear_depth(texture1.SampleLevel(point_clamp_sampler, In.Tex, 0)).r;

	float4 reds = texture0.GatherRed(point_clamp_sampler, In.Tex);
	float4 greens = texture0.GatherGreen(point_clamp_sampler, In.Tex);
	float4 blues = texture0.GatherBlue(point_clamp_sampler, In.Tex);
	float4 alphas = texture0.GatherAlpha(point_clamp_sampler, In.Tex);

	float4 prt0 = float4(reds.x, greens.x, blues.x, alphas.x);
	float4 prt1 = float4(reds.y, greens.y, blues.y, alphas.y);
	float4 prt2 = float4(reds.z, greens.z, blues.z, alphas.z);
	float4 prt3 = float4(reds.w, greens.w, blues.w, alphas.w);
	
	float4 d = hw_depth_to_linear_depth(texture2.GatherRed(linear_clamp_sampler, In.Tex));

	float totalweight = 0;
	float4 totalprt = 0;

	totalprt += BlurFunction(totalweight, center_depth, d.x, prt0);
 	totalprt += BlurFunction(totalweight, center_depth, d.y, prt1);
 	totalprt += BlurFunction(totalweight, center_depth, d.z, prt2);
 	totalprt += BlurFunction(totalweight, center_depth, d.w, prt3);
	
	if (totalweight < 1e-6)
	{
		return float4((prt0 + prt1 + prt2 + prt3) * 0.25);
	}


	return totalprt / totalweight;
}
#endif
