#ifndef USE_OUTER_MESH_FUNCTIONS_RSH
#define USE_OUTER_MESH_FUNCTIONS_RSH

//outer mesh albedo function
#if PIXEL_SHADER && !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS)
#include "pbr_standart_pixel_functions.rsh"

void compute_outer_mesh_albedo_color_aux(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , 
inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float3 _albedo_color;
	
	float4 diffuse1 = outer_mesh_diffuse_texture_1.Sample(linear_sampler, In.tex_coord.xy * g_mesh_vector_argument.x);
	INPUT_TEX_GAMMA(diffuse1.rgb);
	float4 diffuse2 = outer_mesh_diffuse_texture_2.Sample(linear_sampler, In.tex_coord.xy * g_mesh_vector_argument.y);
	INPUT_TEX_GAMMA(diffuse2.rgb);
	float4 diffuse3 = outer_mesh_diffuse_texture_3.Sample(linear_sampler, In.tex_coord.xy * g_mesh_vector_argument.z);
	INPUT_TEX_GAMMA(diffuse3.rgb);
	float4 splat_map = splatmap_texture.Sample(linear_sampler, In.tex_coord.xy);
	
	_albedo_color = (diffuse1.rgb * splat_map.r * diffuse1.a + diffuse2.rgb * splat_map.g * diffuse2.a + diffuse3.rgb * splat_map.b * diffuse3.a);
	
	float3 areamap_texture = outer_mesh_areamap_texture.Sample(linear_sampler, In.tex_coord.xy * g_mesh_vector_argument.w).rgb;
	INPUT_TEX_GAMMA(areamap_texture.rgb);
	_albedo_color = lerp(_albedo_color , areamap_texture * _albedo_color , g_mesh_vector_argument_2.x);
	
	#if SYSTEM_SNOW_LAYER			
		float4 snow_color = sample_snow_diffuse_texture( In.tex_coord.xy * g_mesh_vector_argument.w);
		_albedo_color = lerp(_albedo_color , snow_color.rgb,  splat_map.a);
	#endif
	
	pp_modifiable.albedo_color = _albedo_color;
}

void compute_outer_mesh_albedo_color(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , 
inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	#if SPLAT_TEXTURE_BLENDING
		compute_outer_mesh_albedo_color_aux(In, pp_static, pp_modifiable, pp_aux);
	#else
		calculate_albedo_standart(In, pp_static, pp_modifiable, pp_aux);
	#endif
}

#endif

#endif
