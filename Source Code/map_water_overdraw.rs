#define OVERDRAW_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.

#define DepthGradientTexture	texture1
#define NormalMap1	texture2
#define NormalMap2	texture3
#define FoamTexture	texture6
#define IceSpecular	texture7
#define IceNormal	texture8

#define WATER_RENDERING 1
#define USE_MAP_WATER
#define Vertex_shader_output_type VS_OUTPUT_WATER

#define Pixel_shader_input_type VS_OUTPUT_WATER
#define my_material_id MATERIAL_ID_NONE

#define Per_pixel_modifiable_variables water_shading_values

#define Per_pixel_auxiliary_variables standart_auxiliary_values

#include "../shader_configuration.h" 
#include "definitions.rsh" 
#include "modular_struct_definitions.rsh" 
#include "shared_functions.rsh" 
#include "motion_vector.rsh" 
#include "generated_definitions.rsh" 

#include "watermap.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_water(In , pv_modifiable, Out );
	calculate_world_space_values_water(In , pv_modifiable, Out );
	calculate_render_related_values_water(In , pv_modifiable, Out );
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	vs_output_vertex_color(Out, In);
#endif
	return Out;
}

#endif
#ifdef PIXEL_SHADER
#if !ALPHA_TEST
[earlydepthstencil]
#endif
PS_OUTPUT_TO_USE main_ps(Pixel_shader_input_type In, uint prim_id : SV_PrimitiveID)
{
	PS_OUTPUT_TO_USE Out = (PS_OUTPUT_TO_USE)0;
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	calculate_alpha_water(In , pp_static , pp_modifiable, pp_aux);
#ifdef PIXEL_SHADER
compute_overdraw(In, In.position, In.instanceID, prim_id);
#endif
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
Out.RGBColor = float4(1,1,0,1);
	return Out;
}
#endif
