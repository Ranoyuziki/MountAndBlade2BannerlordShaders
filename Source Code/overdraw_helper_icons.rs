
#include "../shader_configuration.h"

#include "definitions.rsh"

#if VERTEX_SHADER
VS_OUTPUT_HELPERICON main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_HELPERICON Out;
	Out.position = float4(In.position, 1.0f);
	Out.vertex_color = In.color;
	Out.tex_coord = In.tex_coord;
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_HELPERICON In)
{
	PS_OUTPUT Output;
	Output.RGBColor = float4(1, 0, 1, 1);
	return Output;
}

#endif
