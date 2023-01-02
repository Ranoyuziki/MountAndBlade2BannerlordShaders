#ifndef GBUFFER_FUNCTIONS_RSH
#define GBUFFER_FUNCTIONS_RSH

#include "definitions_samplers.rsh"
#include "shared_functions.rsh"
#include "modular_struct_definitions.rsh"
#include "terrain_mesh_blend_functions.rsh"
#include "shared_decal_functions.rsh"
#include "speedtree_depth_functions.rsh"

#define gbuffer__albedo_thickness texture3
#define gbuffer__normal texture1
#define gbuffer__spec_gloss_ao_shadow texture2

#if PIXEL_SHADER
//TODO_MURAT2 : cleanup
#if !( my_material_id == MATERIAL_ID_TERRAIN )

float calculate_occlusion_info_for_gbuffer(Pixel_shader_input_type In, Per_pixel_modifiable_variables pp_modifiable, Per_pixel_auxiliary_variables pp_aux)
{
	float occlusion = 1.0f;
	
	#if( my_material_id == MATERIAL_ID_STANDART || my_material_id == MATERIAL_ID_METALLIC || my_material_id == MATERIAL_ID_FACE || my_material_id == MATERIAL_ID_TRANSLUCENT_FACE)
		float2 tex_coord = float2(0.0f,0.0f);
		float3 vertex_color = float3(1,1,1);
		
		#if VERTEX_DECLARATION != VDECL_POSTFX
			tex_coord = In.tex_coord.xy;
			vertex_color = In.vertex_color.xyz;
		#endif

#if defined(SYSTEM_SNOW_LAYER)
			occlusion = 1;
#else
		if(bool(USE_ANISO_SPECULAR))
		{
			//TODO_GOKHAN1 hair material id
			//no texture
		}
		else if (bool(USE_SPECULAR_FROM_DIFFUSE))
		{
			float3 albedo = pp_modifiable.diffuse_sample.xyz;
			occlusion *= saturate(max((albedo.x + albedo.y + albedo.z + 0.2), 0.01)) * g_ambient_occlusion_coef;
			occlusion = saturate(occlusion);
		}
		else if(HAS_MATERIAL_FLAG(g_mf_use_specular))
		{
#if defined(USE_UNIFIED_LOD)
			float ao_map = 0.7;
#else
			float ao_map = pp_modifiable.specular_sample.b;
#endif
			occlusion *= ao_map * g_ambient_occlusion_coef;
			occlusion = saturate(occlusion);
		}
#endif
		if( ! bool(USE_VERTEX_COLORS) )
		{
			occlusion *= vertex_color.r;
		}
		#elif ( my_material_id == MATERIAL_ID_FLORA )
		{
			if(HAS_MATERIAL_FLAG(g_mf_use_specular))
			{
			 occlusion *= pp_modifiable.specular_sample.b;
			}
			occlusion *= In.vertex_color.r;
			occlusion = sqrt(occlusion);
		}
        #elif ( my_material_id == MATERIAL_ID_FLORA_BILLBOARD  || my_material_id == MATERIAL_ID_FLORA_BILLBOARD_DYNAMIC_SHADOWED)
		{
			occlusion *= sample_normal_texture(In.tex_coord.xy).a;
		}
	#elif ( my_material_id == MATERIAL_ID_GRASS )
		#if !defined(SHADOWMAP_PASS)
		occlusion = pp_modifiable.ambient_ao_factor;
		#endif
	#elif( my_material_id == MATERIAL_ID_NONE)
		occlusion = pp_modifiable.ambient_ao_factor;
	#endif

	return occlusion;
}

#endif
#endif





float3 get_ws_position_at_gbuffer_deprecated(in float hw_depth, in float2 uv)
{
	float x = uv.x * 2 - 1;
	float y = (1.0 - uv.y) * 2.0 - 1.0;

	float3 cam_dir = -get_row(g_view, 2).xyz;
	float3 cam_right = get_row(g_view, 0).xyz;
	float3 cam_up = get_row(g_view, 1).xyz;

	float linear_depth = hw_depth_to_linear_depth(hw_depth);

	float3 up_vec = y * cam_up * g_camera_top;
	float3 right_vec = x * cam_right * g_camera_right;

	float3 camera_pos = cam_dir * g_camera_near + right_vec + up_vec;
	camera_pos = (camera_pos / g_camera_near) * linear_depth;

	return g_camera_position.xyz + camera_pos;
}

float3 get_ws_position_at_gbuffer(in float hw_depth, in float2 uv)
{
	float x = uv.x * 2 - 1;
	float y = (1.0 - uv.y) * 2.0 - 1.0;

	float4 position_ws = mul(g_view_proj_inverse, float4(x, y, hw_depth, 1.0));
	position_ws.xyz /= position_ws.w;

	return position_ws.xyz;
}


float3 get_vs_position_at_gbuffer(in float hw_depth, in float2 uv)
{
	float3 ws_position = get_ws_position_at_gbuffer(hw_depth, uv);
	return mul(g_view, float4(ws_position, 1.0f)).xyz;
}

#define EPSILON 0.00001

float2 encodeNormal(float3 ws_normal)
{
	float3 view_normal = mul(to_float3x3(g_view), ws_normal);

	//USE_Stereographic_Projection
	float scale = 1.7777;
	float2 enc = view_normal.xy / (view_normal.z + 1);
	enc /= scale;
	enc = enc*0.5 + 0.5;
	return enc;
}

float3 decodeNormalVS(float2 encodedNormal)
{
	float scale = 1.7777;
	float3 nn = float3(-scale, -scale, 1);
	nn.xy += encodedNormal.xy*scale * 2;

	float g = 2.0 / dot(nn.xyz, nn.xyz);
	float3 view_normal;
	view_normal.xy = g*nn.xy;
	view_normal.z = g - 1;

	return view_normal;
}

float3 get_ws_normal_at_gbuffer(in float2 pixel_gbuffer)
{
	float3 vs_normal = decodeNormalVS(pixel_gbuffer.xy);
	return mul(to_float3x3(g_inverse_view), vs_normal);
}

float3 get_vs_normal_at_gbuffer(in float2 pixel_gbuffer)
{
	return decodeNormalVS(pixel_gbuffer.xy);
}

void set_gbuffer_values(inout PS_OUTPUT_GBUFFER Out, float3 _world_space_normal, float final_alpha, float3 _albedo_color, float2 _specularity_info, float occlusion,
	float3 vertex_normal, float translucency, float shadow, float4 resolve_output = float4(0, 0, 0, 0))
{
	Out = (PS_OUTPUT_GBUFFER)0;

	Out.gbuffer_normal_xy_dummy_alpha.xy = encodeNormal(_world_space_normal);
	float2 vertex_normal_compressed = encodeNormal(vertex_normal);
	Out.gbuffer_vertex_normal_xy.xy = vertex_normal_compressed.xy;
	
#ifdef USE_GAMMA_CORRECTED_GBUFFER_ALBEDO
	OUTPUT_GAMMA(_albedo_color.rgb);
#endif
	Out.gbuffer_albedo_thickness = float4(_albedo_color, translucency);
	Out.gbuffer_spec_gloss_ao_shadow = float4(_specularity_info, occlusion, shadow);
	
#if SYSTEM_OUTPUT_ALPHA_TO_GBUFER
	Out.gbuffer_normal_xy_dummy_alpha.w = final_alpha;
	Out.gbuffer_albedo_thickness.w = final_alpha;
	Out.gbuffer_spec_gloss_ao_shadow.w = final_alpha;
#endif

#if USE_VIRTUAL_TEXTURING
	Out.vt_resolve = resolve_output;
#endif



}

#ifndef WATER_RENDERING
void set_decal_entity_id(in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, Pixel_shader_input_type In, inout uint entity_id)
{
	[branch]
	if (g_use_tiled_decal_rendering)
	{
		float2 ss_pos = saturate(pp_static.screen_space_position);
		uint2 tile_counts = (uint2)ceil(g_application_viewport_size / RGL_TILED_CULING_TILE_SIZE);
		uint2 tile_index = (uint2)((ss_pos * g_application_viewport_size) / RGL_TILED_CULING_TILE_SIZE);
		uint start_index = MAX_DECALS_PER_TILE * (tile_counts.x * tile_index.y + tile_index.x);
		uint2 probe_index = visible_decals[start_index];

		float pixel_depth = mul(g_view_proj, float4(pp_static.world_space_position.xyz, 1)).w;

		float dist_fade_out_val = smoothstep(0, 1, (MAX_DISTANCE_DECAL_TILE - pixel_depth) * 0.01); //magic number can be adjusted for smoother transition

		[loop]
		while (probe_index.x != 0xFFFF)
		{
			DecalParams decal_render_params = visible_decal_render_params[probe_index.x];

			[branch]
			if (
#if my_material_id == MATERIAL_ID_TERRAIN
				decal_render_params.decal_flags & rgl_decal_flag_render_on_terrain
#elif my_material_id == MATERIAL_ID_FLORA
				decal_render_params.decal_flags & rgl_decal_flag_render_on_grass
#else
				decal_render_params.decal_flags & rgl_decal_flag_render_on_objects
#endif
				)
			{
				float4 decal_d = 0;

				float4x4 d_data_frame_inv = decal_render_params.frame_inv;

				float4 pixel_pos_in_os = mul(d_data_frame_inv, float4(pp_static.world_space_position, 1));
				pixel_pos_in_os.xyz /= pixel_pos_in_os.w;;

				float2 tc_init = (pixel_pos_in_os.xy + 1.0) * 0.5;
				float2 tc_d = get_atlassed_decal_texture_tc(tc_init, decal_render_params.d_atlas_uv_d, decal_render_params.atlas_uv);

				float4 pixel_pos_in_os2 = mul(d_data_frame_inv, float4(pp_static.world_space_position, 1));
				pixel_pos_in_os2.xyz /= pixel_pos_in_os2.w;

				float3 clipSpacePos = float3(pixel_pos_in_os.xy, pixel_pos_in_os2.z);
				float3 uvw = clipSpacePos.xyz*float3(0.5f, -0.5f, 0.5f) + 0.5f;

				// discard outside of the frame
				[branch]
				if (!any(uvw - saturate(uvw)))
				{
					// angle rejecting
					float threshold_angle_cos = 0.4;
					float edgeBlend = 1 - pow(saturate(abs(clipSpacePos.z)), 8);

					if (any(tc_d))
					{
						decal_d = decal_atlas_texture.SampleLevel(linear_clamp_sampler, tc_d, 3);
					}

					decal_d *= decal_render_params.factor_color_1;
					decal_d.a *= edgeBlend;
					if (!(decal_render_params.decal_flags & rgl_decal_flag_override_visibility_checks))
					{
						decal_d.a *= dist_fade_out_val;
					}

					if (decal_d.a > 0.5)
					{
						entity_id = decal_render_params.entity_id;
					}
				}
			}//render decal
			probe_index = visible_decals[++start_index];
		}
	}
}
#endif

#if PIXEL_SHADER
void set_gbuffer_entity_id(in Pixel_shader_input_type In, in Per_pixel_static_variables pp_static, inout Per_pixel_modifiable_variables pp_modifiable, inout PS_OUTPUT_GBUFFER Out)
{
#if (SYSTEM_DRAW_ENTITY_IDS)
	{

#if((my_material_id == MATERIAL_ID_STANDART) || (my_material_id == MATERIAL_ID_METALLIC) || (my_material_id == MATERIAL_ID_FACE) || (my_material_id == MATERIAL_ID_FLORA && !SYSTEM_INSTANCING_ENABLED))
		{
			Out.entity_id.r = g_entity_id;//float4(0, 1, 1, 0);
			Out.entity_id.g = g_mesh_id;
		}
#endif

#if (my_material_id != MATERIAL_ID_FACE) && (my_material_id != MATERIAL_ID_SKYBOX) && (my_material_id != MATERIAL_ID_TRANSLUCENT_FACE) && !defined(WATER_RENDERING) && !defined(STANDART_FOR_HORSE) && !defined(STANDART_FOR_EYE) && !defined(STANDART_FOR_CROWD)
		set_decal_entity_id(pp_static, pp_modifiable, In, Out.entity_id.r);
#endif

	}
#endif

#if defined(SPEEDTREE_BILLBOARD)
#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS) && !defined(CONSTANT_OUTPUT_PASS)
	compute_billboard_depth(In, Out);
#endif
#endif
}
#endif

void set_shadowmap_values(inout PS_OUTPUT Out, float pos)
{
	Out.RGBColor.rgb = float3(pos, pos, pos);
}

#endif
