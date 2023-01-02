#ifndef METAL_ROUGHNESS_RSH
#define METAL_ROUGHNESS_RSH

#if DOMAIN_SHADER
VS_OUTPUT_STANDART standart_metal_rough_ds(HS_CONSTANT_DATA_OUTPUT_STANDART In, float3 barycentric_coords, const OutputPatch<VS_OUTPUT_STANDART, 3> triangle_patch)
{
	return standart_ds_helper(In, barycentric_coords, triangle_patch, texture3);
}
#endif

#if PIXEL_SHADER
void sample_metal_roughness_textures(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout Per_pixel_auxiliary_variables pp_aux)
{
	pp_modifiable.shadow = 1;
#if VDECL_HAS_TANGENT_DATA
#if USE_PARALLAXMAPPING
	float depth;

#if USE_OBJECT_SPACE_TANGENT
	float3 world_binormal = cross(In.world_normal.xyz, normalize(In.world_tangent.xyz)) * In.world_tangent.w;
	float3x3 _TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
#else
	float3x3 _TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord.xy);
#endif
	pp_modifiable.shadow = apply_parallax(In, texture3, In.tex_coord.xy, pp_static.view_vector_unorm, _TBN, In.world_normal.xyz, depth, pp_modifiable);
#endif
#endif

	{
		pp_modifiable.diffuse_sample = DiffuseMap.Sample(anisotropic_sampler, In.tex_coord.xy);
		INPUT_TEX_GAMMA(pp_modifiable.diffuse_sample.rgb);

		//pp_modifiable.diffuse_sample.rgb = texture3.SampleLevel(linear_sampler, In.tex_coord.xy, 0).rrr;
	}

	{
		pp_modifiable.specular_sample.x = Metallic.Sample(linear_sampler, In.tex_coord.xy).r;
		pp_modifiable.specular_sample.y = 1.0 - Roughness.Sample(linear_sampler, In.tex_coord.xy).r;
		pp_modifiable.specular_sample.z = Occlusion.Sample(linear_sampler, In.tex_coord.xy).r;
	}

#if VDECL_HAS_TANGENT_DATA
	pp_modifiable.normal_sample = NormalMap.Sample(anisotropic_sampler, In.tex_coord.xy).rgb;
	pp_modifiable.normal_sample.y = 1.0 - pp_modifiable.normal_sample.y;
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
#else
pp_modifiable.normal_sample = float3(0, 0, 1);
#endif
}
#endif

#endif
