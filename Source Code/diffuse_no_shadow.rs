

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "standart.rsh"
#include "ui_shaders.rsh"


struct VS_OUTPUT_DEFAULT 
{
	float4 position					: RGL_POSITION;	
	float2 tex_coord				: TEXCOORD1;	
};

#if VERTEX_SHADER
VS_OUTPUT_DEFAULT main_vs(RGL_VS_INPUT input)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_DEFAULT, Out);

	float4 object_position, object_tangent;
	float3 object_normal;
	float3 prev_object_position, object_color;

	#if (VERTEX_DECLARATION != VDECL_POSTFX)
	rgl_vertex_transform(input, object_position, object_normal, object_tangent, prev_object_position, object_color);
	#else
		object_position = float4(input.position.xyz,1);
	#endif

	Out.position = mul(g_view_proj, mul(g_world, object_position));
	
	#if (VERTEX_DECLARATION != VDECL_POSTFX)
	Out.tex_coord.xy = input.tex_coord.xy;
	#else
		Out.tex_coord.xy = input.position.xy * 0.5 + 0.5;
	#endif
	
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_DEFAULT In)
{
	PS_OUTPUT Output;
	Output.RGBColor.rgb = sample_diffuse_texture(point_sampler, In.tex_coord).rgb;
	Output.RGBColor.a = 1;

	return Output;
}
#endif
