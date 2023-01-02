#ifndef MAP_DECAL_RSH
#define MAP_DECAL_RSH

#include "../shader_configuration.h"

// #define VERTEX_DECLARATION VDECL_REGULAR

#include "definitions.rsh"

#include "shared_functions.rsh"

PS_OUTPUT deferred_decal_ps(VS_OUTPUT_DEFERRED_DECAL In)
{ 
	PS_OUTPUT Output;
	
	//Output.RGBColor = float4(1,0,0,1);
	//return Output;
	
	In.ClipSpacePos.xy /= In.ClipSpacePos.w;
	
	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f; 
	tc.y = tc.y * -0.5f - 0.5f; 

	float4 pixel_gbuffer = sample_normal_texture(tc);
	float pixel_depth = pixel_gbuffer.z;	
	
	if(pixel_gbuffer.r < 10.0)
		clip(-1);
	else
		pixel_gbuffer.r -= 10.0;
		
	float3 In_WorldSpaceCamDir = normalize(In.WorldSpacePos.xyz - g_camera_position.xyz);
	
	float4 pixel_pos_in_ws = float4(In_WorldSpaceCamDir.xyz * pixel_depth * g_far_clip + g_camera_position.xyz, 1);
	float4 pixel_pos_in_os =  mul(g_world_inverse, pixel_pos_in_ws);
	float2 decal_tex_coord = (pixel_pos_in_os.xy + 1.0) * 0.5;

	
	float3 view_direction = normalize(g_camera_position.xyz - pixel_pos_in_ws.xyz);
	float3 pixel_normal_in_ws;

	float3 pixel_normal_in_vs; 
	pixel_normal_in_vs.xy = float2(pixel_gbuffer.r, pixel_gbuffer.g) * 2.0f - 1.0f;
	pixel_normal_in_vs.z = sqrt(1.0f - dot(pixel_normal_in_vs.xy, pixel_normal_in_vs.xy));
	pixel_normal_in_ws = mul((float3x3)g_inverse_view, pixel_normal_in_vs);
	
	float3 distance_vector2 = abs(pixel_pos_in_os.xyz);
	float is_in_range = 0;
	if( distance_vector2.x < 1 && distance_vector2.y < 1 && distance_vector2.z < 1)
	{
		is_in_range= 1;
	}
	
	float3 normal;

	normal = pixel_normal_in_ws.xyz;
	
	
	float sun_amount = 1;
	
	float4 total_light = get_ambient_term_with_skyaccess(In.WorldSpacePos, pixel_normal_in_ws, In.Pos.xy * g_application_halfpixel_viewport_size_inv.zw);

	{
		total_light.rgb += (saturate(dot(-g_sun_direction.xyz, normal.xyz))) * sun_amount * g_sun_color.rgb;
	}
	
	//float2 tex_modifiers = g_mesh_vector_argument.xy;
	float2 diffuse_tex_coord = decal_tex_coord;//	 * 0.5 + 0.5;// * tex_modifiers.xx + tex_modifiers.yy;
	
	float uv_scale_x = g_mesh_factor_color.x;
	float uv_scale_y = g_mesh_factor_color.y;	//use color2?
	float uv_offset_x = g_mesh_factor_color.z;
	float uv_offset_y = g_mesh_factor_color.w;
	float2 atlassed_texture_coord = float2(diffuse_tex_coord.x * uv_scale_x + uv_offset_x, diffuse_tex_coord.y * uv_scale_y + uv_offset_y);
	//float2 atlassed_texture_coord = diffuse_tex_coord;
	float4 tex_col = sample_diffuse_texture(linear_sampler, atlassed_texture_coord);
	//float4 tex_col = float4(1,0,0,0.85f);
	float tex_mask = 1;//sample_specular_texture(decal_tex_coord).a;
	
	float3 normal_ = g_mesh_vector_argument.xyz;
	float p = g_mesh_vector_argument.w;
	float distance = dot(normal_, pixel_pos_in_ws) + p;
	
	total_light.rgb *= tex_col.rgb *  /*g_mesh_factor_color.rgb */ is_in_range;
	total_light.a = tex_col.a * is_in_range * tex_mask;// * g_mesh_factor_color.a;
	if(abs(distance) > 0.1f || dot(normal_, pixel_normal_in_ws) < 0)
		total_light.a = 0;
	//total_light.rgb = is_in_range;
	//total_light.a = 1;
	
	Output.RGBColor = total_light;
	
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	
	return Output;
}

#endif
