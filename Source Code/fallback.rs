#include "../shader_configuration.h"

#define Pixel_shader_input_type VS_OUTPUT_FALLBACK

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "modular_struct_definitions.rsh"

#if VERTEX_DECLARATION == VDECL_EMPTY
VS_OUTPUT_FALLBACK main_vs(uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
#else
VS_OUTPUT_FALLBACK main_vs(RGL_VS_INPUT input)
#endif
{
	VS_OUTPUT_FALLBACK output;
#if VERTEX_DECLARATION == VDECL_EMPTY
	output.position_ = 1;
#else
	output.position_ = float4(input.position.xyz,1);
#endif
	return output;
}

PS_OUTPUT main_ps(VS_OUTPUT_FALLBACK input)
{
	PS_OUTPUT output;
	output.RGBColor = float4(1,0,1,1);
	return output;
}
