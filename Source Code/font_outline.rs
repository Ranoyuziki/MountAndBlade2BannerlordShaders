#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

#ifdef VERTEX_SHADER
VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	return vs_font(In);
}
#endif

#ifdef PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	return ps_font_outline(In);
}
#endif
