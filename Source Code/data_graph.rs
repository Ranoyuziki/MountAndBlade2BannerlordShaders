
#include "../shader_configuration.h"

// #define VERTEX_DECLARATION VDECL_REGULAR

#include "definitions.rsh"
#include "shared_functions.rsh"

VS_OUTPUT_NOTEXTURE main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_NOTEXTURE Out;
	
	
	#define MAX_GRAPH_HISTORY 128
	
	float obj_val_normalized;
	{
		int data_index = min(126, int( floor(In.position.x + 0.01f)));
		int data_mat_no = min(data_index / 4, 31);
		int data_sub_no = data_index % 4;
		float4x4 data_mat = g_world_array[data_mat_no];
		float4 data_mat_val = data_mat[0];
		obj_val_normalized = max(0, data_mat_val[data_sub_no]);
	}
	
	float obj_prev_val_normalized;
	{
		int data_index = max(0, min(126, int( floor(In.position.x - 0.99f))));
		int data_mat_no = min(data_index / 4, 31);
		int data_sub_no = data_index % 4;
		float4x4 data_mat = g_world_array[data_mat_no];
		float4 data_mat_val = data_mat[0];
		obj_prev_val_normalized = max(0, data_mat_val[data_sub_no]);
	}
	
	float base_x = g_mesh_vector_argument.x;
	float base_y = g_mesh_vector_argument.y;
	float x_size = g_mesh_vector_argument.z;
	float y_size = g_mesh_vector_argument.w;


	float cur_y = base_y + obj_val_normalized * y_size;
	float prev_y = base_y + obj_prev_val_normalized * y_size;
	
	const float dx = g_application_halfpixel_viewport_size_inv.z;
	const float dy = g_application_halfpixel_viewport_size_inv.w;

	In.position.x *= (x_size / MAX_GRAPH_HISTORY);
	In.position.x += base_x;
	
	/*if( abs(obj_val_normalized - obj_prev_val_normalized) > 8*dy )
	{
		if(obj_val_normalized - obj_prev_val_normalized > 0)
		{
			if(In.tex_coord.y < 0.5)
			{
				In.position.x += dx;
			}
			else
			{
				In.position.x -= dx;
			}
		}
		else
		{
			if(In.tex_coord.y < 0.5)
			{
				In.position.x -= dx;
			}
			else
			{
				In.position.x += dx;
			}
		}
			
	
		In.position.y = y;
	}
	else*/
	{
		In.position.y = min(prev_y, cur_y);
		
		if(In.tex_coord.y < 0.5)
		{
			//In.position.y += dy;
			In.position.y = max(prev_y, cur_y)+dy;
		}
	}
	
	
	
	Out.position = mul(g_view_proj, mul(g_world, float4(In.position, 1.0f)));
	Out.color = get_vertex_color(In.color) * g_mesh_factor_color;
	
	return Out;
}

PS_OUTPUT main_ps(VS_OUTPUT_NOTEXTURE In) 
{ 
	PS_OUTPUT Output;
	Output.RGBColor = In.color;
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	
	return Output;
}
