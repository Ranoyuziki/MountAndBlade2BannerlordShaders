
#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"
#include "standart.rsh"

struct VS_OUTPUT_FLORA_GPU_BILLBOARD
{
	float4 position					: RGL_POSITION;	
	float4 world_position			: TEXCOORD0;
	float4 world_normal				: TEXCOORD1;
	TEXCOORD_FORMAT tex_coord		: TEXCOORD2;
	float4 shadow_world_position	: TEXCOORD3;
#ifdef SYSTEM_SHOW_VERTEX_COLORS
	float4 vertex_color				: TEXCOORD5;
#endif
};



static const int billboard_count = 8;

VS_OUTPUT_FLORA_GPU_BILLBOARD main_vs(RGL_VS_INPUT In)
{
	VS_OUTPUT_FLORA_GPU_BILLBOARD Out;

	float4 object_position, object_tangent;
	float3 object_normal, object_color;
	float4 world_position;
	float3 world_normal;
	float3 prev_object_position;
	float4 temp_vert_color = get_vertex_color(In.color);	

	rgl_vertex_transform(In, object_position, object_normal, object_tangent, prev_object_position, object_color);

	world_position = mul(g_world, object_position);
	world_normal = normalize(mul(to_float3x3(g_world),object_normal));

	float2 view_vec = g_camera_position.xy - world_position.xy;

#if USE_GPU_BILLBOARDS
	enlarge_gpu_billboards_with_z(world_position, object_normal);
#endif

#ifdef SYSTEM_SHOW_VERTEX_COLORS
	Out.vertex_color = get_masked_vertex_color(get_vertex_color(In.color));
#endif
	float instance_angle = temp_vert_color.r * 2.0 - 1.0;

	Out.position = mul(g_view_proj, world_position);
	Out.world_position = world_position;
	Out.tex_coord.xy = In.tex_coord.xy;
	Out.world_normal = float4(world_normal, instance_angle);

	float view_angle = atan2(view_vec.y, view_vec.x) * (1.0 / RGL_PI);

	float view_index			= int(floor(view_angle		* (billboard_count / 2)) + billboard_count) % billboard_count;
	int view_index_int			= (int(view_index) + billboard_count) % billboard_count;
	int instance_view_offset	= int(floor(instance_angle	* (billboard_count / 2)) + billboard_count) % billboard_count;

	int main_billboard_index = (view_index_int - instance_view_offset + billboard_count + billboard_count) % billboard_count;
	int secondary_billboard_index = (main_billboard_index + 1) % billboard_count;

	Out.sample_data = float3(main_billboard_index, secondary_billboard_index, 0);

	return Out;
}


PS_OUTPUT main_ps(VS_OUTPUT_FLORA_GPU_BILLBOARD input)
{
	PS_OUTPUT Output;

#ifdef SYSTEM_SHOW_VERTEX_COLORS
	{
		Output.RGBColor.rgba = input.vertex_color.rgba;
		return Output;
	}
#endif
	float2 tex_coords = input.tex_coord;
	tex_coords.x *= (1.0 / billboard_count);

	float4 tex_coord_1 = float4(tex_coords + float2(input.sample_data.x * (1.0 / billboard_count), 0), 0, 0);
	float4 albed_tex = sample_diffuse_texture(point_sampler, tex_coord_1.xy);
	
	clip(albed_tex.a - 0.1);


	

#ifdef USE_SMOOTH_FLORA_LOD_TRANSITION
	float2 xy = input.position.xy;

	int x = fmod(xy.x, 8);
	int y = fmod(xy.y, 8);

	float c0 = g_mesh_vector_argument.a;
	float early_alpha;
	if(c0 >= 0.0f)
	{
		float final_alpha = find_closest(x, y, c0);
		early_alpha = final_alpha;
	}
	else
	{
		float final_alpha = find_closest(x, y, -1.0 * c0);
		early_alpha = 1.0 - final_alpha;
	}

	clip(early_alpha - 0.999f);
#endif

	float instance_cos, instance_sin;
	sincos(input.world_normal.w * RGL_PI, instance_sin, instance_cos);

	float2x2 rotation_matrix;

	rotation_matrix[0][0] = instance_cos;	rotation_matrix[0][1] = -instance_sin;
	rotation_matrix[1][0] = instance_sin;	rotation_matrix[1][1] = instance_cos;

	float4 normal_tex = sample_normal_texture(tex_coord_1.xy);
	float ambient_ao_factor = normal_tex.w;

	float3 world_normal = normal_tex.xyz;
	float3 standard_world_normal = world_normal = normalize(world_normal * 2.0 - 1.0);

	standard_world_normal.z = 1.5f;
	standard_world_normal = normalize(standard_world_normal);

	world_normal.z = 2.0f;
	world_normal = normalize(world_normal);

	world_normal.xy = mul(rotation_matrix, world_normal.xy);
	standard_world_normal.xy = mul(rotation_matrix, standard_world_normal.xy);
		
	float sun_amount = compute_sun_amount_from_cascades(input.world_position, input.position);

	world_normal = normalize(world_normal);
	float NdotL = saturate(dot(g_sun_direction_inv, world_normal));

	sun_amount *= saturate(dot(g_sun_direction_inv, standard_world_normal));

	float3 view_dir = normalize(input.world_position - g_camera_position.xyz);
	float SdotV = -dot(g_sun_direction_inv, view_dir);

	float3 ambient_light = get_ambient_term_with_skyaccess(input.world_position, world_normal);

	float scatter_strength = saturate(-SdotV);
	scatter_strength *= scatter_strength;
	float3 transluceny_term = 3.0f * scatter_strength; //We multiply with diffuse color to give the effect oplight passing through and taking the color of the material 

	float3 sun_light = sun_amount * g_sun_color.rgb;

	float translucency = 0.08;
	float3 translucency_light = translucency * transluceny_term;
	float3 diffuse_light = NdotL * ambient_ao_factor;

	float3 final_color = albed_tex.rgb  * (ambient_light * ambient_ao_factor +  sun_light * (diffuse_light + translucency));


	float3 view_direction_unorm = g_camera_position.xyz - input.world_position.xyz;
	float3 view_direction = normalize(view_direction_unorm);
	//apply_advanced_fog(final_color, view_direction, view_direction_unorm.z, input.shadow_tex_coord.w);


	if(bool(USE_SHADOW_DEBUGGING))
	{
		int index = compute_shadow_index(pp_static.world_space_position);

		if(index == 4)
		{
			final_color.rgb = float3(1,1,1);
		}
		else if(index == 3)
		{
			final_color.rgb = float3(1,0,1);
		}
		else if(index == 2)
		{
			final_color.rgb = float3(0,0,1);
		}
		else if(index == 1)
		{
			final_color.rgb = float3(0,1,0);
		}
		else
		{
			final_color.rgb = float3(1,0,0);
		}
	}

	Output.RGBColor.rgb = output_color(final_color);
	Output.RGBColor.a = albed_tex.a;


	return Output;
}
