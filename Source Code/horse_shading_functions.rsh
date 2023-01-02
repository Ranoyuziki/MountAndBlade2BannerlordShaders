#ifndef HORSE_SHADING_FUNCTIONS_RSH
#define HORSE_SHADING_FUNCTIONS_RSH

#if PIXEL_SHADER
#ifdef STANDART_FOR_HORSE
#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(GBUFFER_PASS) && !defined(CONSTANT_OUTPUT_PASS)
void sample_anisotropic_flowmap(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, out float3 T, out float3 B)
{
	float3 tangent = AnisoFlowmap.Sample(linear_sampler, In.tex_coord).xyz * 2 - 1;
	tangent = normalize(float3(tangent.y, -tangent.x, tangent.z));

	//float3x3 TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord);
#if USE_OBJECT_SPACE_TANGENT
	float3 world_binormal = cross(In.world_normal.xyz, normalize(In.world_tangent.xyz)) * In.world_tangent.w;
	float3x3 TBN = create_float3x3(normalize(In.world_tangent.xyz), world_binormal.xyz, In.world_normal.xyz);
#else
	float3x3 TBN = cotangent_frame_from_derivatives(In.world_normal.xyz, In.world_position.xyz, In.tex_coord.xy);
#endif
	tangent = mul(tangent, TBN);

	tangent = tangent - pp_modifiable.world_space_normal.xyz * dot(tangent, pp_modifiable.world_space_normal.xyz);
	T = normalize(tangent.xyz);
	B = normalize(cross(pp_modifiable.world_space_normal.xyz, T));
}

float D_GGXAnisotropic(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
	float f = TdotH * TdotH / (roughnessT * roughnessT) + BdotH * BdotH / (roughnessB * roughnessB) + NdotH * NdotH;
	return 1.0 / (roughnessT * roughnessB * f * f);
}

float3 compute_anisotropic_specular(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, float3 light_direction)
{
	float gloss = saturate(pp_modifiable.specularity.y * 1.40);
	float3 reflectivity = normalize(pp_modifiable.albedo_color + float3(0.705, 0.705, 0.705)) * 0.04;

	float3 N = pp_modifiable.world_space_normal;
	float3 T, B;
	sample_anisotropic_flowmap(In, pp_static, pp_modifiable, T, B);

	float roughnessX = saturate(1.0f - 0.15);
	roughnessX = max(1e-6, roughnessX);
	float alphaX = roughnessX * roughnessX;

	float roughnessY = saturate(1.0f - gloss);
	roughnessY = max(1e-6, roughnessY);
	float alphaY = roughnessY * roughnessY;

	float3 view_direction = pp_static.view_vector;
	float3 world_space_normal = pp_modifiable.world_space_normal;
	float3 half_vector = normalize(view_direction.xyz + light_direction);
	float NdotH = saturate(dot(world_space_normal, half_vector));
	float VdotH = saturate(dot(view_direction, half_vector));
	float NdotV = saturate(dot(world_space_normal, view_direction));
	float NdotL = saturate(dot(light_direction, world_space_normal.xyz));

	float3 F = reflectivity + (1.0f - reflectivity) * pow((1.0 - VdotH), 5);

	//Hotness remapping for grazing angles Burley 2012
	float roughness = 1.0f - gloss;
	roughness = max(1e-6, roughness);

	float alphag = (0.5 + roughness * 0.5);
	alphag *= alphag;

	float k = alphag * 0.5;
	float G_L = 1.0f / (NdotL * (1.0 - k) + k);
	float G_V = 1.0f / (NdotV * (1.0 - k) + k);
	float G = G_L * G_V;

	float3 D = D_GGXAnisotropic(dot(T, half_vector), dot(B, half_vector), saturate(dot(N, half_vector)), alphaX, alphaY);

	float3 specular_light = D * G * F;
	specular_light = specular_light / (4.0 * RGL_PI);

	return specular_light * NdotL;
}

float3 shift_aniso_tangent(float3 T, float3 N, float shiftAmount)
{
	return normalize(T + shiftAmount * N);
}
float3 compute_secondary_anisotropic_specular(inout Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, float3 light_direction)
{
	float gloss = saturate(g_areamap_amount);
	float3 reflectivity = construct_specular_color(pp_modifiable.specularity, pp_modifiable.albedo_color);

	float tangent_shift = pp_modifiable.diffuse2_sample.r * 2.0 - 1.0;//sample_texture(texture1, linear_sampler, In.tex_coord.xy * 0.2 * 2.0).r * 2.0 - 1.0;
	float second_spec_mask = pp_modifiable.diffuse2_sample.g; // sample_texture(texture1, linear_sampler, In.tex_coord.xy * 7 * 1.0).g;

	float3 N = pp_modifiable.world_space_normal;
	float3 T, B;
	sample_anisotropic_flowmap(In, pp_static, pp_modifiable, T, B);

	B = shift_aniso_tangent(B, N, tangent_shift * 0.08 - 0.005);

	float roughnessX = saturate(1.0f - 0.15);
	roughnessX = max(1e-6, roughnessX);
	float alphaX = roughnessX * roughnessX;

	float roughnessY = saturate(1.0f - gloss);
	roughnessY = max(1e-6, roughnessY);
	float alphaY = roughnessY * roughnessY;

	float3 view_direction = pp_static.view_vector;
	float3 world_space_normal = pp_modifiable.world_space_normal;
	float3 half_vector = normalize(view_direction.xyz + light_direction);
	float NdotH = saturate(dot(world_space_normal, half_vector));
	float VdotH = saturate(dot(view_direction, half_vector));
	float NdotV = saturate(dot(world_space_normal, view_direction));
	float NdotL = saturate(dot(light_direction, world_space_normal.xyz));

	float3 F = reflectivity + (1.0f - reflectivity) * pow((1.0 - VdotH), 5);

	//Hotness remapping for grazing angles Burley 2012
	float roughness = 1.0f - gloss;
	roughness = max(1e-6, roughness);

	float alphag = (0.5 + roughness * 0.5);
	alphag *= alphag;

	float k = alphag * 0.5;
	float G_L = 1.0f / (NdotL * (1.0 - k) + k);
	float G_V = 1.0f / (NdotV * (1.0 - k) + k);
	float G = G_L * G_V;

	float3 D = D_GGXAnisotropic(dot(T, half_vector), dot(B, half_vector), saturate(dot(N, half_vector)), alphaX, alphaY);

	float3 specular_light = D * G * F;
	specular_light = specular_light / (4.0 * RGL_PI);;

	return  second_spec_mask * specular_light * NdotL;
}


float3 compute_horse_lighting(float2 specularity_info, float3 albedo_color,
	float3 light_color, float light_amount, float3 world_space_normal, float3 view_direction, float3 light_direction, float diffuse_ao_factor)
{
	float NdotL = saturate(dot(light_direction, world_space_normal.xyz));

	float3 diffuse_light = albedo_color.rgb;
	float3 result_color = float3(0.0, 0.0, 0.0);

	diffuse_light = diffuse_light * saturate(1.0 - specularity_info.x);
	result_color = (diffuse_light) * light_color.rgb * NdotL * light_amount / RGL_PI;

	return result_color;
}


float3 compute_direct_horse_lighting(direct_lighting_info l_info, float2 specularity_info, float3 albedo_color,
	float3 world_space_normal, float3 view_direction, float3 world_space_position,
	float2 screen_space_position, float diffuse_ao_factor)
{
	return compute_horse_lighting(specularity_info, albedo_color,
		l_info.light_color, l_info.light_amount, world_space_normal, view_direction, l_info.light_direction, diffuse_ao_factor);
}


#endif
#endif
#endif

#endif
