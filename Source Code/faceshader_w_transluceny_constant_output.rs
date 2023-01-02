#define CONSTANT_OUTPUT_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.

#define DiffuseMap	texture0
#define Diffuse2Map	texture1
#define NormalMap	texture2
#define DetailNormalMap	texture3
#define SpecularMap	texture4
#define Heightmap	texture6
#define DecalDiffuseMap	texture7
#define DecalNormalMap	texture8
#define DecalSpecularMap	texture9

#define PN_TRIANGLES
#define Vertex_shader_output_type VS_OUTPUT_STANDART

#if USE_TESSELATION
 #define Pixel_shader_input_type VS_OUTPUT_STANDART
#else
 #define Pixel_shader_input_type VS_OUTPUT_STANDART
#endif

#define my_material_id MATERIAL_ID_FACE

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

#include "pbr_standart_functions.rsh" 

Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_standart(In , pv_modifiable, Out );
	calculate_world_space_values_standart(In , pv_modifiable, Out );
	calculate_render_related_values_standart(In , pv_modifiable, Out );
	#ifdef SYSTEM_SHOW_VERTEX_COLORS
		#if (my_material_id != MATERIAL_ID_TERRAIN) && (MATERIAL_ID_DEFERRED != my_material_id)
			Out.vertex_color = get_vertex_color(In.color);
		#endif
	#endif
	return Out;
}

#if USE_TESSELATION
	#define Constant_hs_output_type HS_CONSTANT_DATA_OUTPUT_STANDART

	#define Hull_shader_output_type VS_OUTPUT_STANDART

	#define Domain_shader_output_type VS_OUTPUT_STANDART

	#define Generated_hull_shader_func_name standart_hs

	#define Generated_domain_shader_func_name standart_ds

	[domain("tri")]
	[partitioning("integer")]
	[outputtopology("triangle_cw")]
	[outputcontrolpoints(3)]
	[patchconstantfunc("constants_hs")]
	[maxtessfactor(16.0)]
	Hull_shader_output_type main_hs(InputPatch<VS_OUTPUT_STANDART, 3> inputPatch, uint control_point_id : SV_OutputControlPointID)
	{
		return Generated_hull_shader_func_name(inputPatch, control_point_id);           
	}
	[domain("tri")]
	Domain_shader_output_type main_ds(Constant_hs_output_type input, float3 barycentric_coords : SV_DomainLocation, const OutputPatch<Hull_shader_output_type, 3> triangle_patch)
	{
		return Generated_domain_shader_func_name(input, barycentric_coords, triangle_patch);            
	}
#endif

PS_OUTPUT main_ps(Pixel_shader_input_type In)
{
	PS_OUTPUT Out = (PS_OUTPUT)0;
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	calculate_alpha_standart(In , pp_static , pp_modifiable, pp_aux);
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
Out.RGBColor = g_zero_constant_output ? float4(0, 0, 0, 0) : g_contour_color;
	return Out;
}
