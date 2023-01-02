         
#include "blob_shadow_shader.rsh"

#if VERTEX_SHADER
VS_OUTPUT_DEFERRED_LIGHT main_vs(RGL_VS_INPUT In)
{
	return blob_shadow_shader_vs(In);
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_DEFERRED_LIGHT In)
{ 
	return blob_shadow_shader_ps(In, false);
}      
#endif
