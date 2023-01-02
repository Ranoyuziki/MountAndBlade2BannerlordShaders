#define GBUFFER_PASS
//WARNING : This is a generated file
//WARNING : Do not change this file.

#define diffuse_texture	texture0
#define outer_mesh_diffuse_texture_1	texture1
#define normal_texture	texture2
#define outer_mesh_diffuse_texture_2	texture3
#define outer_mesh_diffuse_texture_3	texture4
#define outer_mesh_areamap_texture	texture6
#define splatmap_texture	texture7
#define FlowMap	texture8
#define DecalSpecularMap	texture9

#define OUTER_MESH_RENDERING
#define USE_METALLIC_WORKFLOW 1
#define Vertex_shader_output_type VS_OUTPUT_STANDART

#if USE_TESSELATION
 #define Pixel_shader_input_type VS_OUTPUT_STANDART
#else
 #define Pixel_shader_input_type VS_OUTPUT_STANDART
#endif

#define my_material_id MATERIAL_ID_METALLIC

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

#include "outer_mesh_functions.rsh" 

#if VERTEX_SHADER
Vertex_shader_output_type main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(Vertex_shader_output_type, Out);
	Per_vertex_modifiable_variables pv_modifiable = (Per_vertex_modifiable_variables)0;

	calculate_object_space_values_standart(In , pv_modifiable, Out );
	calculate_world_space_values_standart(In , pv_modifiable, Out );
	calculate_render_related_values_standart(In , pv_modifiable, Out );
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	vs_output_vertex_color(Out, In);
#endif
	return Out;
}

#endif
#if USE_TESSELATION
	#define Constant_hs_output_type HS_CONSTANT_DATA_OUTPUT_STANDART

	#define Hull_shader_output_type VS_OUTPUT_STANDART

	#define Domain_shader_output_type VS_OUTPUT_STANDART

	#define Generated_hull_shader_func_name standart_hs

	#define Generated_domain_shader_func_name standart_ds

#if HULL_SHADER
	[domain("tri")]
	[partitioning("fractional_odd")]
	[outputtopology("triangle_cw")]
	[outputcontrolpoints(3)]
	[patchconstantfunc("constants_hs")]
	[maxtessfactor(16.0)]
	Hull_shader_output_type main_hs(InputPatch<VS_OUTPUT_STANDART, 3> inputPatch, uint control_point_id : SV_OutputControlPointID)
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
#if !ALPHA_TEST && !USE_SMOOTH_FADE_OUT
[earlydepthstencil]
#endif
PS_OUTPUT_GBUFFER main_ps(Pixel_shader_input_type In)
{
	PS_OUTPUT_GBUFFER Output = (PS_OUTPUT_GBUFFER)0;
	Per_pixel_static_variables pp_static = (Per_pixel_static_variables)0;
	Per_pixel_modifiable_variables pp_modifiable = (Per_pixel_modifiable_variables)0;

	Per_pixel_auxiliary_variables pp_aux = (Per_pixel_auxiliary_variables)0;

	calculate_per_pixel_static_variables(In, pp_static);

	sample_textures_standart(In , pp_static , pp_modifiable, pp_aux);
	calculate_alpha_standart(In , pp_static , pp_modifiable, pp_aux);
	apply_alpha_test(In, pp_modifiable.early_alpha_value);
	calculate_normal_standart(In , pp_static , pp_modifiable, pp_aux);
	compute_outer_mesh_albedo_color(In , pp_static , pp_modifiable, pp_aux);
	calculate_specularity_standart(In , pp_static , pp_modifiable, pp_aux);
	calculate_diffuse_ao_factor_standart_deferred(In , pp_static , pp_modifiable, pp_aux);
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
