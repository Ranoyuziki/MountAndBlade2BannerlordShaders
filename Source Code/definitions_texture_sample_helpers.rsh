#ifndef DEFINITIONS_TEXTURE_SAMPLE_HELPERS_RSH
#define DEFINITIONS_TEXTURE_SAMPLE_HELPERS_RSH

#include "definitions_helper_macros.rsh"
#include "definitions_shader_resource_views.rsh"

#define diffuse_texture 		texture0			
#define diffuse2_texture 		texture1			
#define normal_texture 			texture2		
#define env_texture 			texture3
#define specular_texture 		texture4
#define displacement_texture 	texture6			
#define cubic_texture 			texture5_cube

float4 sample_texture(Texture2D t, SamplerState s, float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return t.Sample(s, tex_coord);
}

float4 sample_texture_level(Texture2D t, SamplerState s, float2 tex_coord, float level)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return t.SampleLevel(s, tex_coord, level);
}

float4 sample_texture_proj(Texture2D t, SamplerState s, float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	tex_coord.xy = tex_coord.xy / tex_coord.w;
	return t.Sample(s, tex_coord.xy);
}

float4 sample_texture_offseted(Texture2D t, SamplerState s, float2 tex_coord, int2 offset)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return t.SampleLevel(s, tex_coord, 0, offset);
}

float4 sample_blood_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return blood_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_ssao_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return ssao_texture.SampleLevel(linear_sampler, tex_coord, 0);
}

float sample_terrain_height_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return 0;
#endif

	return terrain_height_texture.SampleLevel(linear_mirror_sampler, tex_coord, 0).r;
}

float sample_terrain_shadow_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return 1;
#endif

	return terrain_shadow_texture.SampleLevel(linear_mirror_sampler, tex_coord, 0).r;
}

float4 sample_triplanar(Texture2D t, SamplerState s, float3 normal, float3 uv)
{
	float3 blending = float3(abs(normal.x), abs(normal.y), abs(normal.z));
	blending = normalize(max(blending, 0.00001)); // Force weights to sum to 1.0
	float b = (blending.x + blending.y + blending.z);
	blending /= float3(b, b, b);

	float4 xaxis = t.Sample(s, uv.yz);
	float4 yaxis = t.Sample(s, uv.xz);
	float4 zaxis = t.Sample(s, uv.xy);
	return xaxis * blending.x + yaxis * blending.y + zaxis * blending.z;
}

float4 sample_texture_grad(Texture2D t, SamplerState s, float2 tex_coord, float2 dx, float2 dy)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return t.SampleGrad(s, tex_coord, dx, dy);
}

float4 sample_detail_normal_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return env_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_diffuse_texture(SamplerState s, float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return diffuse_texture.Sample(s, tex_coord);
}

float4 sample_diffuse2_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return diffuse2_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_normal_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return normal_texture.Sample(anisotropic_sampler, tex_coord);
}

float4 sample_specular_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return specular_texture.Sample(anisotropic_sampler, tex_coord);
}

float4 sample_noise_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return diffuse2_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_snow_texture(float2 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return diffuse2_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_diffuse_texture_level(SamplerState s, float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return diffuse_texture.SampleLevel(s, tex_coord.xy, tex_coord.w);
}

float4 sample_diffuse2_texture_level(float4 tex_coord)
{
	return diffuse2_texture.SampleLevel(linear_sampler, tex_coord.xy, tex_coord.w);
}

float4 sample_normal_texture_level(float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return normal_texture.SampleLevel(linear_sampler, tex_coord.xy, tex_coord.w);
}

float4 sample_specular_texture_level(float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return specular_texture.SampleLevel(linear_sampler, tex_coord.xy, tex_coord.w);
}

float4 sample_water_gradient_texture_level(float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	return diffuse2_texture.SampleLevel(linear_clamp_sampler, tex_coord.xy, tex_coord.w);
}

float4 sample_diffuse2_texture_proj(float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	tex_coord.xy = tex_coord.xy / tex_coord.w;
	return diffuse2_texture.Sample(linear_sampler, tex_coord.xy);
}

float4 sample_normal_texture_proj(float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	tex_coord.xy = tex_coord.xy / tex_coord.w;
	return normal_texture.Sample(linear_sampler, tex_coord.xy);
}

float4 sample_specular_texture_proj(float4 tex_coord)
{
#if SYSTEM_DONT_FETCH_TEXTURES && defined(GBUFFER_PASS)
	return float4(1, 0, 1, 1);
#endif

	tex_coord.xy = tex_coord.xy / tex_coord.w;
	return specular_texture.Sample(linear_sampler, tex_coord.xy);
}

float4 sample_postfx_texture(Texture2D tex, SamplerState s, float2 uv, int2 offset = int2(0, 0), bool clamped = true, bool dont_scale = false)
{
	if (dont_scale)
	{
		uv = clamped ? saturate(uv) : uv;
	}
	else
	{
		float2 vTextureDims;
		tex.GetDimensions(vTextureDims.x, vTextureDims.y);
		float2 pixel_size = 1.0f / vTextureDims;

		float2 uv_bounds = trunc(vTextureDims * g_postfx_rc_scale) / vTextureDims;
		uv = clamp(uv * g_postfx_rc_scale + pixel_size * offset, 0, uv_bounds - pixel_size * 0.5f);
	}

	return tex.SampleLevel(s, uv, 0);
}

float4 sample_postfx_texture_prev_frame(Texture2D tex, SamplerState s, float2 uv, int2 offset = int2(0, 0), bool clamped = true, bool dont_scale = false)
{
	if (dont_scale)
	{
		uv = clamped ? saturate(uv) : uv;
	}
	else
	{
		float2 vTextureDims;
		tex.GetDimensions(vTextureDims.x, vTextureDims.y);
		float2 pixel_size = 1.0f / vTextureDims;

		float2 uv_bounds = trunc(vTextureDims * g_postfx_prev_rc_scale) / vTextureDims;
		uv = clamp(uv * g_postfx_prev_rc_scale + pixel_size * offset, 0, uv_bounds - pixel_size * 0.5f);
	}

	return tex.SampleLevel(s, uv, 0);
}

float4 sample_depth_texture(float2 tex_coord)
{
	return depth_texture.Sample(point_sampler, tex_coord);
}

float4 sample_terrain_mesh_blend_diffuse_texture(float2 uv, uint layer_index, float2 dx, float2 dy)
{
	return terrain_diffuse_textures.SampleGrad(anisotropic_sampler, float3(uv, layer_index), dx, dy);
}

float sample_terrain_mesh_blend_displacement_texture(float2 uv, uint layer_index, float2 dx, float2 dy)
{
	return terrain_displacement_textures.SampleGrad(linear_sampler, float3(uv, layer_index), dx, dy).r;
}

float4 sample_terrain_detail_normalmap_texture(float2 uv, uint layer_index, float2 dx, float2 dy)
{
	float4 value = terrain_detail_normalmap_textures.SampleGrad(anisotropic_sampler, float3(uv, layer_index), dx, dy);
	value.xy = 2.0f * value.rg - float2(1.0f, 1.0f);
	value.z = sqrt(saturate(1.0f - dot(value.xy, value.xy)));
	return value;
}

float4 sample_terrain_specular_texture(float2 uv, uint layer_index, float2 dx, float2 dy)
{
	float4 value = terrain_diffuse_textures.SampleGrad(anisotropic_sampler, float3(uv, layer_index), dx, dy);
	return value;
}

void sample_terrain_materialid_texture(float2 uv, inout uint4 layer_id, inout uint4 texture_locations, inout float4 weights)
{
	uint mip_level = 0;
	uint dims = 0;
	terrain_materialmap_textures.GetDimensions(mip_level, dims);
	uint2 width_height = uint2(dims, dims);
	float3 location = float3(width_height * uv, 0);

	uint3 clamp_max = uint3(dims - 1, dims - 1, 0);
	uint3 clamp_min = uint3(0, 0, 0);

	uint4 material_ids;
	material_ids.x = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(-0.5, 0.5), 0), clamp_min, clamp_max));
	material_ids.y = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(0.5, 0.5), 0), clamp_min, clamp_max));
	material_ids.z = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(0.5, -0.5), 0), clamp_min, clamp_max));
	material_ids.w = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(-0.5, -0.5), 0), clamp_min, clamp_max));

	float2 bilinear_weight = frac(location.xy - 0.5f);
	float a = bilinear_weight.x;
	float one_minus_a = 1.0 - a;
	float b = bilinear_weight.y;
	float one_minus_b = 1.0 - b;
	weights = float4(one_minus_a * b, a * b, a * one_minus_b, one_minus_a * one_minus_b);

	layer_id = (material_ids & 0xF);
	texture_locations = (material_ids >> 4) & 0xF;
}


float4 sample_cubic_texture(float3 tex_coord)
{
	//Swizzled dir
	tex_coord = tex_coord.xzy;
	float4 value = cubic_texture.Sample(linear_sampler, tex_coord);
	return value;
}

float sample_cubic_shadow_texture(float3 tex_coord, float compare_val)
{
	return cubic_texture.SampleCmpLevelZero(compare_lequal_bordered_sampler, tex_coord.xyz, compare_val);
}

float4 sample_depth_texture_level(float4 tex_coord)
{
	return depth_texture.SampleLevel(linear_sampler, tex_coord.xy, tex_coord.w);
}

float4 sample_cubic_global_texture_level(float3 tex_coord, float mip)
{
	//Swizzled dir
	tex_coord = tex_coord.xzy;

	float4 value = texture_cube_array.SampleLevel(linear_sampler, float4(tex_coord, 0), mip);

	value.rgb *= g_ambient_multiplier.rgb;
	return value;
}

float4 sample_custom_cubic_texture_level(float4 tex_coord)
{
	//Swizzled dir
	tex_coord = tex_coord.xzyw;
	float4 value = cubic_texture.SampleLevel(linear_sampler, tex_coord.xyz, tex_coord.w);
	value.rgb *= g_ambient_multiplier.rgb;
	return value;
}

float4 sample_cube_texture_array(float3 sample_dir, float mip, uint array_index)
{
	//tex_coord swizzled
	sample_dir = sample_dir.xzy;
	float4 value = texture_cube_array.SampleLevel(linear_sampler, float4(sample_dir, (float)array_index), mip);

	value.rgb *= g_ambient_multiplier.rgb;
	return value;
}

float4 sample_depth_texture_proj(float4 tex_coord)
{
	tex_coord.xy = tex_coord.xy / tex_coord.w;
	return depth_texture.Sample(linear_sampler, tex_coord.xy);
}

float4 sample_cubic_texture_proj(float4 tex_coord)
{
	tex_coord.xy = tex_coord.xy / tex_coord.w;
	return cubic_texture.Sample(linear_sampler, tex_coord.xyz);
}

float4 sample_snow_diffuse_texture(float2 tex_coord)
{
	//return snow_diffuse_texture.SampleLevel(linear_sampler, tex_coord, 0);
	return float4(0.92, 0.92, 0.92, 1.0);
}

float4 sample_snow_normal_texture(float2 tex_coord)
{
	return snow_normal_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_snow_specular_texture(float2 tex_coord)
{
	return snow_specular_texture.Sample(linear_sampler, tex_coord);
}

float4 sample_global_random_texture(float2 tex_coord)
{
	return global_random_texture.SampleLevel(linear_sampler, tex_coord, 3);
}

#endif
