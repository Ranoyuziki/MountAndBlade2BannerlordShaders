#ifndef DEFERRED_STANDART_RSH
#define DEFERRED_STANDART_RSH

#include "../shader_configuration.h"

#include "flagDefs.rsh"
#include "definitions.rsh"
#include "shared_functions.rsh"

#include "system_postfx.rsh"
#include "flora_shading_functions.rsh"
#include "grass.rsh"
#include "forward_face_functions.rsh" 


//main vertex shader functions
void calculate_render_related_values_deferred(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	output.position = float4(In.position, 1.0f);

	output.Tex = (float2(In.position.x, -In.position.y) * 0.5f + 0.5f);

	output.Color = get_vertex_color(In.color);
}
void calculate_object_space_values_deferred(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{


}
void calculate_world_space_values_deferred(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{

}

#if PIXEL_SHADER
//main pixel shader functions
void calculate_alpha_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.early_alpha_value = 1.0f;
}

void calculate_normal_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 _screen_space_position = In.Tex.xy;

	float4 pixel_gbuffer = gbuffer__normal.Load(int3(In.position.xy, 0));

	float3 world_space_normal = get_ws_normal_at_gbuffer(pixel_gbuffer.xy);
	pp_modifiable.world_space_normal = world_space_normal;

	//uint packed_vnormal = asuint(pixel_gbuffer.w);
	//float2 encoded_vnormal;
	//encoded_vnormal.x = ((packed_vnormal & 0x0000FF00) >> 8) / 255.0f;
	//encoded_vnormal.y = (packed_vnormal & 0x000000FF) / 255.0f;
	//pp_modifiable.vertex_normal = get_ws_normal_at_gbuffer(encoded_vnormal);

	//pp_modifiable.vertex_normal = world_space_normal;

	float4 data = texture6.Load(int3(In.position.xy, 0));
	float3 vertex_normal = get_ws_normal_at_gbuffer(data.xy);
	pp_modifiable.vertex_normal = vertex_normal;
}
void calculate_albedo_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 _screen_space_position = In.Tex.xy;
	float3 albedo_color = gbuffer__albedo_thickness.Load(int3(In.position.xy, 0)).rgb;

#ifdef USE_GAMMA_CORRECTED_GBUFFER_ALBEDO
	INPUT_TEX_GAMMA(albedo_color.rgb);
#endif
	pp_modifiable.albedo_color = albedo_color.rgb;
}
void calculate_specularity_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 _screen_space_position = In.Tex.xy;
	float2 _specularity_info = gbuffer__spec_gloss_ao_shadow.Load(int3(In.position.xy, 0)).xy;
	float thickness = gbuffer__albedo_thickness.Load(int3(In.position.xy, 0)).a;

	pp_modifiable.specularity = _specularity_info;
	pp_modifiable.translucency = thickness;
}

void calculate_diffuse_ao_factor_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float diffuse_occlusion_factor = 1.0f;
	float ambient_occlusion_factor = 1.0f;

	ambient_occlusion_factor = gbuffer__spec_gloss_ao_shadow.Load(int3(In.position.xy, 0)).z;

	float tsao_ao_factor = sample_ssao_texture(pp_static.screen_space_position).r;
	ambient_occlusion_factor *= tsao_ao_factor;
	diffuse_occlusion_factor *= tsao_ao_factor;


	ambient_occlusion_factor = max(ambient_occlusion_factor, 0.05);

	pp_modifiable.ambient_ao_factor = ambient_occlusion_factor;
	pp_modifiable.diffuse_ao_factor = diffuse_occlusion_factor;
}

void calculate_final_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{

#if IS_FLORA
	{
		calculate_final_flora(In, pp_static, pp_modifiable, Output);
	}
#elif IS_GRASS
	{
		calculate_final_pbr(In, pp_static, pp_modifiable, Output);
	}
#elif IS_FLORA_BILLBOARD
	{
		calculate_final_flora(In, pp_static, pp_modifiable, Output);
	}
#elif IS_FACE_WO_SPECULAR
	{
		calculate_final_color_face(In, pp_static, pp_modifiable, Output, false);
	}
#elif IS_FACE_W_SPECULAR
	{
		calculate_final_color_face(In, pp_static, pp_modifiable, Output, true);
	}
#elif IS_FACE_SPECULAR
	{
		calculate_final_color_face_specular(In, pp_static, pp_modifiable, Output);
	}
#else
	{
		calculate_final_pbr(In, pp_static, pp_modifiable, Output);
	}
#endif

	//Output.RGBColor = float4(pp_modifiable.world_space_normal * 0.5 + 0.5,0);

}

#endif

#endif
