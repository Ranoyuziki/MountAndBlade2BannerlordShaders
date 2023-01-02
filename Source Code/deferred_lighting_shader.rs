#define DEFERRED_LIGHTING
     
#include "definitions.rsh"
#include "deferred_lighting.rsh"

VS_OUTPUT_DEFERRED_LIGHT main_vs(RGL_VS_INPUT In)
{
	return deferred_light_vs(In);
}

PS_OUTPUT main_ps(VS_OUTPUT_DEFERRED_LIGHT In)
{ 
	return deferred_light_ps(In, false, false);
}   
