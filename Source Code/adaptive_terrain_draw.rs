#include "definitions.rsh"
#define ADAPTIVE_TERRAIN_DRAW_PASS

struct VS_OUTPUT_TEST
{
	float4 position : RGL_POSITION;
	float3 color : COLOR0;
	float2 texcoord : TEXCOORD0;
	float3 world_pos : TEXCOORD1;
};

#include "modular_struct_definitions.rsh"

float3 heatmap(float v)
{
	float3 r = saturate(v) * 2.1 - float3(1.8, 1.14, 0.3);
	return 1.0 - r * r;
}

#if VERTEX_SHADER

#ifdef USE_DIRECTX12
#define culled_subd_buffer (Buffer_uint_table[indices.t_custom_7])
#else
Buffer<uint> culled_subd_buffer : register(t_custom_7);
#endif

#include "adaptive_terrain_common.rsh"

VS_OUTPUT_TEST main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_TEST Out;
	uint threadID = In.instanceID * 2;
	float4 final_vertex = calculate_vertex_position(threadID + adaptive_terrain.index_offset, In.position.xy);
	Out.texcoord = final_vertex.xy;

	final_vertex = mul(adaptive_terrain.model, float4(final_vertex.xyz, 1));
	Out.world_pos = final_vertex.xyz;

	float2 height_uv = Out.texcoord;
	height_uv.y = 1 - height_uv.y;
	Out.world_pos.z += sector_height_texture.SampleLevel(linear_clamp_sampler, height_uv, 0).r * adaptive_terrain.heightmap_scale;

	Out.color = 1;// heatmap(sector_data.x / 64.0f);
	Out.position = mul(g_view_proj, float4(Out.world_pos.xyz, 1));
	return Out;
}
#endif

#if PIXEL_SHADER
#include "gbuffer_functions.rsh"
#include "adaptive_terrain_common.rsh"

#ifdef USE_DIRECTX12
#define albedo_array (Texture2DArray_table[indices.t_terrain_3])
#define normal_array (Texture2DArray_table[indices.t_terrain_4])
#define river_texture (Texture2D_float_table[indices.t_custom_5])
#else
Texture2DArray albedo_array : register(t96);
Texture2DArray normal_array : register(t97);
Texture2D<float> river_texture : register(t_custom_5);
#endif

float4 landscape_sample_albedo_texture(uint index, float2 uv)
{
	index = clamp(index, 0, 6);
	return albedo_array.Sample(anisotropic_sampler, float3(uv, index));
}

float4 landscape_sample_normal_texture(uint index, float2 uv)
{
	index = clamp(index, 0, 6);
	return normal_array.Sample(anisotropic_sampler, float3(uv, index)) * 2 - 1;
}

PS_OUTPUT_GBUFFER main_ps(VS_OUTPUT_TEST In)
{
	PS_OUTPUT_GBUFFER Output = (PS_OUTPUT_GBUFFER)0.0;

	float3 world_position = In.world_pos;
	float2 normalized_uv = In.texcoord;

	float4 final_albedo = float4(1, 0, 1, 1);
	float3 final_normal = float3(0, 0, 1);
	float3 vertex_normal = final_normal;

	float3 detail_albedo = float3(1, 1, 1);
	float3 detail_normal = float3(0, 0, 1);

	float4 specular = float4(0, 0, 1, 0);

	float4 resolve_output = float4(0, 0, 0, 0);

	// Vista
	{
		GraniteLookupData virtual_texture_lookup;
		float2 vista_texcoord = normalized_uv;
		GraniteConstantBuffers virtual_tex_cb;
		virtual_tex_cb.tilesetBuffer = adaptive_terrain.tileset_data;
		virtual_tex_cb.streamingTextureBuffer = adaptive_terrain.tileset_texture_data;
		GraniteTranslationTexture translationTable = { point_sampler, vt_translation_texture };
		Granite_Lookup_Anisotropic(virtual_tex_cb, translationTable, vista_texcoord, virtual_texture_lookup, resolve_output);

		GraniteCacheTexture cache;
		cache.TextureArray = vt_cache_texture_diffuse;
		cache.Sampler = anisotropic_sampler;
		Granite_Sample_HQ(virtual_tex_cb, virtual_texture_lookup, cache, 0, final_albedo);
		INPUT_TEX_GAMMA(final_albedo);

		float4 packed_normal = float4(0, 0, 1, 1);
		cache.TextureArray = vt_cache_texture_normal;
		cache.Sampler = anisotropic_sampler;
		Granite_Sample_HQ(virtual_tex_cb, virtual_texture_lookup, cache, 1, packed_normal);
		final_normal = Granite_UnpackNormal(packed_normal);
		specular.z = final_normal.z;
		final_normal.z = sqrt(1.0 - saturate(dot(final_normal.xy, final_normal.xy)));

#if (GRA_PACK_RESOLVE_OUTPUT==0)
		resolve_output = Granite_PackTileId(resolve_output);
#endif
	}

	float2 detail_uv = normalized_uv * 128;

	// Dynamic effects
	{
		const float2 dynamic_terrain_params = float2(g_dynamic_terrain_params.x, g_dynamic_terrain_params.y);

		float noise = smoothstep(0.4, 0.55, global_random_texture.SampleLevel(linear_sampler, normalized_uv * 20.0f, 0).x) * 0.5 + 0.5;
		float mask = lerp(0.135, 1.0, final_normal.y) * noise;

		float3 grad_value = texture15.SampleLevel(linear_sampler, float2(normalized_uv.x, 1 - normalized_uv.y), 0).rgb;
		float grad = smoothstep((dynamic_terrain_params.x) - dynamic_terrain_params.y, (dynamic_terrain_params.x) + dynamic_terrain_params.y, grad_value.r);

		grad = lerp(0, lerp(mask, 1, grad) * grad, grad);
		grad = saturate(smoothstep(0.45, 0.5, grad) * (smoothstep(0.7, 1.0, final_normal.z)));

		float water_mask = 1 - grad_value.b;
		water_mask = smoothstep(min(final_normal.x, max(final_normal.x, water_mask)), 1, water_mask);
		grad = grad * water_mask;

		float3 detail_albedo = sample_texture(colormap_diffuse_texture, linear_sampler, detail_uv).rgb;

		float3 snow_color = sample_snow_diffuse_texture(detail_uv.xy * 10).xyz;
		INPUT_TEX_GAMMA(snow_color);
		final_albedo.rgb = lerp(final_albedo.rgb, snow_color, grad);

		specular.z = lerp(specular.z, 1, grad);
		float2 snow_normal = sample_snow_normal_texture(detail_uv.xy * 10).xy * 2 - 1;
		specular.y = lerp(specular.y, 0.4, grad);
	}

	detail_uv *= adaptive_terrain.detail_uv_scale;
	[branch]
	if (adaptive_terrain.high_quality > 0.5)
	{
		float2 location = normalized_uv * 4096;

		uint3 clamp_max = uint3(4096, 4096, 0);
		uint3 clamp_min = uint3(0, 0, 0);
	
		uint4 material_ids;
		material_ids.x = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(-0.5, 0.5), 0), clamp_min, clamp_max)).r;
		material_ids.y = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(0.5, 0.5), 0), clamp_min, clamp_max)).r;
		material_ids.z = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(0.5, -0.5), 0), clamp_min, clamp_max)).r;
		material_ids.w = terrain_materialmap_textures.Load(clamp(uint3(location.xy + float2(-0.5, -0.5), 0), clamp_min, clamp_max)).r;
	
		float2 bilinear_weight = frac(location.xy - 0.5f);
		float a = bilinear_weight.x;
		float one_minus_a = 1.0 - a;
		float b = bilinear_weight.y;
		float one_minus_b = 1.0 - b;
		float4 weights = float4(one_minus_a * b, a * b, a * one_minus_b, one_minus_a * one_minus_b);
	
		detail_albedo = float3(0, 0, 0);
		[unroll]
		for (uint i = 0; i < 4; ++i)
		{
			uint texture_index = (material_ids[i]) & 0xF;
			detail_albedo += landscape_sample_albedo_texture(texture_index, detail_uv).rgb * weights[i];
			//detail_albedo += heatmap(texture_index / 6.0f) * weights[i]; // DEBUG
			float3 normal = landscape_sample_normal_texture(texture_index, detail_uv).rgb.xyz;
			detail_normal = float3(detail_normal.xy + normal.xy * weights[i], detail_normal.z);
		}
		detail_normal = normalize(detail_normal);
	}
	final_albedo.rgb *= detail_albedo;

	float3x3 normal_frame;
	normal_frame[2] = final_normal;
	normal_frame[1] = float3(0, -1, 0);
	normal_frame[0] = normalize(cross(normal_frame[2], normal_frame[1]));
	normal_frame[1] = -normalize(cross(normal_frame[0], normal_frame[2]));
	vertex_normal = final_normal;
	vertex_normal.x = -vertex_normal.x;
	vertex_normal.y = -vertex_normal.y;
	final_normal = mul(normal_frame, detail_normal);
	final_normal = normalize(final_normal);

	float river_mask = river_texture.SampleLevel(linear_sampler, normalized_uv, 0).r;
	final_albedo.rgb = lerp(final_albedo.rgb, final_albedo.rgb * float3(0.05f, 0.13f, 0.1f), river_mask);
	specular.y = lerp(specular.y, 0.92f, river_mask);

	set_gbuffer_values(Output, final_normal, 1, final_albedo.xyz, specular.xy, specular.z, vertex_normal, 0, 1, resolve_output);

	return Output;
}

#endif