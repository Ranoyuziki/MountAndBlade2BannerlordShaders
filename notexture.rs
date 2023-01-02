
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "modular_struct_definitions.rsh"

#if VERTEX_SHADER
VS_OUTPUT_NOTEXTURE main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_NOTEXTURE Out;

	Out.position = mul(g_view_proj, mul(g_world, float4(In.position.xyz, 1.0f)));
#if !(VERTEX_DECLARATION == VDECL_DEPTH_ONLY)
	Out.color = get_vertex_color(In.color) * g_mesh_factor_color;
#endif
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_NOTEXTURE In) 
{ 
	PS_OUTPUT Output;
	Output.RGBColor = In.color;
	Output.RGBColor.rgb = Output.RGBColor.rgb;
	return Output;
}
#endif
