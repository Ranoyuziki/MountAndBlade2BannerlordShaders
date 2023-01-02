
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "map_water.rsh"

VS_OUTPUT_MAP_WATER main_vs(RGL_VS_INPUT In)
{
	return vs_map_water(false, In);
}

PS_OUTPUT main_ps(VS_OUTPUT_MAP_WATER In)
{
	return ps_map_water(false, false, false, In);
}
