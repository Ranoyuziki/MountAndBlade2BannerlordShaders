#define POINTLIGHT_SHADOWMAP_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.


#define USE_GAMMA_CORRECTED_TERRAIN_COLORMAPS
#define USE_TERRAIN_GET_HEIGHT_FOR_PARALLAX
#define Vertex_shader_output_type VS_OUTPUT_TERRAIN

#if USE_TESSELATION
 #define Pixel_shader_input_type DS_OUTPUT
#else
 #define Pixel_shader_input_type VS_OUTPUT_TERRAIN
#endif

#define my_material_id MATERIAL_ID_TERRAIN

#define Per_pixel_modifiable_variables pbr_shading_values

#define Per_pixel_auxiliary_variables terrain_auxiliary_values

#include "../shader_configuration.h" 
#include "definitions.rsh" 
#include "modular_struct_definitions.rsh" 
#include "shared_functions.rsh" 
#include "motion_vector.rsh" 
#include "generated_definitions.rsh" 

#include "terrain_header_data.rsh" 

#include "terrain_vertex_functions.rsh" 

#include "terrain_pixel_functions.rsh" 

#include "pbr_shading_functions.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_terrain(In , pv_modifiable, Out );
	calculate_world_space_values_terrain(In , pv_modifiable, Out );
	calculate_render_related_values_terrain(In , pv_modifiable, Out );
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	vs_output_vertex_color(Out, In);
#endif
	return Out;
}

#endif
#if USE_TESSELATION
	#define Constant_hs_output_type HS_CONSTANT_DATA_OUTPUT_TERRAIN

	#define Hull_shader_output_type HS_CONTROL_POINT_OUTPUT

	#define Domain_shader_output_type DS_OUTPUT

	#define Generated_hull_shader_func_name terrain_hs

	#define Generated_domain_shader_func_name terrain_ds

#if HULL_SHADER
	[domain("tri")]
	[partitioning("fractional_odd")]
	[outputtopology("triangle_cw")]
	[outputcontrolpoints(3)]
	[patchconstantfunc("constants_hs")]
	[maxtessfactor(16.0)]
	Hull_shader_output_type main_hs(InputPatch<VS_OUTPUT_TERRAIN, 3> inputPatch, uint control_point_id : SV_OutputControlPointID)
	{
		return Generated_hull_shader_func_name(inputPatch, control_point_id);           
	}
#endif
#if DOMAIN_SHADER
	[domain("tri")]
	Domain_shader_output_type main_ds(Constant_hs_output_type input, float3 barycentric_coords : SV_DomainLocation, const OutputPatch<Hull_shader_output_type, 3> triangle_patch)
	{
		return Generated_domain_shader_func_name(input, barycentric_coords, triangle_patch);            
	}
#endif
#endif

#if PIXEL_SHADER
void main_ps(Pixel_shader_input_type In)
{
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	calculate_terrain_alpha(In , pp_static , pp_modifiable, pp_aux);
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
}
#endif
