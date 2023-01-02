#ifndef BLOOD_FUNCTIONS_RSH
#define BLOOD_FUNCTIONS_RSH

#if SYSTEM_BLOOD_LAYER && !defined(USE_PROCEDURAL_MULTI_MATERIAL) && !defined(USE_MAIN_MAP_SNOW) && !defined(WORLDMAP_TREE) && !defined(OUTER_MESH_RENDERING)
void compute_blood_amount(inout Pixel_shader_input_type In, out float4 decal_albedo_alpha, out float3 decal_normal, out float2 decal_specularity, float3 local_position, float3 local_normal)
{
	decal_albedo_alpha = 0;
	decal_normal = 0;
	decal_specularity = 0;
	float divider = 0;
	[loop]
	for (int i = 0; i < g_skinned_decal_count; i++)
	{
		int cur_index = g_skinned_decal_index + i;
		float3 sphere_radius = skinned_decals[cur_index].position_and_radius.www;
		float3 sphere_radius_inv = 1.0 / sphere_radius;
		float sphere_radius_sq = sqrt(dot(sphere_radius, sphere_radius));

		float3 sphere_center = skinned_decals[cur_index].position_and_radius.xyz;
		float3 forward = skinned_decals[cur_index].direction_and_atlas_index.xyz;
		forward = normalize(forward);

		const float slope = abs(dot(forward, -local_normal));

		float3 up = float3(0, 0, 1);
		float3 side = normalize(cross(up, forward));
		up = normalize(cross(side, forward));

		float3 vecToPos = local_position - sphere_center;
		float3 new_pos;
		new_pos.x = dot(side * sphere_radius_inv.x, vecToPos);
		new_pos.y = dot(up * sphere_radius_inv.y, vecToPos);
		new_pos.z = dot(forward * sphere_radius_inv.z, vecToPos);

		vecToPos.y = 0;
		float distance_to_center = length(vecToPos);
		[branch]
		if (distance_to_center > sphere_radius.x)
		{
			continue;
		}

		uint index = (uint)skinned_decals[cur_index].direction_and_atlas_index.w;
		uint y = index / 4;
		uint x = index % 4;

		float2 uv;
		float2 test = new_pos.xy * 0.5 + 0.5;
		uv = saturate(new_pos.xy * 0.5 + 0.5);

		uv.x = 1.0f - uv.x;
		float2 real_uv = float2(x * 0.25 + uv.x * 0.25, y * 0.25 + uv.y * 0.25);

		float ndotl = dot(forward, normalize(-local_normal));

		{
			float4 diffuse_val = sample_texture_level(DecalDiffuseMap, linear_sampler, real_uv, 1);
			INPUT_TEX_GAMMA(diffuse_val.rgb);
			float3 normal = sample_texture_level(DecalNormalMap, linear_sampler, real_uv, 1).xyz * 2.0 - 1.0;
			normal.z = sqrt(1.0f - dot(normal.xy, normal.xy));

			float smoothness = 1.0 - smoothstep(sphere_radius.x - 0.025, sphere_radius.x, distance_to_center);// *smoothstep(0.0, 0.2, slope);

			decal_albedo_alpha.a += diffuse_val.a * smoothness;

			float4 spec_tex = sample_texture_level(DecalSpecularMap, linear_sampler, real_uv, 1);

			decal_albedo_alpha.rgb += diffuse_val.rgb;
			decal_normal.rgb += normal.rgb * diffuse_val.a * smoothness;
			decal_specularity.xy += spec_tex.xy * diffuse_val.a;
			divider += diffuse_val.a;
		}
	}

	decal_albedo_alpha.xyz = saturate(decal_albedo_alpha.xyz / divider);
	decal_specularity.xy = saturate(decal_specularity.xy / divider);
	decal_normal.rgb = normalize(decal_normal.rgb);
   	decal_albedo_alpha.a = saturate(decal_albedo_alpha.a);
}
#endif

#endif
