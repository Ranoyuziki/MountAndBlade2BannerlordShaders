#ifndef FLORA_SHADING_FUNCTIONS_RSH
#define FLORA_SHADING_FUNCTIONS_RSH

#include "shadow_functions.rsh"
#include "ambient_functions.rsh"
#include "atmosphere_functions.rsh"

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_flora_billboard(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	float sun_amount = compute_sun_amount_from_cascades(pp_static.world_space_position.xyz, pp_static.screen_space_position);

	float NdotL = saturate(dot(g_sun_direction_inv, pp_modifiable.world_space_normal));
	float3 view_dir = normalize(pp_static.world_space_position.xyz - g_camera_position.xyz);
	float SdotV = -dot(g_sun_direction_inv, view_dir);

	float sky_visibility;
	float3 ambient_light = get_ambient_term_with_skyaccess(pp_static.world_space_position.xyz, pp_modifiable.world_space_normal, pp_static.screen_space_position, sky_visibility);
	float scatter_strength = saturate(-SdotV);
	scatter_strength *= scatter_strength;
	float3 transluceny_term = 3.0f * scatter_strength; //We multiply with diffuse color to give the effect oplight passing through and taking the color of the material 
	float3 sun_light = sun_amount * g_sun_color.rgb;
	float translucency = 0.08;
	float3 translucency_light = translucency * transluceny_term;
	float3 diffuse_light = NdotL * pp_modifiable.diffuse_ao_factor;
	float3 final_color = pp_modifiable.albedo_color.rgb  * (ambient_light * pp_modifiable.ambient_ao_factor + sun_light * (diffuse_light + translucency));
	float3 view_direction_unorm = g_camera_position.xyz - pp_static.world_space_position.xyz;
	float3 view_direction = normalize(view_direction_unorm);

	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);

	if (bool(USE_SHADOW_DEBUGGING))
	{
		int index = compute_shadow_index(pp_static.world_space_position);

		if (index == 4)
		{
			final_color.rgb = float3(1, 1, 1);
		}
		else if (index == 3)
		{
			final_color.rgb = float3(1, 0, 1);
		}
		else if (index == 2)
		{
			final_color.rgb = float3(0, 0, 1);
		}
		else if (index == 1)
		{
			final_color.rgb = float3(0, 1, 0);
		}
		else
		{
			final_color.rgb = float3(1, 0, 0);
		}
	}

	Output.RGBColor.rgb = output_color(final_color);
	Output.RGBColor.a = pp_modifiable.early_alpha_value;
}

void calculate_final_flora(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	float sun_amount = 1.0f;
	direct_lighting_info l_info = get_lighting_info(pp_static.world_space_position, pp_static.screen_space_position);
	sun_amount = l_info.light_amount;

	float3 normal = pp_modifiable.world_space_normal.rgb;

	float3 In_Color;
	float3 In_SunLight;

	float3 view_dir = normalize(pp_static.world_space_position - g_camera_position.xyz);
	
	float3 specular_ambient_term;
	float3 diffuse_ambient_term;

	float sky_visibility = 1.0f;

	get_ambient_terms(pp_static.world_space_position, pp_modifiable.world_space_normal, pp_modifiable.world_space_normal, pp_static.screen_space_position.xy,
		pp_static.view_vector, float2(0, 0), pp_modifiable.albedo_color, l_info.light_amount,
		specular_ambient_term, diffuse_ambient_term, sky_visibility);

	float3 ambient_light = pp_modifiable.albedo_color.rgb * diffuse_ambient_term;
	ambient_light *= 1.0 - (0.08 * pp_modifiable.specularity.x);
	ambient_light += specular_ambient_term;

	float4 specular_color = 0;
	specular_color = float4(pp_modifiable.specularity, 1, 1);
	specular_color.xy *= (1.0 - saturate((pp_static.view_length - 20) / 80.0f));

	float translucency = pp_modifiable.translucency;

	bool bark = translucency < 0.05;

	float wrap_ndotl = bark ? 0 : 0.5;
	float NdotL = max(0, (dot(g_sun_direction_inv, normal) + wrap_ndotl) / (1 + wrap_ndotl));

	float wrap_sdotv = 0.15;
	float SdotV = max(0, (dot(g_sun_direction_inv, view_dir) + wrap_sdotv) / (1 + wrap_sdotv));

	float SdotVinv = max(0, (dot(g_sun_direction_inv, -view_dir) + wrap_sdotv) / (1 + wrap_sdotv));


	ambient_light = ambient_light * pp_modifiable.ambient_ao_factor;


	float3 sun_light = sun_amount * g_sun_color.rgb;

	float3 translucency_light = 2.0 * translucency * max(0.01, sun_amount) * g_sun_color.rgb  * SdotV * pp_modifiable.ambient_ao_factor;
	float3 subsurface_light = translucency * g_sun_color.rgb * min(0.1, 1.0 - sun_amount) * NdotL * pp_modifiable.ambient_ao_factor;
	float3 diffuse_light = sun_light * (1.0 - translucency * SdotV) * NdotL * pp_modifiable.ambient_ao_factor;

	float3 total_light = (diffuse_light + subsurface_light + translucency_light) / RGL_PI;
	float3 final_color = pp_modifiable.albedo_color.rgb  * total_light + ambient_light;

	{
		float min_spec = 0.08 * specular_color.x;
		float3 reconstructed_pixel_specular_color = lerp(float3(min_spec, min_spec, min_spec), pp_modifiable.albedo_color, 0);
		view_dir = -view_dir;

		float3 half_vector = normalize(view_dir + g_sun_direction_inv);
		float NdotH = saturate(dot(normal, half_vector));
		float VdotH = saturate(dot(view_dir, half_vector));
		float NdotV = saturate(dot(normal, view_dir));
		float NdotL2 = saturate(dot(g_sun_direction_inv, normal));

		float3 F = reconstructed_pixel_specular_color + (1.0f - reconstructed_pixel_specular_color) * pow((1.0 - VdotH), 5);
		//NDF ndotl and ndotv omitted because of cook torrance's denominator
		float roughness = 1.0f - specular_color.y;
		roughness = max(1e-6, roughness);
		float alpha = roughness * roughness;
		float alpha_sqr = alpha * alpha;
		float ndoth_sqr = NdotH * NdotH;
		float D = alpha_sqr;
		float denominator = (ndoth_sqr * (alpha_sqr - 1) + 1);
		denominator *= denominator;
		denominator = max(denominator, 1e-6);
		D = D / denominator;

		//Hotness remapping for grazing angles Burley 2012
		float alphag = (0.5 + roughness * 0.5);
		alphag *= alphag;
		float k = alphag * 0.5;
		float G_L = 1.0f / (NdotL2 * (1.0 - k) + k);
		float G_V = 1.0f / (NdotV * (1.0 - k) + k);
		float G = G_L * G_V;

		float3 specular_light = D * G * F;
		specular_light = specular_light / (4.0 * RGL_PI);
		final_color += specular_light * sun_light * NdotL2;
		//final_color = NdotL2;

	}

	//final_color = pp_modifiable.ambient_ao_factor;
	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, sky_visibility);
	//Output.RGBColor.rgb = Output.RGBColor.a;
	//Output.RGBColor.a = 1;a

	if (bool(USE_SHADOW_DEBUGGING))
	{
		int index = compute_shadow_index(pp_static.world_space_position);

		if (index == 4)
		{
			final_color.rgb = float3(1, 1, 1);
		}
		else if (index == 3)
		{
			final_color.rgb = float3(1, 0, 1);
		}
		else if (index == 2)
		{
			final_color.rgb = float3(0, 0, 1);
		}
		else if (index == 1)
		{
			final_color.rgb = float3(0, 1, 0);
		}
		else
		{
			final_color.rgb = float3(1, 0, 0);
		}
	}
	Output.RGBColor.rgb = final_color;//final_color;//normal.xyz * 0.5 + 0.5;
	Output.RGBColor.a = pp_modifiable.early_alpha_value;

	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
}
#endif

#endif //_FLORA_RSH
