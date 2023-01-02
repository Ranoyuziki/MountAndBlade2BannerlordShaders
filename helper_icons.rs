#include "definitions.rsh"
#include "modular_struct_definitions.rsh"
#include "definitions_texture_sample_helpers.rsh"

#if VERTEX_SHADER
VS_OUTPUT_HELPERICON main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_HELPERICON Out = (VS_OUTPUT_HELPERICON)0;
	Out.position = float4(In.position, 1.0f);
	Out.vertex_color = In.color;
	Out.tex_coord = In.tex_coord;
	Out.world_position = 0.0f;
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_HELPERICON In)
{
	PS_OUTPUT Output;
	Output.RGBColor = sample_diffuse_texture(anisotropic_sampler, In.tex_coord) * In.vertex_color;
	clip(Output.RGBColor.a - 0.5);
	return Output;
}
#endif
