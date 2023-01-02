#ifndef FLORA_DEFORM_FUNCTIONS_RSH
#define FLORA_DEFORM_FUNCTIONS_RSH

#if(VERTEX_DECLARATION != VDECL_POSTFX)
#if VERTEX_SHADER

void deform_tree_bark(RGL_VS_INPUT In, float4 vertex_colors, inout float3 world_position, float3 object_space_position)
{
	float amount;

	float2 local_wind_dir = g_global_wind_direction.xy;
	float phase_difference = length(world_position.xy)* 4.2f;

	float sin_var = g_time_var + phase_difference * 0.05;

	float random_wind_req = sin_var * 0.01;
	float3 random_winds = float3(0.0, 0.0, 0.0);
	random_winds.yx += float2(cos(random_wind_req), cos(3 * random_wind_req) * 1.35);
	random_winds.yx += float2(cos(random_wind_req * 6) * 0.2, cos(7.8 * random_wind_req) * 0.8);
	random_winds *= float3(local_wind_dir.yx, 0);
	local_wind_dir.xy += random_winds.xy;

	amount = 0.4 + sin(sin_var) * cos(sin_var * 0.5 - 0.37);
	amount *= 0.1;

	float object_z_scale = length(get_column(g_world, 2));
	float normalized_height = object_space_position.z;//* saturate(object_z_scale);

	float linear_height_threshold = 25.37;
	float min_height = 0.2;

	float fAdjust = max(normalized_height - min_height, 0.0f);
	fAdjust = saturate(fAdjust / linear_height_threshold);
	fAdjust = pow(fAdjust, 1.6);

	float3 move_amount = float3(local_wind_dir.xy, 0) * amount * fAdjust;

	world_position.xyz += move_amount;
}

void deform_tree_leaf(RGL_VS_INPUT In, float4 vertex_colors, inout float3 world_position, float3 object_space_position)
{
	const float3 pos_xyz = world_position;

	float2 tex = float2(pos_xyz.x, pos_xyz.y) / 8;
	const float2 global_wind_dir = g_global_wind_direction.xy;
	tex.xy -= global_wind_dir.xy * g_time_var * 0.04;
	float3 wind_tex = sample_texture_level(grass_wind_texture, linear_sampler, tex, 0).rgb;

	deform_tree_bark(In, vertex_colors, world_position, object_space_position);


	float flora_mesh_wind_effect = (1.0f + g_mesh_vector_argument.z) * (2.5f + 1);
	float leaf_vertex_wind_factor = saturate(0.9 - vertex_colors.b);
	float wind_effect = 0.12 *  leaf_vertex_wind_factor * flora_mesh_wind_effect * saturate(pos_xyz.z * 0.17 + dot(pos_xyz, pos_xyz) * 0.12);

	const float wind_power = saturate(g_global_wind_direction_power) * 6.2;
	float3 wind_move = 0;
	wind_move.xy += (wind_tex.r - 0.3) * 0.2;
	wind_move.xy += (wind_tex.g * 0.05) - 0.025;
	wind_move.z += (wind_tex.b - 0.5) * 0.1;

	wind_move.xy *= global_wind_dir;

	world_position.xyz += wind_effect * wind_move;

	float3 snapped_camera = g_camera_position.xyz - fmod(g_camera_position.xyz, 2);
	float3 dirsamp = snow_diffuse_texture.SampleLevel(linear_clamp_sampler, (pos_xyz.xy - snapped_camera.xy + float2(16, 16)) / 32.0f, 0).rgb * 2.0 - 1.0;
	float height_factor = 1 - smoothstep(1.9, 2.0, distance(dirsamp.z * 16 + snapped_camera.z, pos_xyz.z));
	world_position.xyz += float3(dirsamp.xy * 0.5 * leaf_vertex_wind_factor, -length(dirsamp.xy) * leaf_vertex_wind_factor * 0.3) * height_factor;

}
void deform_palm_leaf(RGL_VS_INPUT In, float4 vertex_colors, inout float3 world_position, float3 object_space_position)
{
	deform_tree_bark(In, vertex_colors,world_position, object_space_position);
	const float3 pos_xyz = world_position;

	float2 local_wind_dir = g_global_wind_direction.xy;
	float phase_difference = length(pos_xyz.x)* 1.8 + length(pos_xyz.x)* 2.5 + length(pos_xyz.x)* 3.9;

	//float flora_mesh_wind_effect = (1.0f + phase_difference) * (2.5f + 1);
	float leaf_vertex_wind_factor = (1.0f - vertex_colors.b);
	float leaf_vertex_wind_phase = (1.0f - vertex_colors.g) + phase_difference;

	float displacement_z = sin(g_time_var * 4.0 + leaf_vertex_wind_phase * 1.1)  + sin(g_time_var * 1.0 + leaf_vertex_wind_phase * 4.1) * 0.5 + sin(g_time_var * 6.0 + leaf_vertex_wind_phase * 9.1)  * 1.2;

	world_position.z += length(local_wind_dir) * displacement_z * 0.01f * leaf_vertex_wind_factor;

	float displacement_y = sin(g_time_var * 2.0 + leaf_vertex_wind_phase * 3.1)  + sin(g_time_var * 5.0 + leaf_vertex_wind_phase * 1.1) * 0.2 + sin(g_time_var * 9.0 + leaf_vertex_wind_phase * 1.1)  * 0.4;

	world_position.x += length(local_wind_dir) * (sin(g_time_var * 4.0 + leaf_vertex_wind_phase * 8.1) + displacement_y ) * 0.01f * leaf_vertex_wind_factor;
	world_position.y += length(local_wind_dir) * (sin(g_time_var * 2.0 + leaf_vertex_wind_phase * 4.1) + displacement_y ) * 0.01f * leaf_vertex_wind_factor;
}


void apply_deform_tree_bark_delegate(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable)
{
	deform_tree_bark(In, get_vertex_color(In.color), pv_modifiable.world_position.xyz, In.position.xyz);
}


void apply_deform_tree_leaf_delegate(inout RGL_VS_INPUT input, inout Per_vertex_modifiable_variables pv_modifiable)
{
#if ALIGNMENT_DEFORMATION
	deform_palm_leaf(input, (input.color), pv_modifiable.world_position.xyz, input.position.xyz);
#else
	deform_tree_leaf(input, get_vertex_color(input.color), pv_modifiable.world_position.xyz, input.position.xyz);
#endif
}

//Flora vertex shader functions
void calculate_object_space_values_flora_leaf(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{
#if defined(SHADOWMAP_PASS)
	float4 object_color;	//only used for instanced floras
	rgl_vertex_transform_shadow(In, pv_modifiable.object_position, object_color);
#else

#if SYSTEM_BLOOD_LAYER
	output.local_position = In.position.xyz;
	float4 qtangent = float4(0, 0, 0, 1);
#if !VDECL_HAS_SKIN_DATA
	qtangent = In.qtangent;
#endif
	output.local_normal = get_in_normal(In, normalize(qtangent));
#endif

	float4 object_color = float4(1, 1, 1, 1);//only used for instanced floras
	float3 object_color_rgb;
	rgl_vertex_transform(In, pv_modifiable.object_position, pv_modifiable.object_normal, pv_modifiable.object_tangent, pv_modifiable.prev_object_position, object_color_rgb);
	object_color.rgb = object_color_rgb;

#if VDECL_HAS_SKIN_DATA && SYSTEM_WRITE_MOTION_VECTORS
	output.prev_object_space_position = pv_modifiable.prev_object_position;
	output.object_space_position = pv_modifiable.object_position.xyz;
#endif

#if USE_PROCEDURAL_WIND_ANIMATION
	pv_modifiable.object_position.xyz = simple_wind_animation(pv_modifiable.object_position.xyz, pv_modifiable.vertex_color.a, pv_modifiable.object_normal);
#endif

#if defined(SYSTEM_USE_COMPRESSED_FLORA_INSTANCING) && (my_material_id == MATERIAL_ID_FLORA)
	Instance_data instance_data = g_instance_data[In.instanceID];
	output.albedo_multiplier_center_position = instance_data.position;
#endif
#endif

#if VDECL_IS_DEPTH_ONLY || defined(SHADOWMAP_PASS) || defined(POINTLIGHT_SHADOWMAP_PASS)
	pv_modifiable.vertex_color = float4(1.0f, 1.0f, 1.0f, object_color.a);
#if ALPHA_TEST
	output.vertex_color.a = pv_modifiable.vertex_color.a;
#endif
#else
	pv_modifiable.vertex_color = get_vertex_color(In.color);

	output.vertex_color.a = pv_modifiable.vertex_color.r;
	output.world_normal.w = pv_modifiable.vertex_color.r;
	output.vertex_color.rgb = pv_modifiable.vertex_color.rgb = object_color.rgb;
#endif
}

//World space procedural deformation
void calculate_world_space_values_flora_bark(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{
	pv_modifiable.world_position = mul(g_world, pv_modifiable.object_position);
	pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));

	#ifndef SHADOWMAP_PASS
		#if ENABLE_DYNAMIC_INSTANCING
			Out.world_position.w = In.instanceID + INDEX_EPSILON;
		#endif
	#endif

#if USE_OBJECT_SPACE_TANGENT
	{
		Out.world_tangent.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_tangent.xyz));

		float mesh_frame_handedness;
		{
			float3 mesh_rot_s = get_column(g_world, 0).xyz;
			float3 mesh_rot_f = get_column(g_world, 1).xyz;
			float3 mesh_rot_u = get_column(g_world, 2).xyz;

			float handedness_dot = dot(cross(mesh_rot_u, mesh_rot_s), mesh_rot_f);
			mesh_frame_handedness = (handedness_dot < 0.0) ? -1.0 : 1.0;
		}
		Out.world_tangent.w = -sign(In.qtangent.w) * mesh_frame_handedness;
	}
#endif // VDECL_HAS_TANGENT_DATA

	apply_deform_tree_bark_delegate(In, pv_modifiable);

	Out.position = mul(g_view_proj, pv_modifiable.world_position);

#if !defined(SHADOWMAP_PASS) && !defined(POINTLIGHT_SHADOWMAP_PASS)
	Out.world_position = pv_modifiable.world_position;
	Out.world_position.w = In.instanceID + INDEX_EPSILON;
#endif

#ifdef POINTLIGHT_SHADOWMAP_PASS
	{
#if SYSTEM_INSTANCING_ENABLED
		uint face_index = In.instanceID / g_zero_constant_output;
#else
		uint face_index = In.instanceID;
#endif
		uint light_face_id = light_faces[g_light_face_id + face_index];
		uint light_index = light_face_id / 6;
		uint face = light_face_id % 6;
		uint shadow_index = visible_lights_params[light_index].shadow_params_index;

		float4 shadow_tc = mul(visible_light_shadow_params[shadow_index].shadow_view_proj[face], float4(pv_modifiable.world_position.xyz, 1));

		float4 shadow_tc_copy = shadow_tc;
		shadow_tc.xyz = shadow_tc.xyz / (shadow_tc.w);
		shadow_tc.x = shadow_tc.x / 2 + 0.5;
		shadow_tc.y = shadow_tc.y / 2 + 0.5;
		shadow_tc.y = 1.0 - shadow_tc.y;

		shadow_tc.xy *= visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].zw;
		shadow_tc.xy += visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].xy;
		shadow_tc.xy = shadow_tc.xy * 2.0 - 1.0f;
		shadow_tc.y *= -1;

		Out.position = float4(shadow_tc.xyz * shadow_tc_copy.w, shadow_tc_copy.w);

		[unroll]
		for(uint i = 0; i < 4; i++)
		{
			Out.clip_distances[i] = GetClipDistance(pv_modifiable.world_position.xyz, visible_lights_params[light_index].position.xyz, light_index, face, i);
		}
	}
#endif
}

void calculate_world_space_values_flora_leaf(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type Out)
{

	pv_modifiable.world_position = mul(g_world, pv_modifiable.object_position);
#ifndef SHADOWMAP_PASS
	pv_modifiable.world_normal.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_normal));

#if VDECL_HAS_TANGENT_DATA
	{
		Out.world_tangent.xyz = normalize(mul(to_float3x3(g_world), pv_modifiable.object_tangent.xyz));

		float mesh_frame_handedness;
		{
			float3 mesh_rot_s = get_column(g_world, 0).xyz;
			float3 mesh_rot_f = get_column(g_world, 1).xyz;
			float3 mesh_rot_u = get_column(g_world, 2).xyz;

			float handedness_dot = dot(cross(mesh_rot_u, mesh_rot_s), mesh_rot_f);
			mesh_frame_handedness = (handedness_dot < 0.0) ? -1.0 : 1.0;
		}
		Out.world_tangent.w = -sign(In.qtangent.w) * mesh_frame_handedness;
	}
#endif // VDECL_HAS_TANGENT_DATA
#endif
	apply_deform_tree_leaf_delegate(In, pv_modifiable);

	Out.position = mul(g_view_proj, pv_modifiable.world_position);

#ifndef SHADOWMAP_PASS
	Out.world_position = pv_modifiable.world_position;
#if ENABLE_DYNAMIC_INSTANCING
	Out.world_position.w = In.instanceID + INDEX_EPSILON;
#endif
#endif




#ifdef POINTLIGHT_SHADOWMAP_PASS
	{
#if SYSTEM_INSTANCING_ENABLED
		uint face_index = In.instanceID / g_zero_constant_output;
#else
		uint face_index = In.instanceID;
#endif
		uint light_face_id = light_faces[g_light_face_id + face_index];
		uint light_index = light_face_id / 6;
		uint face = light_face_id % 6;
		uint shadow_index = visible_lights_params[light_index].shadow_params_index;

		float4 shadow_tc = mul(visible_light_shadow_params[shadow_index].shadow_view_proj[face], float4(pv_modifiable.world_position.xyz, 1));

		float4 shadow_tc_copy = shadow_tc;
		shadow_tc.xyz = shadow_tc.xyz / (shadow_tc.w);
		shadow_tc.x = shadow_tc.x / 2 + 0.5;
		shadow_tc.y = shadow_tc.y / 2 + 0.5;
		shadow_tc.y = 1.0 - shadow_tc.y;

		shadow_tc.xy *= visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].zw;
		shadow_tc.xy += visible_light_shadow_params[shadow_index].shadow_offset_and_bias[face].xy;
		shadow_tc.xy = shadow_tc.xy * 2.0 - 1.0f;
		shadow_tc.y *= -1;

		Out.position = float4(shadow_tc.xyz * shadow_tc_copy.w, shadow_tc_copy.w);

		[unroll]
		for(uint i = 0; i < 4; i++)
		{
			Out.clip_distances[i] = GetClipDistance(pv_modifiable.world_position.xyz, visible_lights_params[light_index].position.xyz, light_index, face, i);
		}
	}
#endif
}
void flora_leaf_output_modifier_delegate(inout RGL_VS_INPUT In, inout Per_vertex_modifiable_variables pv_modifiable, inout Vertex_shader_output_type output)
{

}

#endif

#endif

#endif
