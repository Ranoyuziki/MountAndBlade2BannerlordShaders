#ifndef MAP_TREE_BILLBOARDED_RSH
#define MAP_TREE_BILLBOARDED_RSH
 
#include "../shader_configuration.h"

// #define VERTEX_DECLARATION VDECL_REGULAR

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"

#if VERTEX_SHADER
void enlarge_map_tree_billboards(float4 vertex_color, inout float4 world_position, float3 object_normal , out float3 world_normal)
{
    float2 leaf_size = float2(0.874, 0.874);

	float4x4 view_mat = g_view;	//world matrix should have no rotation
	
	float3 vec_to_object = normalize(-get_row(view_mat, 2).xyz);	
	
	float3 right_vector = normalize(get_row(view_mat, 0).xyz);	//get transposed .s
	float3 up_vector = normalize(cross(normalize(right_vector), vec_to_object));
	right_vector *= leaf_size.x ;
	up_vector *= leaf_size.y ;

	float3 tex_cord_middled = normalize(object_normal.xyz); 

	world_position.xyz += tex_cord_middled.x * right_vector;
	world_position.xyz += tex_cord_middled.z * up_vector ;
	world_position.xyz += tex_cord_middled.y * vec_to_object * 0.1;

	world_normal = 0;
	world_normal.xyz += object_normal.x * right_vector * 0.3;
	world_normal.xyz += object_normal.z * up_vector * 0.3;
	
	world_normal.xyz += normalize(vec_to_object) * object_normal.y;
	world_normal.xyz = normalize(world_normal.xyz);
}

//main vertex shader functions
void calculate_render_related_values_map_trees(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	pv_modifiable.tex_coord_1 = float4(In.tex_coord.xy,0,0);

	output.vertex_color = pv_modifiable.vertex_color;
	output.vertex_color.rg = 1.0f;
	output.vertex_color.a = 1;
	#ifndef SHADOWMAP_PASS
	output.world_normal.xyz = pv_modifiable.world_normal.xyz;
	output.world_normal.z = 0.05;
	output.world_normal.xyz = normalize(output.world_normal).xyz;
	#endif

	output.tex_coord.xy = pv_modifiable.tex_coord_1.xy;

	float smooth_transition_distance = 81 * 1.75;
	float3 distance_vec = pv_modifiable.world_position.xyz - g_root_camera_position.xyz;
	if(dot(distance_vec, distance_vec) < (smooth_transition_distance * smooth_transition_distance))
	{
		output.vertex_color.a = 0;
	}
	
	#ifdef STANDART_FOR_CRAFT_TRACK
		output.tex_coord.x += g_mesh_vector_argument.x;
		output.tex_coord.y += g_mesh_vector_argument.y * 0.25f;
	#endif

	#if VDECL_HAS_DOUBLEUV
		output.tex_coord.zw = In.tex_coord2.xy;
	#endif
	

}
void calculate_object_space_values_map_trees(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_STANDART, Out);
	
	float3 prev_object_position, object_color;
	rgl_vertex_transform(In, pv_modifiable.object_position, pv_modifiable.object_normal, pv_modifiable.object_tangent, prev_object_position, object_color);

}
void calculate_world_space_values_map_trees(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
	pv_modifiable.world_position = mul(g_world, pv_modifiable.object_position);
	pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));
	
	//billboarding: 
	{
		pv_modifiable.vertex_color = (get_vertex_color(In.color));
		bool is_2d_billboard = pv_modifiable.vertex_color.b > 0;

		if( !is_2d_billboard )
		{
			enlarge_map_tree_billboards(pv_modifiable.vertex_color, pv_modifiable.world_position, pv_modifiable.object_normal.xyz , pv_modifiable.world_normal.xyz);
		}
		else
		{
			pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));
		}
	}

	Out.world_position = pv_modifiable.world_position;
	Out.position = mul(g_view_proj, pv_modifiable.world_position);
	
	Out.position.z = min(Out.position.z, Out.position.w-0.001f);

	//#if SYSTEM_CLIP_PLANE
	//	clip_plane_calculation(pv_modifiable.world_position, Out.clip_distance);
	//#endif
}
	
#endif

#endif
