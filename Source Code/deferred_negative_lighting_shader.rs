
#include "shared_functions.rsh"
#include "gbuffer_functions.rsh"         
#include "deferred_negative_lighting.rsh"

#if VERTEX_SHADER
VS_OUTPUT_DEFERRED_LIGHT main_vs(RGL_VS_INPUT In)
{
	return deferred_negative_light_vs(In);
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_DEFERRED_LIGHT In)
{ 
	return deferred_negative_light_ps(In, false);
}      
#endif
