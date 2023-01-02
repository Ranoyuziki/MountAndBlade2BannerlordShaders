

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "contour.rsh"

VS_OUTPUT_STANDART_CONTOUR main_vs(RGL_VS_INPUT input)
{
	return main_vs_contour(input);
}

PS_OUTPUT main_ps(VS_OUTPUT_STANDART_CONTOUR input)
{
	return main_ps_contour(input);
}
