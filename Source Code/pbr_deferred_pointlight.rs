#define POINTLIGHT_SHADOWMAP_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.

#define DiffuseMap	texture0
#define Diffuse2Map	texture1
#define NormalMap	texture2
#define DetailNormalMap	texture3
#define SpecularMap	texture4
#define EnvMap	texture5

#define USE_METALLIC_WORKFLOW IS_METALLIC || IS_GRASS
#define Vertex_shader_output_type VS_OUT_POSTFX

#define Pixel_shader_input_type VS_OUT_POSTFX
#define my_material_id MATERIAL_ID_DEFERRED

#define Per_pixel_modifiable_variables pbr_shading_values

#define Per_pixel_auxiliary_variables standart_auxiliary_values

#include "../shader_configuration.h" 
#include "definitions.rsh" 
#include "modular_struct_definitions.rsh" 
#include "shared_functions.rsh" 
#include "motion_vector.rsh" 
#include "generated_definitions.rsh" 

#include "standart.rsh" 

#include "pbr_shading_functions.rsh" 

#include "deferred_standart.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_deferred(In , pv_modifiable, Out );
	calculate_world_space_values_deferred(In , pv_modifiable, Out );
	calculate_render_related_values_deferred(In , pv_modifiable, Out );
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	vs_output_vertex_color(Out, In);
#endif
	return Out;
}

#endif
#if PIXEL_SHADER
void main_ps(Pixel_shader_input_type In)
{
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	calculate_alpha_deferred(In , pp_static , pp_modifiable, pp_aux);
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
}
#endif
