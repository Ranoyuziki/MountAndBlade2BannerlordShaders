#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

#if PIXEL_SHADER
VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	In.tex_coord.xy = In.tex_coord.xy * g_mesh_vector_argument.xy + g_mesh_vector_argument.zw;
	return vs_font(In);
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	//PS_OUTPUT output;
	//output.RGBColor = float4(1, 0, 1, 1);
	//return output;
	
	return ps_no_shading(In);
}
#endif
