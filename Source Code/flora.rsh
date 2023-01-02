#ifndef _FLORA_RSH
#define _FLORA_RSH

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"

struct VS_OUTPUT_FLORA
{
	float4 Pos					: RGL_POSITION;
	
	//TODO_PERF_SHADERS: optimize!
	float4 vertex_color				: COLOR0;
	float2 tex_coord				: TEXCOORD0;
	float fade_out_randomness		: TEXCOORD1;
	float4 shadow_tex_coord			: TEXCOORD2;
	float4 dynamic_shadow_tex_coord	: TEXCOORD3;	
	float3 view_direction			: TEXCOORD4;
	float3 world_normal				: TEXCOORD5;

	
	#if VDECL_HAS_TANGENT_DATA
		float4 world_tangent			: TEXCOORD6;
		float4 world_binormal			: TEXCOORD7;
	#endif 

	float4 world_position			: TEXCOORD8;
	float3 albedo_multiplier_center_position :TEXCOORD9;
};

#if PIXEL_SHADER
#if (VERTEX_DECLARATION != VDECL_POSTFX)	
void calculate_alpha_flora(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 tex_col = pp_modifiable.diffuse_sample;// sample_diffuse_texture_biased(In, anisotropic_sampler, In.tex_coord.xy);

	float early_alpha = 1;
	//TODO_GOKHAN0 hot fix
#if !SYSTEM_INSTANCING_ENABLED
	In.vertex_color.a = 1.0f;
#endif

#if defined(SHADOWMAP_PASS) || defined(SYSTEM_DEPTH_PREPASS) 
#ifdef USE_SMOOTH_FLORA_LOD_TRANSITION
	dithered_fade_out(pp_static.screen_space_position, In.vertex_color.a);
#endif
#endif
	
	//diffuse texture alpha
	{
		early_alpha *= tex_col.a * g_mesh_factor_color.a;
	}

	//flora fading out
	{
		const bool apply_fading_out = g_fade_out_distance > 0;
		if(apply_fading_out)
		{
			float fade_distance = FLORA_DEFULT_FADEOUT_DISTANCE - g_fade_out_distance;
			float rand_0_1 = (sin(pp_static.world_space_position.x * 100 + pp_static.world_space_position.y * 35) + 0.5f) * 0.5f;
			float random_0_20 = 20 * rand_0_1;
			float fading_alpha = saturate((fade_distance - (pp_static.view_length + random_0_20))/10);		

			early_alpha *= fading_alpha;
		}
	}

	pp_modifiable.early_alpha_value = early_alpha;

#ifdef SYSTEM_TEXTURE_DENSITY
	pp_modifiable.early_alpha_value = 1.0;
#endif
}

#ifndef SHADOWMAP_PASS
void calculate_normal_flora(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	//TODO_BURAK : ASSERT !SKINNED  FLORA SHADERS

	float3 normal = normalize(In.world_normal.xyz);

#if SYSTEM_INSTANCING_ENABLED && (my_material_id == MATERIAL_ID_FLORA)
	float3 z_projection_coord = In.albedo_multiplier_center_position.xyz;
#else
	float3 z_projection_coord = get_column(g_world, 3).xyz;
#endif
	float translucency = sample_specular_texture(In.tex_coord.xy).a;
	bool bark = translucency < 0.05;

	{
#if SYSTEM_TWO_SIDED_RENDER
		normal.xyz *= In.is_fronface ? 1 : -1;
#endif
		normal = normalize(lerp(normal, normalize(In.world_position.xyz - z_projection_coord), bark ? 0.0 : saturate(g_mesh_vector_argument.x)));
	}

	pp_modifiable.vertex_normal = normal;
	
	#if VDECL_HAS_TANGENT_DATA
		float3 world_binormal = normalize(cross(normal, In.world_tangent.xyz)) * In.world_tangent.w;
		float3x3 TBN = create_float3x3(In.world_tangent.xyz, world_binormal.xyz, normal);
		normal = (mul(pp_modifiable.normal_sample, TBN));
	#else
		normal = In.world_normal.xyz;
	#endif
	
	pp_modifiable.world_space_normal = normal.xyz;

}

void calculate_albedo_flora(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 tex_col = pp_modifiable.diffuse_sample;// sample_diffuse_texture_biased(In, anisotropic_sampler, In.tex_coord.xy);

	pp_modifiable.albedo_color.rgb = tex_col.rgb * In.vertex_color.rgb;
	
#if SYSTEM_RAIN_LAYER
			float _wetness_amount = saturate(g_rain_density);
			pp_modifiable.albedo_color.rgb *= lerp(1.0, 0.5, _wetness_amount);
#endif
	
	#ifdef SYSTEM_TEXTURE_DENSITY
		pp_modifiable.albedo_color.rgb = checkerboard(tex_col, In.tex_coord, diffuse_texture, true, In.world_position.xyz);
	#endif

	float translucency = sample_specular_texture(In.tex_coord.xy).a;
	bool bark = translucency < 0.05;

#if SYSTEM_INSTANCING_ENABLED  && (my_material_id == MATERIAL_ID_FLORA)
		float3 z_projection_coord = In.albedo_multiplier_center_position.xyz; 
#else
		float3 z_projection_coord = get_column(g_world, 3).xyz;
#endif


#if defined(WORLDMAP_TREE) && !defined(SHADOWMAP_PASS)
		float2 world_texcoord = In.world_position.xy * g_terrain_size_inv;
		world_texcoord.y = 1 - world_texcoord.y;

		float2 dynamic_terrain_params = float2(g_dynamic_terrain_params.x, g_dynamic_terrain_params.y);

		float noise = smoothstep(0.4, 0.6, global_random_texture.SampleLevel(linear_sampler, world_texcoord * 30, 0).x) * 0.5;
		float grad_value = texture8.SampleLevel(linear_sampler, world_texcoord, 0).r;
		grad_value = smoothstep((dynamic_terrain_params.x) - dynamic_terrain_params.y, (dynamic_terrain_params.x) + dynamic_terrain_params.y, grad_value);  // TODO_OZGUR000

		grad_value = lerp(0, lerp(noise, 1, grad_value) * grad_value, grad_value);
		grad_value = saturate(smoothstep(0.48, 0.5, grad_value));
		pp_aux.worldmap_snow_mask = 1 - grad_value;

		float3 snow_layer_diffuse = texture1.Sample(anisotropic_sampler, In.tex_coord.xy).rgb;
		INPUT_TEX_GAMMA(snow_layer_diffuse);

		grad_value = grad_value * smoothstep(0.1, 1.0, pp_modifiable.world_space_normal.z);

		pp_modifiable.albedo_color = lerp(pp_modifiable.albedo_color, snow_layer_diffuse, grad_value);
#endif


#if ALBEDO_MULTIPLIER_PROJECTION 
	#ifdef WORLDMAP_TREE
		float3 tex = texture7.Sample(linear_sampler, z_projection_coord.xy * g_terrain_size_inv).rgb;
		pp_modifiable.albedo_color.rgb = blendOverlay(pp_modifiable.albedo_color.rgb, tex, bark ? 0.0 : pp_aux.worldmap_snow_mask);
#else
		float3 tex = sample_diffuse2_texture(z_projection_coord.xy * g_terrain_size_inv).rgb;
	pp_modifiable.albedo_color.rgb = blendOverlay(pp_modifiable.albedo_color.rgb, lerp(0.12, 0.8, tex), bark ? 0.0 : 1.0);
#endif
#endif
}

void calculate_ao_flora_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = In.world_normal.w;

	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
 		pp_modifiable.ambient_ao_factor *= sample_specular_texture(In.tex_coord.xy).b * g_ambient_occlusion_coef;
	}
}

void calculate_ao_flora_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = In.world_normal.w;

	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
 		pp_modifiable.ambient_ao_factor *= sample_specular_texture(In.tex_coord.xy).b;
	}

	compute_occlusion_factors_forward_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, In.world_position.xyz, pp_static.screen_space_position, In.tex_coord.xy, In.vertex_color);

}

void calculate_specular_flora(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 _specularity_info = 0;

	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
 	#if USE_SPECULAR_FROM_DIFFUSE
		_specularity_info.x = max((pp_modifiable.albedo_color.x + pp_modifiable.albedo_color.y + pp_modifiable.albedo_color.z) * 0.33, 0.01);
		_specularity_info.y = max((pp_modifiable.albedo_color.x + pp_modifiable.albedo_color.y + pp_modifiable.albedo_color.z) * 0.33, 0.01);
	#else
		float4 specular = sample_specular_texture(In.tex_coord.xy);
		_specularity_info = specular.rg;
	#endif
	_specularity_info.x = saturate(_specularity_info.x * g_specular_coef);
	_specularity_info.y = saturate(_specularity_info.y * g_gloss_coef);
#if USE_TRANSLUCENCY_MAP
		pp_modifiable.translucency = specular.a;
#endif

#if WORLDMAP_TREE
#if SYSTEM_INSTANCING_ENABLED 
		float3 z_projection_coord = In.albedo_multiplier_center_position.xyz;
#else
		float3 z_projection_coord = get_column(g_world, 3).xyz;
#endif
		pp_modifiable.translucency = pow(max(0, length(In.world_position.xyz - z_projection_coord) / g_bounding_radius), 10.0f);
#endif
	}

	pp_modifiable.specularity = _specularity_info;
}

void calculate_specular_flora_bark(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 _specularity_info = 0;

	if (HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
#if USE_SPECULAR_FROM_DIFFUSE
		_specularity_info.x = max((pp_modifiable.albedo_color.x + pp_modifiable.albedo_color.y + pp_modifiable.albedo_color.z) * 0.33, 0.01);
		_specularity_info.y = max((pp_modifiable.albedo_color.x + pp_modifiable.albedo_color.y + pp_modifiable.albedo_color.z) * 0.33, 0.01);
#else
		float3 specular = pp_modifiable.specular_sample.rgb;
		_specularity_info = specular.rg;
#endif
		_specularity_info.x = saturate(_specularity_info.x * g_specular_coef);
		_specularity_info.y = saturate(_specularity_info.y * g_gloss_coef);
#if USE_TRANSLUCENCY_MAP
		pp_modifiable.translucency = 0;
#endif
	}

	pp_modifiable.specularity = _specularity_info;
	pp_modifiable.specularity.x = 0;
}
#endif
#endif
#endif
#endif