#ifndef DEFAULT_RSH
#define DEFAULT_RSH

#include "definitions.rsh"
#include "shared_functions.rsh"

//======================================================================================
// Vertex Shader
//======================================================================================

#if VERTEX_SHADER
VS_OUTPUT_STANDART default_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_STANDART, output);

	float4 new_position = float4(In.position, 1.0f);

	#if VDECL_HAS_SKIN_DATA
		float4 object_position;
		object_position.x = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 0];
		object_position.y = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 1];
		object_position.z = global_skinned_position_buffer[(g_skinned_vertex_buffer_offset + In.vertex_id) * 3 + 2];
		object_position.w = 1;
	#else
		float4 object_position = new_position;
	#endif
	
	output.position = mul(g_view_proj, mul(g_world, object_position));
	
	#if(VERTEX_DECLARATION != VDECL_POSTFX)
		output.tex_coord = In.tex_coord;
	#endif


	output.vertex_color = float4(1,1,1,1);


	return output;
}
#endif

//======================================================================================
// Pixel Shader
//======================================================================================

#if PIXEL_SHADER
float4 default_ps(VS_OUTPUT_STANDART In)
{
	float4 color_factor = g_mesh_factor_color * In.vertex_color;
	float4 tex_col = sample_diffuse_texture(linear_sampler, In.tex_coord);
	apply_alpha_test(In, tex_col.a);
	INPUT_TEX_GAMMA(tex_col.rgb);
	
	float4 out_col;
	out_col = tex_col * color_factor;
	
	out_col.rgb = output_color(out_col.rgb);
		
    return out_col;
}
#endif

#endif
