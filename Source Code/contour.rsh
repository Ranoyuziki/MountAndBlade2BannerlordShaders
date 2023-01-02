#ifndef CONTOUR_RSH
#define CONTOUR_RSH

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"

VS_OUTPUT_STANDART_CONTOUR main_vs_contour(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_STANDART_CONTOUR, Out);
	
	float4 object_position;
	float3 object_normal, object_tangent, object_binormal, prev_object_position, object_color;
	
	rgl_vertex_transform_with_binormal(In, object_position, object_normal, object_tangent, object_binormal, prev_object_position, object_color);
	
#if USE_PROCEDURAL_WIND_ANIMATION
	object_position.xyz = simple_wind_animation(object_position.xyz,get_vertex_color(In.color).a, object_normal);
#endif

	Out.object_space = object_position;
			
	float4 world_position;
	float3 world_normal;

	float4 temp_vert_color = get_vertex_color(In.color);
	
	world_position = mul(g_world, object_position);
	world_normal = normalize(mul(to_float3x3(g_world),object_normal));

	world_position = mul(g_world, object_position);

	float len = length(world_position - g_camera_position.xyz);
	
	world_position.xyz	+= world_normal.xyz * (0.022) * g_contour_color.w ;

	Out.position = mul(g_view_proj, world_position);

	//Out.screen_space_pos = Out.position;
	Out.world_position = world_position;	
	Out.tex_coord.xy = In.tex_coord.xy;
	
	
	if(g_contour_color.w < 10e-6)
	{
		Out.position.z = Out.position.w;
	}
	
	Out.vertex_color = temp_vert_color;

	Out.world_normal.xyz = world_normal;

	
	return Out;
}

PS_OUTPUT main_ps_contour ( VS_OUTPUT_STANDART_CONTOUR In)
{ 
	PS_OUTPUT Output;
	
	Output.RGBColor = float4(0, 0, 0, 1);

	float4 contour_color = g_contour_color;

	Output.RGBColor = contour_color;
	return Output;
}

#endif
