#ifndef ATMOSPHERE_FUNCTIONS_RSH
#define ATMOSPHERE_FUNCTIONS_RSH

#include "system_postfx.rsh"

float compute_volumetric_fog_amount(in float height, in float distance)	//TODO_GOKHAN_PERF: move to vertex shader for forward rendering..
{
	float cHeightFalloff = (g_fog_falloff * 0.01) + 0.0001;
	float cVolFogHeightDensityAtViewer = exp( -cHeightFalloff * (g_root_camera_position.z - g_fog_falloff_offset));
	float fogInt = max(0.0, distance) * cVolFogHeightDensityAtViewer;
	const float cSlopeThreshold = 0.01;
	if(abs(height) > cSlopeThreshold)
	{
		float t = cHeightFalloff * height;
		fogInt *= (( 1.0 - exp( -t ) ) / t);
	}

	float fog_amount = exp( -g_fog_density * 0.0005 * fogInt );
	return saturate(min(fog_amount, 1.0f - g_fog_falloff_min));
}


float compute_volumetric_fog_simple(in float height)
{
	float ray_begin_height = min(g_camera_position.z, height);
	float ray_end_height = max(g_camera_position.z, height);
	float ray_len = ray_end_height - ray_begin_height;
	float ray_len_in_fog = saturate((g_fog_falloff_offset - ray_begin_height) / ray_len);
	return ray_len_in_fog;
}

float3 apply_atmospheric_scatter_sky(float3 viewdir, float height, float depth, float3 color, bool apply_rayleigh, bool apply_falloff,
	bool use_scatter = true)
{
	depth = max(0.0, depth - g_fog_start_distance);
	depth *= g_scene_scale;
	float fogInt = compute_volumetric_fog_amount(height, depth);

	const float MieConstCoefficient = 0.05;

	const float3 bm = (210.0e-5)  * MieConstCoefficient;
	const float3 bm_func_factor = (4 * RGL_PI);
	const float3 OneOverRayMConst = float3(1.0f, 1.0f, 1.0f) / bm.xyz;

	//Hoffman Equation for Mie Scattering
	const float g = min(0.9999f, g_mie_scatter_particle_size / 10);

	float cosTheta = dot(g_sun_direction.xyz, normalize(viewdir));
	float mie = (1.0f - g * g) / ((4 * RGL_PI) * pow(abs(1.0f + g * g - 2 * g * cosTheta), 1.5f));
	mie = clamp(mie, 0 , 100);

	float3 MieTotal =  g_rayleigh_constant * mie * g_fog_ambient_color.rgb * (g_sky_brightness + length(g_sun_color));
	
	color += MieTotal;// lerp(MieTotal, color, g_debug_vector.y);
	float3 rotated_dir = -1 * viewdir.xyz;
	float scatter_coef = exp(-max(0.0, depth) * 0.00001 * g_scatter_strength);
	//return scatter_coef;
	float lod = max(0, saturate(scatter_coef) * (ENVMAP_LEVEL - 1));

	float4 tex_coord_to_sample = float4(rotated_dir.xzy, lod);

	float3 fog_color = color;
	if (use_scatter)
	{
		float3 fog_color_from_sky = scatter_cubemap.SampleLevel(linear_sampler, tex_coord_to_sample.xyz, 2.0).xyz / g_target_exposure;
		float3 xyY = RGBtoxyY(fog_color_from_sky.xyz);
		fog_color_from_sky.b = g_sky_brightness;
		fog_color_from_sky.xyz = xyYtoRGB(xyY);
		fog_color = lerp(g_fog_color, fog_color_from_sky, g_fog_scatter * (1.0 - exp(-max(0.0, depth) * 0.0001 * 41.3f)));
	}

	return lerp(fog_color, color, saturate(fogInt));
}

void apply_advanced_fog_sky(inout float3 color, const float3 view_dir, const float height, float depth, bool use_scatter = true)
{
	color = apply_atmospheric_scatter_sky(view_dir, -height, depth, color, true, true, use_scatter);
}

void compute_fog_iterative(float3 cam_pos, float3 pixel_pos)
{
	float3 diff = pixel_pos - cam_pos;
	float itt_count = 40;
	float3 dv = diff / itt_count;

	[loop]
	for (int i = 0; i < itt_count; i++)
	{
		

	}
}

float3 apply_atmospheric_scatter(float3 viewdir, float height, float depth, float3 color,
	bool apply_rayleigh, bool apply_falloff, float sky_visibility, bool use_scatter)
{
	float sky_visibility_factor = 1.0f;//1.0f - saturate(sky_visibility * 4.0f);
	float fog_start_distance_to_use =  g_fog_start_distance * (sky_visibility_factor);

	depth = max(0.0, depth - fog_start_distance_to_use);
	depth *= g_scene_scale;
	float fogInt = compute_volumetric_fog_amount(height, depth);

	float3 rotated_dir = -1 * viewdir.xyz;

	//float coef = exp(-max(0.0, depth - 300 * g_scene_scale) * 0.00001 * g_scatter_strength / g_scene_scale);
	float coef = exp(-max(0.0, depth) * 0.00001 * g_scatter_strength);
	float lod = max(0, saturate(coef) * (ENVMAP_LEVEL - 1));

	float4 tex_coord_to_sample = float4(rotated_dir.xzy, lod);
	float3 scatter_color = scatter_cubemap.SampleLevel(linear_sampler, tex_coord_to_sample.xyz, lod).xyz / g_target_exposure;

	if (use_scatter)
		color = lerp(scatter_color, color, saturate(coef));
	fogInt = saturate(fogInt);

	float4 fog_color_from_sky = scatter_cubemap.SampleLevel(linear_sampler, tex_coord_to_sample.xyz, 2.0) / g_target_exposure;

	float3 xyY = RGBtoxyY(fog_color_from_sky.xyz);
	fog_color_from_sky.b = g_sky_brightness;
	fog_color_from_sky.xyz = xyYtoRGB(xyY);

	float3 fog_color_to_use = g_fog_color;

	return lerp(lerp(fog_color_to_use, fog_color_from_sky.xyz, g_fog_scatter * (1.0 - exp(-max(0.0, depth) * 0.0001 * 41.3f))), color, fogInt);
}

float ComputeHalfSpace(float3 world_position, float3 camera_position)
{
	float4 P = float4(world_position, 1.0);
	float4 C = float4(camera_position, 1.0);
	float4 F = float4(0, 0, 1, g_fog_falloff_offset);
	float4 V = C - P;
	float FdotP = dot(F, P);
	float FdotV = dot(F, V);
	float FdotC = dot(F, C);

	float k = FdotC <= 0 ? 1 : 0;
	float a = g_fog_falloff * 0.001;
	float nominator = min((1 - 2 * k) * FdotP, 0);
	float gP = -a * 0.5 * length(V) * (k * (FdotP + FdotC) - (nominator * nominator / abs(FdotV)));

	return gP;
}


// 
// void apply_new_fog(inout float3 color, float3 world_position)
// {
// 	float gHeight = ComputeHalfSpace(world_position, g_camera_position);
// 	float gDistance = g_fog_density * 0.001 * length(world_position - g_camera_position);
// 
// 	float total_fog_factor = max(0.0, (gHeight + gDistance));
// 	float f0 = saturate(exp2(-gHeight));
// 	float f1 = saturate(exp2(-gDistance));
// 	color = lerp(g_fog_ambient_color, color, f0);
// 	color = lerp(g_fog_color * g_sky_brightness, color, f1);
// }

void apply_advanced_fog(inout float3 color, const float3 view_dir, const float height, float depth, float sky_visibility, bool use_scatter = true)
{
	color = apply_atmospheric_scatter(view_dir, -height, depth, color, true, true, sky_visibility, use_scatter);
}

void apply_advanced_fog(inout float3 color, const float3 world_position, float sky_visibility)
{
	float3 view_direction_unorm = g_camera_position.xyz - world_position.xyz;
	float3 view_direction = normalize(view_direction_unorm);

	float3 view_dir = world_position;
	float depth = length(view_dir);
	view_dir /= depth;

	apply_advanced_fog(color, view_dir, view_direction_unorm.z, depth, sky_visibility);
}

#endif // ATMOSPHERE_FUNCTIONS_RSH
