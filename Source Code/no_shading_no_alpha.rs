
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	return vs_font(In);
}

PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	return ps_no_shading_no_alpha(In);
}
