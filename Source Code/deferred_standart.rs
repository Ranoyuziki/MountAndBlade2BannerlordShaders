
#include "deferred_standart.rsh"

VS_OUT_POSTFX main_vs(RGL_VS_INPUT In)
{
	return main_vs_deferred_terrain(In);
}

PS_OUTPUT main_ps(VS_OUT_POSTFX In)
{
	PS_OUTPUT Output;
	Output.RGBColor.rgb = main_ps_deferred_standart(In);
	Output.RGBColor.a = 1;
	return Output;
}
