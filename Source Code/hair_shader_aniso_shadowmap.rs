#define SHADOWMAP_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.

#define DiffuseMap	texture0
#define HairShiftandNoiseMap	texture1
#define DecalDiffuseMap	texture7
#define DecalNormalMap	texture8
#define DecalSpecularMap	texture9

#define USE_ANISO_SPECULAR 1
#define Vertex_shader_output_type VS_OUTPUT_HAIR

#define Pixel_shader_input_type VS_OUTPUT_HAIR
#define my_material_id MATERIAL_ID_NONE

#define Per_pixel_modifiable_variables pbr_shading_values

#define Per_pixel_auxiliary_variables hair_auxiliary_values

#include "../shader_configuration.h" 
#include "definitions.rsh" 
#include "modular_struct_definitions.rsh" 
#include "shared_functions.rsh" 
#include "motion_vector.rsh" 
#include "generated_definitions.rsh" 

#include "standart.rsh" 

#include "pbr_shading_functions.rsh" 

#include "hair_functions.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_hair_aniso(In , pv_modifiable, Out );
	calculate_world_space_values_hair_aniso(In , pv_modifiable, Out );
	calculate_render_related_values_hair_aniso(In , pv_modifiable, Out );
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

	sample_textures_standart(In , pp_static , pp_modifiable, pp_aux);
	calculate_alpha_hair_aniso(In , pp_static , pp_modifiable, pp_aux);
	aniso_hair_alpha_test_function(In , pp_static , pp_modifiable, pp_aux);
}
#endif
