//WARNING : This is a generated file
//WARNING : Do not change this file.

#define DiffuseMap	texture0
#define SpecularMap	texture1
#define NormalMap	texture2
#define EmissiveMask	texture3

#define USE_SMOOTH_FADE_OUT 1
#define Vertex_shader_output_type VS_OUTPUT_PARTICLE

#define Pixel_shader_input_type VS_OUTPUT_PARTICLE
#define my_material_id MATERIAL_ID_STANDART

#define Per_pixel_modifiable_variables particle_shading_values

#define Per_pixel_auxiliary_variables standart_auxiliary_values

#include "../shader_configuration.h" 
#include "definitions.rsh" 
#include "modular_struct_definitions.rsh" 
#include "shared_functions.rsh" 
#include "motion_vector.rsh" 
#include "generated_definitions.rsh" 

#include "pbr_shading_functions.rsh" 

#include "particle_shading.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_particle(In , pv_modifiable, Out );
	calculate_world_space_values_particle(In , pv_modifiable, Out );
	calculate_render_related_values_particle(In , pv_modifiable, Out );
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	vs_output_vertex_color(Out, In);
#endif
	return Out;
}

#endif
#if PIXEL_SHADER
#if !ALPHA_TEST && !USE_SMOOTH_FADE_OUT
[earlydepthstencil]
#endif
PS_OUTPUT_TO_USE main_ps(Pixel_shader_input_type In)
{
	PS_OUTPUT_TO_USE Output = (PS_OUTPUT_TO_USE)0;
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	sample_textures_particle(In , pp_static , pp_modifiable, pp_aux);
	calculate_alpha_particle(In , pp_static , pp_modifiable, pp_aux);
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
	calculate_normal_particle(In , pp_static , pp_modifiable, pp_aux);
	calculate_albedo_particle(In , pp_static , pp_modifiable, pp_aux);
	calculate_specularity_particle(In , pp_static , pp_modifiable, pp_aux);
	calculate_final_particle(In , pp_static , pp_modifiable, Output);
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	#if (MATERIAL_ID_TERRAIN != my_material_id) && (MATERIAL_ID_DEFERRED != my_material_id) && (MATERIAL_ID_GRASS != my_material_id)
		Output.RGBColor.rgba = get_masked_vertex_color(In.vertex_color.rgba);
	#endif
#endif
	return Output;
}
#endif
