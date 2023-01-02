#define GBUFFER_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.

#define SDFAlpha	texture6

#define USE_METALLIC_WORKFLOW 1
#define USE_SMOOTH_FLORA_LOD_TRANSITION
#define Vertex_shader_output_type VS_OUTPUT_GRASS

#define Pixel_shader_input_type VS_OUTPUT_GRASS
#define my_material_id MATERIAL_ID_GRASS

#define Per_pixel_modifiable_variables pbr_shading_values

#define Per_pixel_auxiliary_variables standart_auxiliary_values

#include "../shader_configuration.h" 
#include "definitions.rsh" 
#include "modular_struct_definitions.rsh" 
#include "shared_functions.rsh" 
#include "motion_vector.rsh" 
#include "generated_definitions.rsh" 

#include "grass.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_world_space_values_grass(In , pv_modifiable, Out );
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	vs_output_vertex_color(Out, In);
#endif
	return Out;
}

#endif
#if PIXEL_SHADER
PS_OUTPUT_GBUFFER main_ps(Pixel_shader_input_type In)
{
	PS_OUTPUT_GBUFFER Output = (PS_OUTPUT_GBUFFER)0;
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	sample_textures_standart(In , pp_static , pp_modifiable, pp_aux);
	calculate_alpha_grass(In , pp_static , pp_modifiable, pp_aux);
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
	calculate_normal_grass(In , pp_static , pp_modifiable, pp_aux);
	calculate_albedo_grass(In , pp_static , pp_modifiable, pp_aux);
	calculate_specular_grass(In , pp_static , pp_modifiable, pp_aux);
	calculate_ao_grass_deferred(In , pp_static , pp_modifiable, pp_aux);
	float occlusion_info = pp_modifiable.ambient_ao_factor;
	set_gbuffer_values(Output, pp_modifiable.world_space_normal, pp_modifiable.early_alpha_value, pp_modifiable.albedo_color, 		pp_modifiable.specularity, occlusion_info, pp_modifiable.vertex_normal, pp_modifiable.translucency, pp_modifiable.shadow, pp_modifiable.resolve_output);
	set_gbuffer_motion_vector(In, Output);
	set_gbuffer_entity_id(In, pp_static, pp_modifiable, Output);

#ifdef SYSTEM_SHOW_VERTEX_COLORS
	#if (MATERIAL_ID_TERRAIN != my_material_id) && (MATERIAL_ID_GRASS != my_material_id)
		Output.gbuffer_albedo_thickness.rgb = get_masked_vertex_color(In.vertex_color.rgba).rgb;
	#endif
#endif
	return Output;
}
#endif