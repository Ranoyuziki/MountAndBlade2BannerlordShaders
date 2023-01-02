
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_FONT result;
	#if USE_DEPTH_BUFFER_FLIPPING
		In.position.z = 1.0f;
	#else
		In.position.z = 0.0f;
	#endif
	result.Pos = float4(In.position,1.0f);
	result.Color = In.color;
	result.Tex0 = In.tex_coord;
	return result;
}

PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	PS_OUTPUT Output;
	Output.RGBColor = sample_diffuse_texture(anisotropic_sampler, In.Tex0) * In.Color;
	return Output;
}
