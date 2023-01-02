
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "gpu_particle.rsh"

VS_OUTPUT_STANDART main_vs(RGL_VS_INPUT input)
{
	return main_vs_gpu(input);
}

PS_OUTPUT main_ps(VS_OUTPUT_STANDART input)
{
	return main_ps_gpu(input);
}


