#ifndef BOW_DEFORMER_RSH
#define BOW_DEFORMER_RSH

#include "../shader_configuration.h"

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"
#include "projectile_load.rsh"

//missile motion blur ----------------------


#define arrow_length g_mesh_vector_argument_2.x
#define arrow_directional_dx (g_mesh_vector_argument_2.y * 4.6)

#if VERTEX_SHADER

//---------------------------------
// Arrow Motion Blur Functions
bool do_motion_blur(RGL_VS_INPUT In)
{
	return arrow_length > 0;
}

float get_modified_percentage_of_vertex(inout RGL_VS_INPUT In, float pos_z, float modification_amount)
{
	return (pos_z + modification_amount) / (modification_amount + arrow_length);
}

void deform_position_wrt_motion_blur(inout RGL_VS_INPUT In, inout float3 object_position)	//returns blend amount
{
	if(object_position.z < 0.1)
	{
		float expand_value = arrow_directional_dx;
		object_position.z -= expand_value;
	}
}



float calculate_blend_amount_wrt_vertex_paint(float paint)
{
	float blend_value = pow(paint,2.5);
	//return top_value_modifier;
	return blend_value;
}


//---------------------------------
// Vertex Position Deformers
void deform_bow(inout RGL_VS_INPUT In, inout float4 vertex_color, inout float3 pos, float rope_len_half)
{
	float progress = g_mesh_vector_argument.x;

    float d_pull_max = 0.6f;
    //float rope_len_half = 0.55f;
    float curve_const_x = 1.6f;
    float curve_const_z = 0.6f;
	
    float d_pull = progress * d_pull_max * 0.5f;

	float bow_z = sqrt(rope_len_half * rope_len_half - d_pull * d_pull);
    float point_on_bow = pos.z / rope_len_half;
    //point_on_bow = (point_on_bow < -1.0f) ? -1.0f : ((point_on_bow >= 1.0f) ? 1.0f : point_on_bow); 
	point_on_bow = clamp(point_on_bow, -1.0f, 1.0f);
    
    float abs_point_on_bow = abs(point_on_bow);

    float z_diff = point_on_bow * (rope_len_half - bow_z);
    float x_diff = abs_point_on_bow * (-d_pull);

    //float curve_x = curve_const_x * pow(abs(pos.z), 2);
    //float curve_z = curve_const_z * pow(abs(pos.x), 2);

    float bend_factor = (abs_point_on_bow + 0.5f) / 1.4f;

    pos.z -= z_diff * bend_factor; /** curve_z*/
    pos.x -= x_diff * bend_factor * 0.7f/** curve_x*/;
	
	// if(vertex_color.b == 0.0f && vertex_color.r == 0.0f && vertex_color.g == 1.0f)
	// {
	    // pos.x += (1.0f - abs_point_on_bow) * progress * d_pull_max;
	// }
	pos.x += (1.0f - abs_point_on_bow) * progress * d_pull_max * vertex_color.g;
	
	//if(abs_point_on_bow < 0.1f && abs_point_on_bow > -0.1f)
	//{
	//	pos.z += 0.05f;
	//}
	
	vertex_color = 1;
}

void deform_crossbow(inout RGL_VS_INPUT In, inout float4 vertex_color, inout float3 pos, float rope_len_half)
{
	float progress = g_mesh_vector_argument.x;
	progress *= vertex_color.b;

    float d_pull_max = 0.25f;
    //float rope_len_half = 0.55f;
    float curve_const_x = 1.6f;
    float curve_const_z = 0.6f;
	
    float d_pull = progress * d_pull_max * 0.5f;

	float bow_z = sqrt(rope_len_half * rope_len_half - d_pull * d_pull);
    float point_on_bow = pos.x / rope_len_half;
    //point_on_bow = (point_on_bow < -1.0f) ? -1.0f : ((point_on_bow >= 1.0f) ? 1.0f : point_on_bow); 
	point_on_bow = clamp(point_on_bow, -1.0f, 1.0f);
    
    float abs_point_on_bow = abs(point_on_bow);

    float z_diff = point_on_bow * (rope_len_half - bow_z);
    float x_diff = abs_point_on_bow * (-d_pull);

    //float curve_x = curve_const_x * pow(abs(pos.z), 2);
    //float curve_z = curve_const_z * pow(abs(pos.x), 2);

    float bend_factor = (abs_point_on_bow + 0.5f) / 1.4f;

    pos.x -= z_diff * bend_factor; /** curve_z*/
    pos.z += x_diff * bend_factor * 0.7f/** curve_x*/;
	
    pos.z -= (1.0f - abs_point_on_bow) * progress * d_pull_max * vertex_color.g;

	
	vertex_color.b = 1.0f;
}

void deform_pistol_crossbow(inout RGL_VS_INPUT In, inout float4 vertex_color, inout float3 pos, float rope_len_half)
{
	float progress = g_mesh_vector_argument.x;
	progress *= vertex_color.b;

    float d_pull_max = 0.25f;
    //float rope_len_half = 0.55f;
    float curve_const_x = 1.6f;
    float curve_const_z = 0.6f;
	
    float d_pull = progress * d_pull_max * 0.5f;

	float bow_z = sqrt(rope_len_half * rope_len_half - d_pull * d_pull);
    float point_on_bow = pos.y / rope_len_half;
    //point_on_bow = (point_on_bow < -1.0f) ? -1.0f : ((point_on_bow >= 1.0f) ? 1.0f : point_on_bow); 
	point_on_bow = clamp(point_on_bow, -1.0f, 1.0f);
    
    float abs_point_on_bow = abs(point_on_bow);

    float z_diff = point_on_bow * (rope_len_half - bow_z);
    float x_diff = abs_point_on_bow * (-d_pull);

    //float curve_x = curve_const_x * pow(abs(pos.z), 2);
    //float curve_z = curve_const_z * pow(abs(pos.x), 2);

    float bend_factor = (abs_point_on_bow + 0.5f) / 1.4f;

    pos.y -= z_diff * bend_factor; /** curve_z*/
    pos.z += x_diff * bend_factor * 0.7f/** curve_x*/;
	
    pos.z -= (1.0f - abs_point_on_bow) * progress * d_pull_max * vertex_color.g;
	
	//if(abs_point_on_bow < 0.1f && abs_point_on_bow > -0.1f)
	//{
	//	pos.z += 0.05f;
	//}
	
	vertex_color.b = 1.0f; 
}

//---------------------------------
// DELEGATES

void deform_bow_delegate(inout RGL_VS_INPUT input)
{
	float4 color = get_vertex_color(input.color);
	deform_bow(input, color, input.position.xyz, 0.515f);
	set_vertex_color(color, input.color);
}

void deform_longbow_delegate(inout RGL_VS_INPUT input)
{
	float4 color = get_vertex_color(input.color);
	deform_bow(input, color, input.position.xyz, 0.865f);
	set_vertex_color(color, input.color);
}

void deform_pistol_crossbow_delegate(inout RGL_VS_INPUT input)
{
	float4 color = get_vertex_color(input.color);
	deform_pistol_crossbow(input, color, input.position.xyz, 0.35f);
	set_vertex_color(color, input.color);
}

void deform_crossbow_delegate(inout RGL_VS_INPUT input)
{
	float4 color = get_vertex_color(input.color);
	deform_crossbow(input, color, input.position.xyz, 0.35f);
	set_vertex_color(color, input.color);
}

void deform_arrow_delegate(inout RGL_VS_INPUT In)
{
	if(do_motion_blur(In))
	{		
		deform_position_wrt_motion_blur(In, In.position.xyz);
	}
}



//----------------------------------

void calculate_render_related_values_bow_deformer(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	calculate_render_related_values_standart(In,pv_modifiable,output);
	#ifdef USE_MOTION_BLUR_ARROW
		if(do_motion_blur(In))
		{		
			output.arrow_mb_alpha_multiplier = get_modified_percentage_of_vertex(In, In.position.z, arrow_directional_dx);
		}
	#endif
}

#endif


#if PIXEL_SHADER
void deform_arrow_pixel_output_modifier(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , 
										inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux, inout PS_OUTPUT Output)
{
	#ifdef USE_MOTION_BLUR_ARROW
		if(do_motion_blur())
		{	
			Output.RGBColor.a *= calculate_blend_amount_for_blur(In, inout RGL_VS_INPUT InIn.arrow_mb_alpha_multiplier );
		}
	#endif
}

float calculate_blend_amount_for_blur(inout Pixel_shader_input_type In, float modified_percentage)
{
	float expand_value = arrow_directional_dx;
	float top_value_modifier = pow(min(arrow_length / expand_value, 1), 2.5f);

	float blend_value = (1.0f - abs(modified_percentage - 0.5f) * 2.0f) * top_value_modifier;
	//return top_value_modifier;
	return max(blend_value * 1.5f, 0.3);
}
#endif

#endif
