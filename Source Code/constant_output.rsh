#ifndef CONSTANT_OUTPUT_RSH
#define CONSTANT_OUTPUT_RSH

#include "shared_functions.rsh"

#ifndef Pixel_shader_input_type
	#define Pixel_shader_input_type VS_OUTPUT_STANDART
#endif


PS_OUTPUT main_ps_constant_output(Pixel_shader_input_type input)
{
	PS_OUTPUT Out;
	
	float alpha_value;
	float4 tex_col = sample_diffuse_texture(anisotropic_sampler, input.tex_coord.xy).rgba;
	INPUT_TEX_GAMMA(tex_col.rgb);
	
	alpha_value = input.vertex_color.a;

	if(!HAS_MATERIAL_FLAG(g_mf_do_not_use_alpha))
	{
		alpha_value *= tex_col.a;
	}

	apply_alpha_test(alpha_value);
	Out.RGBColor = g_zero_constant_output ? float4(0, 0, 0, 0) : g_contour_color;
	
	return Out;
}

#endif
