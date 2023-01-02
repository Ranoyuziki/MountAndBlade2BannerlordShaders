#ifndef DEFERRED_DECAL_RSH
#define DEFERRED_DECAL_RSH

#include "standart.rsh"
#include "gbuffer_functions.rsh"
#include "parallax_functions.rsh"

#if VERTEX_SHADER
void calculate_render_related_values_deferred_decal(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
}
void calculate_object_space_values_deferred_decal(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{	
}
void calculate_world_space_values_deferred_decal(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
	float4 object_position = float4(In.position, 1.0f);	
	float4 world_position = mul(g_world, object_position);
	Out.position = mul(g_view_proj, world_position);
	Out.ClipSpacePos = Out.position;
	Out.world_position = world_position;
	
	#if ENABLE_DYNAMIC_INSTANCING
		Out.world_position.w = In.instanceID + INDEX_EPSILON;
	#endif
}
#endif

#if PIXEL_SHADER
void sample_textures_deferred_decal(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	In.ClipSpacePos.xy /= In.ClipSpacePos.w;
	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f; 
	tc.y = tc.y * -0.5f + 0.5f; 

	float pixel_depth = sample_texture_level(depth_texture, linear_sampler, tc.xy, 0).x;
	float3 pos = float3(get_ws_position_at_gbuffer(pixel_depth, tc).xy, 0);
	float4 pixel_pos_in_ws = float4(get_ws_position_at_gbuffer(pixel_depth, tc), 1);
	float4 pixel_pos_in_os = mul(g_world_inverse, pixel_pos_in_ws);
	
	//pp_modifiable.early_alpha_value = pixel_pos_in_os.x;
	//return;
	
	float3 distance_vector2 = abs(pixel_pos_in_os.xyz);
	if( !( distance_vector2.x < 1 && distance_vector2.y < 1 && distance_vector2.z < 1) )
	{
		clip(-1);
	}
	
	float2 decal_tex_coord = (pixel_pos_in_os.xy + 1.0) * 0.5;

	float uv_scale_x = g_mesh_vector_argument.x;
	float uv_scale_y = g_mesh_vector_argument.y;
	float uv_offset_x = g_mesh_vector_argument.z;
	float uv_offset_y = g_mesh_vector_argument.w;
	float2 atlassed_texture_coord = float2(decal_tex_coord.x * uv_scale_x + uv_offset_x, decal_tex_coord.y * uv_scale_y + uv_offset_y);

#if USE_PARALLAXMAPPING
	float3 camvec = g_root_camera_position.xyz - pixel_pos_in_ws.xyz;
	const float3 world_matrix_s = get_column(g_world, 0).xyz;
	float3x3 TBN;

	TBN[2] = pp_aux.pixel_normal_in_ws;
	TBN[0] = normalize(world_matrix_s);
	TBN[1] = safe_normalize(cross(TBN[2], TBN[0]));
	TBN[2] = safe_normalize(cross(TBN[0], TBN[1]));
	
	float depth;
	apply_parallax(In, displacement_texture, atlassed_texture_coord, camvec, TBN, pp_aux.pixel_normal_in_ws, depth, pp_modifiable);
#endif

	pp_aux.atlassed_texture_coord = atlassed_texture_coord;

#if ENABLE_VIRTUAL_TEXTURING
	GraniteLookupData virtual_texture_lookup;
	GraniteConstantBuffers virtual_tex_cb;
    virtual_tex_cb.tilesetBuffer = g_streaming_tile_data[g_streaming_tileset_index];
	virtual_tex_cb.streamingTextureBuffer = g_streaming_texture_data[0];
	GraniteTranslationTexture translationTable = { point_sampler, vt_translation_texture };
	float4 virtual_texture_resolve;
	Granite_Lookup_Anisotropic(virtual_tex_cb, translationTable, pp_aux.atlassed_texture_coord.xy, virtual_texture_lookup, virtual_texture_resolve);
	set_virtual_texture_resolve_data(In, pp_modifiable, virtual_texture_resolve);
#endif

	if (!HAS_MATERIAL_FLAG(g_mf_dont_use_albedo_texture))
	{
#if ENABLE_VIRTUAL_TEXTURING
		pp_modifiable.diffuse_sample = sample_diffuse_virtual_texture(In, pp_modifiable, virtual_texture_lookup, virtual_tex_cb);
#else
		pp_modifiable.diffuse_sample = sample_diffuse_texture_biased(In, anisotropic_sampler, atlassed_texture_coord);
#endif
		INPUT_TEX_GAMMA(pp_modifiable.diffuse_sample.rgb);
	}
	else
	{
	pp_modifiable.diffuse_sample = float4(0, 0, 0, 1);
	}

	if(bool(USE_SPECULAR_FROM_DIFFUSE))
	{
		const float3 albedo = pp_modifiable.diffuse_sample.rgb;
		const float grayscale = saturate(max((albedo.x + albedo.y + albedo.z) * 0.333, 0.01));
		pp_modifiable.specular_sample = grayscale;
	}
	else if (HAS_MATERIAL_FLAG(g_mf_use_specular) || bool(USE_ANISO_SPECULAR))
	{
#if ENABLE_VIRTUAL_TEXTURING
		pp_modifiable.specular_sample = sample_specular_virtual_texture(In, pp_modifiable, virtual_texture_lookup, virtual_tex_cb).rgb;
#else
		pp_modifiable.specular_sample = sample_specular_texture(atlassed_texture_coord).rgb;
#endif
	}

	if (bool(USE_NORMALMAP))
	{
#if ENABLE_VIRTUAL_TEXTURING
		pp_modifiable.normal_sample = sample_normal_virtual_texture(In, pp_modifiable, virtual_texture_lookup, virtual_tex_cb).xyz;
#else
		pp_modifiable.normal_sample = sample_normal_texture(atlassed_texture_coord).rgb;
#if SYSTEM_DXT5_NORMALMAP
		pp_modifiable.normal_sample.xy = (2.0f * pp_modifiable.normal_sample.ag - 1.0f);
		pp_modifiable.normal_sample.xy *= g_normalmap_power; //TODO_GOKHAN_PERF adjust from texture
		pp_modifiable.normal_sample.z = sqrt(1.0f - saturate(dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy)));
#elif SYSTEM_BC5_NORMALMAP
		pp_modifiable.normal_sample.xy = (2.0f * pp_modifiable.normal_sample.rg - 1.0f);
		pp_modifiable.normal_sample.xy *= g_normalmap_power; //TODO_GOKHAN_PERF adjust from texture
		pp_modifiable.normal_sample.z = sqrt(1.0f - saturate(dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy)));
#else
		pp_modifiable.normal_sample = (2.0f * pp_modifiable.normal_sample.rgb - 1.0f);
		pp_modifiable.normal_sample.xy *= g_normalmap_power;
		pp_modifiable.normal_sample.z = sqrt(1.0f - saturate(dot(pp_modifiable.normal_sample.xy, pp_modifiable.normal_sample.xy)));
#endif
#endif
	}
	else
	{
		pp_modifiable.normal_sample = float3(0, 0, 1);
	}
}

void calculate_alpha_deferred_decal(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	bool on_terrain = bool(RENDER_ON_TERRAIN);
	bool on_objects = bool(RENDER_ON_OBJECTS);
	float2 tc = In.ClipSpacePos.xy;
	tc.x = tc.x * 0.5f + 0.5f; 
	tc.y = tc.y * -0.5f + 0.5f; 
	
	
	uint material_id = get_material_id(tc);	
	bool is_terrain = (material_id == MATERIAL_ID_TERRAIN);
	bool is_face = (material_id == MATERIAL_ID_FACE) || (material_id == MATERIAL_ID_TRANSLUCENT_FACE);
	if (is_face)
	{
		clip(-1);
	}
	
	if(!on_terrain && is_terrain)
	{
		clip(-1);
	}
	
	if(!on_objects && !is_terrain)
	{
		clip(-1);
	}
	
	float pixel_depth = sample_texture_level(depth_texture, linear_sampler, tc.xy, 0).x;
	float3 pos = get_ws_position_at_gbuffer(pixel_depth, tc.xy);
	float3 point_normal = normalize(cross(ddy_fine(pos), ddx_fine(pos)));
	
	float3 frame_normal = pp_aux.pixel_normal_in_ws;
	
	float threshold_angle_cos = cos(radians(g_mesh_vector_argument_2.w));
	if (g_mesh_vector_argument_2.w == 0)
	{
		threshold_angle_cos = 0.5;
	}

	if (dot(point_normal, frame_normal) < threshold_angle_cos)
	{
		clip(-1);
	}
	
	//calculate texture coordinate for decal
	float early_alpha_value = 1.0f;
	if(bool(USE_MASK_TEXTURE))
	{
		early_alpha_value = sample_diffuse2_texture(pp_aux.atlassed_texture_coord).a;
		clip(early_alpha_value - 0.001f);
	}
	

	float4 diffuse_texture_color = float4(0,0,0,1);
	if(bool(USE_ALBEDO))
	{
		diffuse_texture_color = pp_modifiable.diffuse_sample;// sample_diffuse_texture(anisotropic_sampler, pp_modifiable.atlassed_texture_coord.xy).rgba;
	}
	
	early_alpha_value *= g_mesh_factor_color.a;
	if(!HAS_MATERIAL_FLAG(g_mf_do_not_use_alpha))
	{
		early_alpha_value *= diffuse_texture_color.a;
	}
	
	pp_modifiable.early_alpha_value = early_alpha_value;
}
void calculate_normal_deferred_decal(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{	
	float3 normalTS = float3(0,0,1);
	float2 tex_coord = float2(0,0);

	float3 camvec = g_root_camera_position.xyz - pp_aux.pixel_pos_in_ws.xyz;
	bool left_handed = false;
	if(bool(USE_NORMALMAP))
	{
		const float3 world_matrix_s = get_column(g_world, 0).xyz;

		float3x3 TBN;
		TBN[2] = normalTS;
		TBN[0] = normalize(world_matrix_s);
		TBN[1] = safe_normalize(cross(TBN[2], TBN[0]));
		TBN[2] = safe_normalize(cross(TBN[0], TBN[1]));

#if USE_PARALLAXMAPPING
		float depth;
		apply_parallax(In, displacement_texture, tex_coord.xy, pp_static.view_vector_unorm, TBN, pp_modifiable.world_space_normal, depth, pp_modifiable);
#endif
		
		normalTS = compute_tangent_space_normal(In, pp_modifiable, pp_aux.atlassed_texture_coord.xy, pp_aux.pixel_normal_in_ws);
	
		pp_modifiable.world_space_normal = normalize(mul(normalTS, TBN));
	}
	else
	{
		pp_modifiable.world_space_normal = normalTS;
	}
}
void calculate_albedo_deferred_decal(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	bool left_handed = false;

	float2 tex_coord = float2(0,0);
	
	float4 diffuse_texture_color = float4(1,1,1,1);
	if(bool(USE_ALBEDO))
	{
		diffuse_texture_color = pp_modifiable.diffuse_sample;// sample_diffuse_texture(anisotropic_sampler, tex_coord.xy).rgba;
	}
	diffuse_texture_color.rgb = compute_albedo_color(In, pp_modifiable, diffuse_texture_color, tex_coord, pp_static.world_space_position.xyz, float4(1,1,1,1), left_handed, pp_aux, pp_modifiable.world_space_normal);
	//albedo_color.rgb *= g_mesh_factor_color.rgb;
	pp_modifiable.albedo_color.rgb = diffuse_texture_color.rgb;
}

void calculate_albedo_deferred_brush_decal(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coord = float2(0,0);
	
	float3 my_pos = get_column(g_world, 3).xyz;
	const float side_len = length(get_column(g_world, 0));
	const float dist_to_center = length(my_pos.xy - pp_aux.pixel_pos_in_ws.xy);
	const float radius = 1.0 - (dist_to_center / side_len);

	float3 albedo_color = float3(1, 1, 1);
	float alpha = saturate(radius);
	alpha = pow(alpha, saturate(1 - saturate(g_mesh_vector_argument_2.y)));
	alpha *= clamp(saturate(g_mesh_vector_argument_2.x) * 0.9 + 0.1, 0.1, 1.0);// *(sin((g_time_var * 5)) * 0.5 + 0.5);// *(sin((g_time_var * 5) + radius * 2) * 0.5 + 0.5);
	if (g_mesh_vector_argument_2.w > 0.75)
	{
		albedo_color.rgb = sample_diffuse_texture(anisotropic_sampler, pp_aux.pixel_pos_in_ws.xy * (g_mesh_vector_argument_2.z)).rgb;
	}
	else if (g_mesh_vector_argument_2.w > 0.25)
	{
		albedo_color.rgb = sample_diffuse_texture(anisotropic_sampler, pp_aux.pixel_pos_in_ws.xy * (g_mesh_vector_argument_2.z)).rgb;
		alpha *= sample_diffuse2_texture(1 - tex_coord.xy).a;
	}
	else if (g_mesh_vector_argument_2.w > 0.10)
	{
		albedo_color.rgb = 1;
		alpha *= sample_diffuse2_texture(1 - tex_coord.xy).a;
	}

	albedo_color.rgb *= g_mesh_factor_color.rgb;

	float thickness = 0.1;
	if (dist_to_center > (side_len - thickness) && dist_to_center < (side_len))
	{
		albedo_color = float3(0.5, 1.0, 0);
		alpha = 1 ;
	}

	INPUT_TEX_GAMMA(albedo_color.rgb);
	pp_modifiable.early_alpha_value = alpha;
	pp_modifiable.albedo_color.rgb = albedo_color.rgb;
}

void calculate_specularity_deferred_decal(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coord = float2(0,0);
	
	pp_modifiable.specularity = compute_specularity(In, pp_modifiable, tex_coord, pp_static.world_space_position.xyz, 
								pp_modifiable.world_space_normal.xyz, float4(1,1,1,1), pp_aux, pp_modifiable.albedo_color, pp_modifiable.albedo_color);
}

void calculate_diffuse_ao_factor_decal_deferred(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static , inout Per_pixel_modifiable_variables pp_modifiable , inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coord = float2(0,0);
	
	compute_occlusion_factors_deferred_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, In.world_position.xyz, pp_static.screen_space_position,  tex_coord, float4(1,1,1,1) );
}

void calculate_diffuse_ao_factor_decal_forward(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	float2 tex_coord = float2(0, 0);

	compute_occlusion_factors_forward_pass(In, pp_modifiable, pp_modifiable.diffuse_ao_factor, pp_modifiable.ambient_ao_factor,
		pp_modifiable.world_space_normal, In.world_position.xyz, pp_static.screen_space_position, tex_coord, float4(1, 1, 1, 1));
}

#endif

#endif
