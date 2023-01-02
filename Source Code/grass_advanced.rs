
#define USE_ADVANCED_FLORA_SHADING

#include "grass.rsh"


VS_OUTPUT_GRASS main_vs(RGL_VS_INPUT In)
{
	return vs_grass(In);
}

PS_OUTPUT main_ps(VS_OUTPUT_GRASS In)
{
	return ps_grass(In);
}
