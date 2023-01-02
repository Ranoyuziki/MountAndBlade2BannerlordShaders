
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"

VS_Output main_vs(uint instanceID : SV_InstanceID, uint vertexID : SV_VertexID)
{
	VS_Output output;
	
	float4 object_position;

	output.position = 1;
	
    output.tex_coord = object_position.xy;

	output.normal = float3(0.0f ,0.0f , 1.0f);
	output.color = float4(0.0f, 1.0f, 0.0f, 1.0f);

    return output;
}

float4 main_ps(VS_Output input) : RGL_COLOR0
{
    float4 color_factor = g_mesh_factor_color * input.color;
	float4 tex_col = sample_diffuse_texture(linear_sampler, input.tex_coord).r * 0.01f;
	//clip(tex_col.a - 0.5f);
	INPUT_TEX_GAMMA(tex_col.rgb);
	
	float4 out_col;
	out_col = tex_col * color_factor;
	//out_col = color_factor;
	
	out_col.rgb = output_color(out_col.rgb);
	
    return out_col;
}
	
