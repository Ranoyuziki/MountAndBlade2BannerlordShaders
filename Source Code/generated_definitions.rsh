#ifndef GENERATED_DEFINITIONS_RSH
#define GENERATED_DEFINITIONS_RSH

#include "modular_struct_definitions.rsh"

#if my_material_id == MATERIAL_ID_DEFERRED
	#include "gbuffer_functions.rsh"
#endif

#if PIXEL_SHADER
void calculate_per_pixel_static_variables(Pixel_shader_input_type In, out Per_pixel_static_variables output)
{
	output = (Per_pixel_static_variables)0;
#if VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS)
	output.screen_space_position = In.position.xy * g_application_halfpixel_viewport_size_inv.zw * g_rc_scale;
#else
	#if my_material_id == MATERIAL_ID_DEFERRED
		float2 _screen_space_position = In.Tex.xy;
		float hw_depth = sample_depth_texture(_screen_space_position * g_rc_scale).r;
		output.world_space_position = get_ws_position_at_gbuffer(hw_depth, _screen_space_position);
	#else
		
#if (my_material_id != MATERIAL_ID_GRASS)
	output.world_space_position = In.world_position.xyz;
#endif

	#endif
	output.screen_space_position = In.position.xy * g_application_halfpixel_viewport_size_inv.zw * g_rc_scale;
	output.view_vector_unorm = g_root_camera_position.xyz - output.world_space_position.xyz;
	output.view_length = length(output.view_vector_unorm);
	output.view_vector = output.view_vector_unorm / output.view_length;

#endif
}


void accumulate_light_contributions(Pixel_shader_input_type In, Per_pixel_static_variables pp_static, Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_TO_USE Output)
{
	//Output.RGBColor.rgb = 0;
}
#endif

#endif
