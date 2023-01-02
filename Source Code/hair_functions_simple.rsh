#ifndef HAIR_FUNCTIONS_SIMPLE_RSH
#define HAIR_FUNCTIONS_SIMPLE_RSH

#if VERTEX_SHADER
//main vertex shader functions for simple hair
void calculate_object_space_values_hair(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float4 object_position;
	float3 object_tangent, object_binormal, object_normal, prev_object_position, object_color;
	
	rgl_vertex_transform_with_binormal(In, object_position, object_normal, object_tangent, object_binormal, prev_object_position, object_color);
	
	output.position = mul(g_view_proj, mul(g_world, object_position));
	
	pv_modifiable.object_position = object_position;
	pv_modifiable.object_normal = object_normal;
	pv_modifiable.object_tangent = object_tangent;
	pv_modifiable.prev_object_position = prev_object_position;
}
void calculate_world_space_values_hair(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	float4 world_position = mul(g_world, pv_modifiable.object_position);
	pv_modifiable.world_normal.rgb = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal).xyz); //normal in g_world space
	
	output.world_position.xyz = world_position.xyz;

#if ENABLE_DYNAMIC_INSTANCING
	output.world_position.w = In.instanceID + INDEX_EPSILON;
#endif
}
void calculate_render_related_values_hair(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
	output.tex_coord = In.tex_coord;
	float3 diffuse_light = g_ambient_color.rgb;

	float3 skylight_direction = float3(g_sun_direction_inv.x, g_sun_direction_inv.y, -g_sun_direction_inv.z);
	diffuse_light.rgb += saturate(dot(pv_modifiable.world_normal.xyz, -skylight_direction.xyz)) * g_sun_color.rgb * 0.1;

	output.vertex_color = get_vertex_color(In.color);
		
	output.Color.rgb = output.vertex_color.r * diffuse_light.rgb;
	output.Color.a = output.vertex_color.a;

	//shadow mapping variables
	float wNdotSun = dot(pv_modifiable.world_normal.xyz, g_sun_direction_inv.xyz);
	output.SunLight.rgb = g_sun_color.rgb * max(0.2f * (wNdotSun + 0.9f),wNdotSun) * output.vertex_color.r;
}
#endif

#if PIXEL_SHADER
float3 compute_hair_albedo(inout Pixel_shader_input_type In, float3 diffuse_texture_color, float4 vertex_color, float2 tex_coord)
{
	float3 hairBaseColor = g_mesh_factor_color.rgb;
	float old_texture_color = dot(diffuse_texture_color.rgb, LUMINANCE_WEIGHTS);

	float oldness = (1.0f - g_mesh_factor2_color.a);
	float oldness_alpha = saturate(((2.1f * oldness) + old_texture_color*(old_texture_color + vertex_color.b)) - 1.6f);

	float3 albedo = diffuse_texture_color;
	albedo.rgb *= hairBaseColor;
	albedo.rgb *= (1.0f - oldness_alpha);
	albedo.rgb += old_texture_color * oldness_alpha;


#ifdef SYSTEM_TEXTURE_DENSITY
	albedo.rgb = checkerboard(albedo, tex_coord.xy, diffuse_texture, false, In.world_space_position.xyz);
#endif

	return albedo;
}

//main pixel shader functions for simple hair
void calculate_alpha_hair(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float4 diffuse_texture_color_ = sample_diffuse_texture_biased(In, anisotropic_sampler, In.tex_coord);
	
	pp_modifiable.early_alpha_value = In.Color.a * diffuse_texture_color_.a;

#if USE_SMOOTH_FADE_OUT
	dithered_fade_out(pp_static.screen_space_position, g_mesh_factor_color.a);
#endif

}

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void calculate_final_pbr_hair(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	float4 diffuse_texture_color_ = sample_diffuse_texture_biased(In, anisotropic_sampler, In.tex_coord);
	Output.RGBColor.a *= g_mesh_factor_color.a;
	
	float tex2_col = dot(diffuse_texture_color_.rgb, LUMINANCE_WEIGHTS);
	
	INPUT_TEX_GAMMA(diffuse_texture_color_.rgb);

	float3 final_albedo_color_ = compute_hair_albedo(In, diffuse_texture_color_.rgb, In.vertex_color, In.tex_coord);
	
	float3 total_light = In.Color.rgb;
	float sun_amount = compute_sun_amount_from_cascades(In.world_position.xyz, In.position);

	Output.RGBColor.rgb =  final_albedo_color_.rgb * (total_light.rgb + In.SunLight.rgb * sun_amount);
	
	apply_advanced_fog(Output.RGBColor.rgb, In.world_position.xyz);	
	
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
}
#endif
#endif

#endif
