#define BAKE_NORMALMAP_TEXTURE

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"
#include "texture_bake.rsh"

#if VERTEX_SHADER
VS_OUTPUT_TEXTURE_BAKE main_vs(RGL_VS_INPUT In)
{
	return texture_bake_vs(In);
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_TEXTURE_BAKE In)
{
	return texture_bake_ps(In);
}
#endif
