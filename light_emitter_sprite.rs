
#undef Vertex_shader_output_type
#define Vertex_shader_output_type VS_OUTPUT_STANDART_LIGHT_EMITTER

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"
#include "shared_vertex_functions.rsh"

struct VS_OUTPUT_STANDART_LIGHT_EMITTER
{
	float4 position : RGL_POSITION;
	float4 vertex_color : COLOR0;
	float4 world_position : TEXCOORD0;
	float4 world_normal : TEXCOORD1;
	float2 tex_coord : TEXCOORD2;
};

#if VERTEX_SHADER
VS_OUTPUT_STANDART_LIGHT_EMITTER main_vs(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_STANDART_LIGHT_EMITTER, Out);

	float4 object_position, object_tangent;
	float3 object_normal, object_binormal;
	float3 prev_object_position, object_color;

	rgl_vertex_transform(In, object_position, object_normal, object_tangent, prev_object_position, object_color);

	float4 world_position;
	float3 world_normal;

	float4 temp_vert_color = get_vertex_color(In.color);	
	
	{
		world_position = mul(g_world, object_position);
		world_normal = normalize(mul(to_float3x3(g_world),object_normal));
		
		#if USE_GPU_BILLBOARDS
			enlarge_gpu_billboards(In, world_position, object_normal);
		#endif
		
		#if USE_TESSELATION
			Out.position = mul(g_world, object_position);
		#else
			Out.position = mul(g_view_proj, world_position);
		#endif
	}

	//Out.screen_space_pos = Out.position;
	Out.world_position = world_position;

	if(bool(USE_ANIMATED_TEXTURE_COORDS))	
	{
		uint num_frames_x = g_mesh_vector_argument.x;
		uint num_frames_y = g_mesh_vector_argument.y;
		float animation_speed = g_mesh_vector_argument.z;
		uint num_frames = g_mesh_vector_argument.w;
		
		float phase_difference = (g_world._m03 + g_world._m13 + g_world._m23) * 2.4;
		
		uint cur_frame = (g_time_var * animation_speed + (int)phase_difference) % num_frames;
		uint cur_frame_x = floor(cur_frame % num_frames_x);
		uint cur_frame_y = floor(cur_frame / num_frames_x);
		
		In.tex_coord.x *= 1.0f / (float)num_frames_x;
		In.tex_coord.y *= 1.0f / (float)num_frames_y;
		
		In.tex_coord.x += ((float)cur_frame_x / (float)num_frames_x);
		In.tex_coord.y += ((float)cur_frame_y / (float)num_frames_y);
	}

	if(bool(USE_CUSTOM_TEXTURE_COORDS))
	{
		int num_frames_x = g_mesh_vector_argument.x;
		int num_frames_y = g_mesh_vector_argument.y;
		int cur_frame_x = g_mesh_vector_argument.z;
		int cur_frame_y = g_mesh_vector_argument.w;

		In.tex_coord.x *= 1.0f / (float)num_frames_x;
		In.tex_coord.y *= 1.0f / (float)num_frames_y;

		In.tex_coord.x += ((float)cur_frame_x / (float)num_frames_x);
		In.tex_coord.y += ((float)cur_frame_y / (float)num_frames_y);
	}
		
	Out.tex_coord.xy = In.tex_coord.xy;
	
	Out.vertex_color = temp_vert_color;

	Out.world_normal.xyz = world_normal;

	Out.position.z = min(Out.position.z, Out.position.w-0.001f);
	
	return Out;
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps ( VS_OUTPUT_STANDART_LIGHT_EMITTER In)
{ 
	PS_OUTPUT Output;
	
	//Output.RGBColor.rgba  = float4(In.tex_coord.x*100,In.tex_coord.y*100,1,1);
	//return Output;
	float4 tex_col = float4(0,0,0,1);

	tex_col = sample_diffuse_texture(linear_sampler, In.tex_coord.xy).rgba;


	Output.RGBColor.rgba = In.vertex_color.rgba;

	if(!HAS_MATERIAL_FLAG(g_mf_do_not_use_alpha))
	{
		Output.RGBColor.a *= tex_col.a;
	}

	apply_alpha_test_simple(Output.RGBColor.a);

	float3 view_direction_unorm = (g_camera_position.xyz - In.world_position.xyz);
	float view_len = length(view_direction_unorm);
	float3 view_direction = view_direction_unorm / view_len;

	In.world_normal.xyz = normalize(In.world_normal.xyz);
	
	INPUT_TEX_GAMMA(tex_col.rgb);

	float4 illumination_color = tex_col;	

	#if USE_ANIMATED_TEXTURE_COORDS
		illumination_color.xyz *= g_mesh_vector_argument_2.xyz;
		float randomness_value = 0;
		float flicker_frequency = 0;
		float flicker_power = 0;
		float base_illumination = g_mesh_vector_argument_2.w;
	#elif USE_CUSTOM_TEXTURE_COORDS
		float base_illumination = 500;
		float randomness_value = 0;
		float flicker_frequency = 0;
		float flicker_power = 0;
	#else
		float randomness_value = g_mesh_vector_argument.x;
		float flicker_frequency = g_mesh_vector_argument.y;
		float flicker_power = g_mesh_vector_argument.z;
		float base_illumination = g_mesh_vector_argument.w;	
	#endif
	
	
	float illum_amount = base_illumination;
	
	if(flicker_power > 0)
	{
		float tc_eff = (In.tex_coord.x + In.world_normal.y + In.world_normal.z * 6.1 + (In.world_position.x + In.world_position.y) * 2.8);
		float flicker_light = clamp(sin( tc_eff * randomness_value + g_time_var * 4.8f * flicker_frequency) * 0.6 * flicker_power, 0 ,  10);
		illum_amount += flicker_light;
	}
	Output.RGBColor.xyz = illumination_color.rgb * illum_amount;


	apply_advanced_fog(Output.RGBColor.rgb, view_direction, view_direction_unorm.z, view_len, 1.0f);	
	
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	return Output;
}

#endif
