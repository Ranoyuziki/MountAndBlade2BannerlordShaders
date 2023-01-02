
#include "flora.rsh"

VS_OUTPUT_STANDART main_vs(RGL_VS_INPUT In)
{
	return vs_flora_gbuffer(In);
}
	
PS_OUTPUT main_ps(VS_OUTPUT_STANDART In)
{
	return ps_flora_gbuffer(In);
}
