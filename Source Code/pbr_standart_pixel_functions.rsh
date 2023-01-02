#ifndef PBR_STANDART_PIXEL_FUNCTIONS_RSH
#define PBR_STANDART_PIXEL_FUNCTIONS_RSH

#include "terrain_mesh_blend_functions.rsh"

void apply_map_circle_input_modifier(inout Pixel_shader_input_type input)
{
	PS_OUTPUT Output;
	input.tex_coord = saturate(input.tex_coord);
}

//3d mesh modifier delegates
void get_contour(float2 tc, inout float contour, float weight)
{
	float neighbor_alpha = sample_diffuse_texture(anisotropic_sampler, tc).a;
	if(neighbor_alpha > 0.0f)
	{
		//		contour = max(contour, weight); //this makes the contour look thicker
		contour = contour + weight * neighbor_alpha;
	}
}

void draw_contour_to_edge(Pixel_shader_input_type In, float2 texture_coord, inout float4 RGBColor)
{
	const float pixel_size = g_mesh_vector_argument.x;

	if(RGBColor.a < 1)
	{
		float tex_col_a = RGBColor.a;
		const float tex_col_org_a = RGBColor.a;

		float contour = 0;
		{
			{
				{
					get_contour(texture_coord + float2(0, 1) * pixel_size, contour, 1.0f);
					get_contour(texture_coord + float2(0, -1) * pixel_size, contour, 1.0f);
					get_contour(texture_coord + float2(1, 0) * pixel_size, contour, 1.0f);
					get_contour(texture_coord + float2(-1, 0) * pixel_size, contour, 1.0f);
					get_contour(texture_coord + float2(1, 1) * pixel_size, contour, 0.7f);
					get_contour(texture_coord + float2(1, -1) * pixel_size, contour, 0.7f);
					get_contour(texture_coord + float2(-1, 1) * pixel_size, contour, 0.7f);
					get_contour(texture_coord + float2(-1, -1) * pixel_size, contour, 0.7f);
				}
			}
		}

		if(contour > (1.0f - tex_col_org_a))
		{
			contour = (1.0f - tex_col_org_a);
		}
		RGBColor.a = saturate(contour + tex_col_org_a);
		float3 contour_color = float3(0, 0, 0);
		RGBColor.rgb = (contour_color * contour + RGBColor.rgb * tex_col_org_a) / (contour + tex_col_org_a);

	}
}

void banner_background_color_calculater(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	Output.RGBColor = In.vertex_color;

	Output.RGBColor.rgb = lerp(g_mesh_factor_color.rgb, g_mesh_factor2_color.rgb, Output.RGBColor.r);
	Output.RGBColor.a = 1;
	//Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);

	//Output.RGBColor.a  = Output.RGBColor.r;
	//Output.RGBColor.rgb *= g_mesh_factor_color.rgb;
	//Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
}

void apply_contour_to_edge_output_modifier(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux, inout PS_OUTPUT Output)
{
	float2 tc = In.tex_coord.xy;
	draw_contour_to_edge(In, tc, Output.RGBColor);
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS)
void fresnel_shader_output(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float3 final_color = pp_modifiable.albedo_color * g_mesh_vector_argument.y;

	float fresnel_term = saturate(dot(pp_static.view_vector.xyz, pp_modifiable.world_space_normal.xyz));
	fresnel_term = pow(fresnel_term, g_mesh_vector_argument.x);
	final_color = lerp(g_mesh_factor2_color.rgb, final_color, fresnel_term);

	Output.RGBColor.rgb = final_color.rgb;
	Output.RGBColor.a = In.vertex_color.a;
}
#endif

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS)
void laser_shader_output(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float3 final_color = g_mesh_factor_color.rgb * g_mesh_vector_argument.w;
	float total_len = length(get_column(g_world, 1));
	float3 up = normalize(get_column(g_world, 1).xyz);
	float3 view = normalize(pp_static.view_vector.xyz);

	float3 a1 = get_column(g_world, 3).xyz;
	float3 a2 = g_camera_position.xyz;

	float3 n = cross(up, view);
	n = normalize(n);
	float dst = 1 - saturate(abs(dot(a1 - a2, n)) * 2 / total_len);
	float alpha = pow(dst, g_mesh_vector_argument.x);
	float mid_value = smoothstep(g_mesh_vector_argument.z, 1.0, pow(dst, g_mesh_vector_argument.y));

	float3 mid_color = g_mesh_factor2_color.rgb * g_mesh_vector_argument.w;

	final_color = lerp(final_color, mid_color, mid_value);

	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, 1.0f);

	Output.RGBColor.rgb = output_color(final_color.rgb);
	Output.RGBColor.a = alpha;// In.vertex_color.a;
}
#endif

//gui functionalities
void calculate_gui_color_and_stroke(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float4 final_color = sample_diffuse_texture(anisotropic_sampler, In.tex_coord.xy);
	INPUT_TEX_GAMMA(final_color.rgb);

	float3 color = g_mesh_factor_color.rgb;
	float3 stroke_color = g_mesh_factor2_color.rgb;
	float draw_stroke = g_mesh_vector_argument.w;

	final_color.a = final_color.a * (draw_stroke * final_color.r + final_color.g);
	final_color.rgb = (stroke_color.xyz * final_color.r) + (color.xyz * final_color.g);

	Output.RGBColor = final_color;
	apply_alpha_test(In, Output.RGBColor.a);

	//Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
}

void calculate_gui_horizantol_progess(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float4 color;
	float ratio = g_mesh_vector_argument.y;
	if(In.tex_coord.x < ratio)
	{
		color = g_mesh_factor_color;
	}
	else
	{
		color = g_mesh_factor2_color;
	}

	Output.RGBColor = float4(color.rgb, 1);
}

void calculate_gui_progess(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float4 _diffuse_color = sample_diffuse_texture(anisotropic_sampler, In.tex_coord.xy).rgba;
	INPUT_TEX_GAMMA(_diffuse_color.rgb);

	float4 final_color = In.vertex_color.rgba * _diffuse_color.rgba;
	apply_alpha_test(In, final_color.a);

	Output.RGBColor = final_color;
	float ratio = g_mesh_vector_argument.y;

	if(Output.RGBColor.a != 0.0f)
	{
		if(Output.RGBColor.r <= ratio)
		{
			// foreground color
			Output.RGBColor = g_mesh_factor_color;
		}
		else
		{
			// background color
			Output.RGBColor = g_mesh_factor2_color;
		}
	}

	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);

}

void calculate_gui_circural_progress_realtime(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float ratio = frac(g_time_var.x* 0.1);
	float2 center = float2(0.5f, 0.5f);
	float2 diffVector = center - In.tex_coord.xy;
	float length_sqr = diffVector.x*diffVector.x + diffVector.y*diffVector.y;
	float angle = atan2(diffVector.y, diffVector.x) + RGL_PI; // translate result btw 0-2PI

	if(length_sqr < 0.43f*0.43f && length_sqr > 0.355f*0.355f)
	{
		if(angle < ratio * RGL_TWO_PI)
		{
			In.vertex_color = float4(1, 0, 1, 1) * length_sqr * 5;
			In.vertex_color.a = g_mesh_factor_color.a;
		}
		else
		{
			In.vertex_color = float4(1, 1, 1, 1);
		}
	}
	else
	{
		In.vertex_color.a = 0;
	}

	Output.RGBColor = In.vertex_color;
}

void calculate_gui_circural_progress(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float ratio = g_mesh_vector_argument.y;
	float2 center = float2(0.5f, 0.5f);
	float2 diffVector = center - In.tex_coord.xy;
	float length_sqr = diffVector.x*diffVector.x + diffVector.y*diffVector.y;
	float angle = atan2(diffVector.y, diffVector.x) + RGL_PI; // translate result btw 0-2PI

	if(length_sqr < 0.43f*0.43f && length_sqr > 0.355f*0.355f)
	{
		if(angle < ratio * RGL_TWO_PI)
		{
			In.vertex_color = float4(1, 0, 1, 1) * length_sqr * 5;
			In.vertex_color.a = g_mesh_factor_color.a;
		}
		else
		{
			In.vertex_color = float4(1, 1, 1, 1);
		}
	}
	else
	{
		In.vertex_color.a = 0;
	}

	Output.RGBColor = In.vertex_color;
}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS)
void vertex_color_shader_output(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT Output)
{
	float3 final_color = In.vertex_color.rgb;
	apply_advanced_fog(final_color.rgb, pp_static.view_vector, pp_static.view_vector_unorm.z, pp_static.view_length, 1.0f);

	Output.RGBColor.rgb = output_color(final_color.rgb);
	Output.RGBColor.a = pp_modifiable.early_alpha_value;
}
#endif

//main pixel shader functions
void calculate_alpha_standart(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float diffuse_alpha = 1.0f;
	float early_alpha_value = 1.0f;

#if !USE_SMOOTH_FADE_OUT
	early_alpha_value *= g_mesh_factor_color.a;
#endif

#if (my_material_id != MATERIAL_ID_TERRAIN)
	if(USE_TABLEAU_BLENDING)
	{
#if VDECL_HAS_DOUBLEUV
		float2 banner_tex_coord = In.tex_coord.zw;
		bool blend_with_banner = (saturate(banner_tex_coord.x) == banner_tex_coord.x) && (saturate(banner_tex_coord.y) == banner_tex_coord.y);
		if(!blend_with_banner)
		{
			diffuse_alpha = sample_diffuse2_texture(In.tex_coord.xy).a;
		}
#endif
		if (USE_TABLEAU_MASK_AS_SEPARATE_TEXTURE)
		{
			diffuse_alpha = pp_modifiable.diffuse_sample.a;
		}
	}
	else
	{
		diffuse_alpha = pp_modifiable.diffuse_sample.a;
	}

#if !defined(STANDART_FOR_CRAFT) && !defined(SYSTEM_SHOW_VERTEX_COLORS)
#if (!USE_PROCEDURAL_WIND_ANIMATION) && (!SYSTEM_CLOTH_SIMULATION_ENABLED) && (!SYSTEM_INSTANCING_ENABLED)
	if(!HAS_MATERIAL_FLAG(g_mf_disable_vertex_color_alpha))
	{
		early_alpha_value *= In.vertex_color.a;
	}
#endif
#endif

	if(!HAS_MATERIAL_FLAG(g_mf_do_not_use_alpha))
	{
#ifndef STANDART_FOR_CRAFT
		early_alpha_value *= diffuse_alpha;
#endif
	}
#endif

#if defined(USE_PROCEDURAL_MULTI_MATERIAL) && !defined(SHADOWMAP_PASS)
	if(g_mesh_vector_argument_2.x >= 0.0)
	{
		float upity = dot(normalize(In.world_normal.xyz), float3(0, 0, 1));
		upity = pow(abs(upity), g_mesh_vector_argument_2.r);
		float height = sample_blood_texture(In.tex_coord.xy).a;
		upity = lerp(upity + 0.3, upity, saturate(height * 2.0 - 1.0));
		early_alpha_value *= saturate(upity);
	}
#endif

#ifdef USE_WEAPON_TRAIL
	early_alpha_value *= smoothstep(2, 4, distance(g_camera_position.xyz, pp_static.world_space_position.xyz));
#endif

#ifndef PBR_DITHERED_COLOR
	//TODO_GOKHAN3 : smooth dithered alpha transition with pbr shading floras
#if USE_SMOOTH_FADE_OUT
#if SYSTEM_INSTANCING_ENABLED
	float smooth_alpha_factor = In.vertex_color.a;
#else
	float smooth_alpha_factor = g_mesh_factor_color.a;
#endif
	dithered_fade_out(pp_static.screen_space_position, smooth_alpha_factor * early_alpha_value);
#endif
#else
	dithered_fade_out(pp_static.screen_space_position, In.vertex_color.a * early_alpha_value);
#endif

	pp_modifiable.early_alpha_value = early_alpha_value;

#ifdef SYSTEM_TEXTURE_DENSITY
	pp_modifiable.early_alpha_value = 1.0;
#endif
}

#ifndef SHADOWMAP_PASS

float3 blend_rnm_pd(float2 n1, float2 n2)
{
	float3 t = float3(n1.xy * 2 - 1, 1);
	float3 u = float3(-2 * n2.xy + 1, 1);
	float q = dot(t, t);
	float s = sqrt(q);
	t.z += s;
	float3 r = t * dot(t, u) - u * (q + s);
	return normalize(r);
}

void calculate_normal_standart(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float wetness_amount = 0;
	pp_aux.wetness_value = wetness_amount;


#if SYSTEM_BLOOD_LAYER && !defined(USE_PROCEDURAL_MULTI_MATERIAL) && !defined(USE_MAIN_MAP_SNOW)  && !defined(WORLDMAP_TREE) && !defined(OUTER_MESH_RENDERING) // Multimaterial uses same slots as blood texture slots for second material, so cannot be used
	float4 decal_albedo_alpha = float4(0, 0, 0, 0);
	float3 decal_normal = float3(0, 0, 0);
	float2 decal_specularity = float2(0, 0);
	float4 blood_normalTS_amount = float4(0, 0, 0, 0);
	compute_blood_amount(In, decal_albedo_alpha, decal_normal, decal_specularity, In.local_position.xyz, In.local_normal);
	pp_aux.decal_albedo_alpha = decal_albedo_alpha;
	pp_aux.decal_normal = decal_normal;
	pp_aux.decal_specularity = decal_specularity;
#endif


	float3 _world_space_normal = normalize(In.world_normal.xyz);
	pp_modifiable.vertex_normal = _world_space_normal;
#if VDECL_HAS_TANGENT_DATA
#if USE_OBJECT_SPACE_TANGENT
// 	if (g_debug_vector.x)
// 	{
// 		In.world_tangent.xyz *= -1;
// 	}
	float3 world_binormal = cross(In.world_normal.xyz, normalize(In.world_tangent.xyz)) * In.world_tangent.w;
	float3x3 _TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
#else
	float3x3 _TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord.xy);
#endif
#if USE_PARALLAXMAPPING
	float depth;
	apply_parallax(In, displacement_texture, In.tex_coord.xy, pp_static.view_vector_unorm, _TBN, _world_space_normal, depth, pp_modifiable);
#endif
	float3 normalTS = compute_tangent_space_normal(In, pp_modifiable, In.tex_coord.xy, In.world_normal.xyz);

#if SYSTEM_BLOOD_LAYER && !defined(USE_PROCEDURAL_MULTI_MATERIAL) && !defined(USE_MAIN_MAP_SNOW) && !defined(WORLDMAP_TREE) && !(defined(OUTER_MESH_RENDERING))// Multimaterial uses same slots as blood texture slots for second material, so cannot be used
	{
		if(decal_albedo_alpha.a > 0)
		{
			normalTS.xyz = normalize(normalTS.xyz);
			decal_normal.xyz = normalize(decal_normal.xyz);
			normalTS.xyz = normalize(float3(normalTS.xy + decal_normal.xy * decal_albedo_alpha.a, normalTS.z));
		}

	}
#endif



#ifdef STANDART_FOR_CRAFT
	{
#if VDECL_HAS_DOUBLEUV
		float2 texcoord_to_sample = In.tex_coord.zw * 4.0f;
#else
		float2 texcoord_to_sample = In.tex_coord.xy * 4.0f;
#endif

#if USE_DUAL_SKIN
		float2 mask = sample_texture(SkinMaskMap, linear_sampler, In.tex_coord.xy).rg;
		mask.xy = 1.0f - mask.xy;
		float3 normal0_orj = sample_texture(MultiNormalMap0, anisotropic_sampler, texcoord_to_sample).rgb;
		float3 normal1_orj = sample_texture(MultiNormalMap1, anisotropic_sampler, texcoord_to_sample).rgb;

			float3 normal0 = (2.0f * normal0_orj - 1.0f);
		normal0.xy *= mask.x * 4.0f;
			normal0.z = sqrt(1.0f - saturate(dot(normal0.xy, normal0.xy)));

			float3 normal1 = (2.0f * normal1_orj - 1.0f);
		normal1.xy *= mask.y * 4.0f;
			normal1.z = sqrt(1.0f - saturate(dot(normal1.xy, normal1.xy)));

			normalTS.xyz = blend_rnm_pd(normalTS.xy * 0.5 + 0.5, normal0.xy * 0.5 + 0.5);
			normalTS.xyz = blend_rnm_pd(normalTS.xy * 0.5 + 0.5, normal1.xy * 0.5 + 0.5);
#else
		float mask = sample_diffuse_texture(linear_sampler, In.tex_coord.xy).a;
		mask = 1.0f - mask;
		float3 normal0_orj = sample_texture(MultiNormalMap0, anisotropic_sampler, texcoord_to_sample).rgb;

		float3 normal0 = (2.0f * normal0_orj - 1.0f);
		normal0.xy *= mask.x * 2.0f;
		normal0.z = sqrt(1.0f - saturate(dot(normal0.xy, normal0.xy)));

		normalTS.xyz = blend_rnm_pd(normalTS.xy * 0.5 + 0.5, normal0.xy * 0.5 + 0.5);
#endif

}
#endif

	_world_space_normal = /*In.world_normal.xyz;*/ normalize(mul(normalTS, _TBN));

#endif

	pp_modifiable.world_space_normal = normalize(_world_space_normal);

#if SYSTEM_TWO_SIDED_RENDER
	const bool is_inverted = (dot(cross(get_column(g_world, 0).xyz, get_column(g_world, 1).xyz), get_column(g_world, 2).xyz) < 0) ? In.is_fronface : !In.is_fronface;
	pp_modifiable.world_space_normal *= is_inverted ? -1 : 1;
#endif
}

void calculate_albedo_standart(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	bool left_handed = (In.world_normal.w < 0.0f);
	float4 diffuse_texture_color = 1.0;

	if (!HAS_MATERIAL_FLAG(g_mf_dont_use_albedo_texture))
	{
		diffuse_texture_color = pp_modifiable.diffuse_sample;
	}

	pp_modifiable.albedo_color = compute_albedo_color(In, pp_modifiable, diffuse_texture_color, In.tex_coord, pp_static.world_space_position.xyz, In.vertex_color, left_handed, pp_aux, pp_modifiable.world_space_normal);
	pp_aux.albedo_color_without_effects = pp_modifiable.albedo_color.rgb;
}

void calculate_specularity_standart(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.specularity = compute_specularity(In, pp_modifiable, In.tex_coord.xy, pp_static.world_space_position.xyz, pp_modifiable.world_space_normal.xyz,
		In.vertex_color, pp_aux, pp_modifiable.albedo_color.rgb, pp_aux.albedo_color_without_effects.rgb);

#if USE_TRANSLUCENCY
	pp_modifiable.specularity.x = 0;
	pp_modifiable.translucency = pp_modifiable.specular_sample.x;
#endif
}

void calculate_diffuse_ao_factor_standart_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.ambient_ao_factor = 1.0f;
	pp_modifiable.diffuse_ao_factor = 1.0f;

	compute_occlusion_factors_deferred_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, 0, pp_static.screen_space_position, In.tex_coord.xy, In.vertex_color);

	#if TERRAIN_MESH_BLEND_CAN_BE_USED
	if (g_is_stationary)
	{
		do_procedural_mesh_terrain_blend(In, pp_static, pp_modifiable, pp_aux);
	}
	#endif
}

void calculate_diffuse_ao_factor_standart_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	calculate_diffuse_ao_factor_standart_deferred(In, pp_static, pp_modifiable, pp_aux);

	compute_occlusion_factors_forward_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, 0, pp_static.screen_space_position, In.tex_coord.xy, In.vertex_color);

	/*#if PROCEDURAL_TERRAIN_BLEND && !defined(POINTLIGHT_SHADOWMAP_PASS)
		do_procedural_mesh_terrain_blend(In, pp_static, pp_modifiable, pp_aux);
		pp_modifiable.albedo_color = float3(1,0,1);
	#endif*/

}

#include "ambient_functions.rsh"

void calculate_final_prt_probe(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	Output.RGBColor = g_mesh_factor_color;
}

#endif

#endif //INCLUDE_PBR_STANDART_PIXEL_FUNCTIONS
