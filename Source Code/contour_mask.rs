
#define CONTOUR_MASK_SHADER


#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "contour.rsh"

VS_OUTPUT_STANDART_CONTOUR main_vs(RGL_VS_INPUT input)
{
	return main_vs_contour(input);
}

//DEFINE_STANDART_DISPLACEMENT_SHADERS	//TODO_MURAT: should use VS_OUTPUT_STANDART rather than VS_OUTPUT_STANDART_CONTOUR!

PS_OUTPUT main_ps(VS_OUTPUT_STANDART_CONTOUR input)
{
	return main_ps_contour(input);
}
