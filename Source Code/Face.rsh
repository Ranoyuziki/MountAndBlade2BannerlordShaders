#ifndef FACE_RSH
#define FACE_RSH

#if PIXEL_SHADER

#ifdef ENABLE_GPU_MORPH_ANIMATIONS
	#define HAS_GPU_FACE_ANIMATION 1
#endif

#ifndef Pixel_shader_input_type
	#define Pixel_shader_input_type VS_OUTPUT_STANDART
#endif


#define TATTOOED_FACE 1

#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"	 


float Fresnel(float3 hlf, float3 view, float f0)
{
	float base = max(0.000001f, 1.0 - dot(view, hlf));
	float exponential = pow(base, 5.0);
	return exponential + f0 * (1.0 - exponential);
}




float beckmannDistribution(float x, float roughness) {
	float NdotH = max(x, 0.0001);
	float cos2Alpha = NdotH * NdotH;
	float tan2Alpha = (cos2Alpha - 1.0) / cos2Alpha;
	float roughness2 = roughness * roughness;
	float denom = 3.141592653589793 * roughness2 * cos2Alpha * cos2Alpha;
	return exp(tan2Alpha / roughness2) / denom;
}

float SpecularKSK(float3 normal, float3 light, float3 view, float roughness)
{
	float3 hlf = view + light;
	float3 halfn = normalize(hlf);

	float ndotl = max(dot(normal, light), 0.0);
	float ndoth = max(dot(normal, halfn), 0.0);

	float specularFresnel = 0.82;
	float ph = beckmannDistribution(ndoth, roughness);
	float f = lerp(0.25, Fresnel(halfn, view, 0.028), specularFresnel);
	float ksk = max(ph * f / max(dot(hlf, hlf), 0.01), 0.0);

	return ndotl * ksk;   
}

float3 compute_face_lighting(float2 specularity_info, float3 albedo_color, 
	float3 light_color, float light_amount, float3 world_space_normal, float3 view_direction, float3 light_direction, 
	float3 world_space_position, float diffuse_ao_factor, float3 diffuse_ndotl)
{
	light_direction = normalize(light_direction);
	world_space_normal = normalize(world_space_normal);
	float3 diffuse_light = albedo_color.rgb * diffuse_ao_factor;

	float roughness = saturate(1.0 - specularity_info.y);
	float reflectivity = specularity_info.x;

	float3 specular_color = SpecularKSK(world_space_normal, light_direction, view_direction, roughness) * reflectivity;
	float3 diffuse_color = (diffuse_light * diffuse_ndotl);
	float3 result_color = (specular_color * diffuse_ao_factor + diffuse_color) * light_amount * light_color.rgb;

	return result_color;
}

float3 compute_diffuse_face_lighting(float3 albedo_color, float3 light_color, float light_amount, float diffuse_ao_factor, float3 diffuse_ndotl)
{
	float3 diffuse_light = 1;
	float3 diffuse_color = (diffuse_light * diffuse_ndotl);
	float3 result_color = diffuse_color * light_amount * light_color.rgb / RGL_PI;

	return result_color;
}

float3 compute_specular_face_lighting(inout Pixel_shader_input_type In, float2 specularity_info, float3 light_color, float light_amount, float3 world_space_normal, float3 view_direction, float3 light_direction,
									  float3 world_space_position, float diffuse_ao_factor)
{
	light_direction = normalize(light_direction);
	world_space_normal = normalize(world_space_normal);

	float roughness = max(0.05, saturate(1.0 - specularity_info.y));
	float reflectivity = specularity_info.x * 5.0f;

	float3 specular_color = SpecularKSK(world_space_normal, light_direction, view_direction, roughness) * reflectivity;
	float3 result_color = specular_color * light_amount * light_color.rgb  / RGL_PI;

	return result_color;
}



PS_OUTPUT main_ps_standart_face_mod( VS_OUTPUT_STANDART In, const bool is_lod )
{
	PS_OUTPUT Output;

#ifdef SYSTEM_SHOW_VERTEX_COLORS
	{
		Output.RGBColor.rgba = In.vertex_color.rgba;
		return Output;
	}
#endif

	return Output;
}

#endif

#endif
