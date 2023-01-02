#ifndef GPU_PARTICLE_RSH
#define GPU_PARTICLE_RSH

#include "../shader_configuration.h"
#include "definitions.rsh"
#include "shared_functions.rsh"

VS_OUTPUT_STANDART_GPU_PARTICLE main_vs_gpu(RGL_VS_INPUT In)
{
	INITIALIZE_OUTPUT(VS_OUTPUT_STANDART_GPU_PARTICLE, Out);
	
	float4 object_position;
	float3 object_normal, object_tangent, object_binormal;

	Out.vertex_color = get_vertex_color(In.color);
	Out.vertex_color.a *= g_mesh_factor_color.a;
	
	float elevation = floor(In.position.z) - 1;
	
	float p_start_time;
	float3 p_start_position;
	float4 p_start_velocity;
	float3 p_gravitation;
	float2 p_life;
	float4 p_alpha;
	
	float adjusted_time_var = g_time_var;
	
	float effect_start_time = g_mesh_vector_argument.z;
	float normalized_index = elevation / 256;
	float effect_normalized_time = (adjusted_time_var - effect_start_time) * 0.1;

	float randomizer = g_mesh_vector_argument.w ;// cos(effect_start_time * 0.1 + sin(effect_start_time * 0.9) * 3.2);
	//float effect_normalized_time = 1;
	
	float particle_start_time = 0;//(sin(normalized_index * cos(normalized_index * 2.3) * 3.2) + 1) * 0.5;
	float particle_life_time =  1;saturate(cos(normalized_index * 1.45) * tan(normalized_index) * 1.5);
	
	float particle_normalized_time = effect_normalized_time;//saturate(effect_normalized_time - effect_start_time) / (particle_life_time);

	if(particle_normalized_time > 1)
		particle_normalized_time = 1;
	
	Out.vertex_color.a = particle_normalized_time;

	
	float3 initial_position;
	float3 initial_area = float3(0.04, 0.02, 0.03);
	initial_position.x = sin(4 * elevation * (elevation + 0.5)) * cos(4 * elevation * (elevation + 0.5)) * initial_area.x * 1.85 ;
	initial_position.y = sin(elevation * 10.5f) * cos(elevation * 10.5f) * initial_area.y * 6.35;
	initial_position.z = cos(elevation * 2.5f) * initial_area.z * 0.5;
	
	// initial_position.x = sin(elevation * 6.5) * cos(elevation * 3.7) * initial_area.y;
	// initial_position.y = cos(elevation * 2.9) * sin(elevation * 4.5) * initial_area.y;
	// initial_position.z = cos(elevation * 1.5f) * 2; 
	
	float4 middle_point = float4(initial_position,1);
	
	float particle_start_scale = g_mesh_vector_argument.x;
	float particle_end_scale = g_mesh_vector_argument.y;
	
	float particle_current_scale = lerp(particle_start_scale,particle_end_scale,particle_normalized_time) * (1 + saturate(cos(normalized_index * 3.4)) * 0.2);
	

	
	//if(elevation < 2)Z
	{
		float2 xy_dir = normalize(initial_position.xy) * 0.7;// * 40; //float2(1,0);
		

		
		xy_dir += float2(xy_dir.x * cos(normalized_index * 7),xy_dir.y * sin(normalized_index * 8.5));
		
		// float3 destination;
		// destination.xy = xy_dir.xy * (0.4 + sin(normalized_index * 0.6));
		// destination.z = 0;
		
		// float3 control;
		// control.xy = xy_dir.xy * (0.23 + sin(normalized_index * 0.6));
		// control.z = normalized_index * (1.3 + cos(normalized_index * 1.2));


		float gravity = -4;
		
		float3 velocity = float3(xy_dir * abs(float2( cos(normalized_index * 0.5) * 2.3 , cos(normalized_index * 1.8) * 1.3)) , ( sin(normalized_index * 3.4)) * 2.7 );
		
		float3x3 inv_ortho_world = to_float3x3(g_world_inverse);
		inv_ortho_world[0] = normalize(inv_ortho_world[0]);
		inv_ortho_world[1] = normalize(inv_ortho_world[1]);
		inv_ortho_world[2] = normalize(inv_ortho_world[2]);
		float3 local_gravity_force = mul(inv_ortho_world,float3(0,0,-2.5));
		
		middle_point.xyz = projectile_motion_with_drag(initial_position,velocity,local_gravity_force,particle_normalized_time) * (1 + saturate(abs(randomizer) * 0.04) * 1.5);


		
		if(middle_point.z < 0)
			middle_point.z = 0;
		
		//middle_point.xy += xy_dir * effect_normalized_time;
		//middle_point.z += saturate( sin( particle_phase + effect_normalized_time * 3.0f ) );
	}
	
	float4 world_position;
	float3 world_normal;
	
	float3 world_middle;
	
	

	// Out.vertex_color.rgb = lerp(float3(1,1,1),sparkle_color, sin(normalized_index * 25) + 0.4);
	
	world_middle = mul(g_world, middle_point);
	world_normal = normalize(mul(to_float3x3(g_world),object_normal));
	
	float2 billboard_tex_cord = In.tex_coord * 2.0 - 1.0;
	
	float3 right_vector = normalize(get_column(g_inverse_view, 0).xyz);
	float3 gaze_vector = normalize(get_column(g_inverse_view, 2).xyz);
	float3 up_vector = normalize(get_column(g_inverse_view, 1).xyz);
	world_normal = normalize(get_column(g_inverse_view, 2).xyz);
	world_position.w = 1; 
	
	//TODO_MURAT: delete shader
	// up_vector.xy += initial_position.xy * 10.4 * (-0.5 + particle_normalized_time);
	// up_vector = normalize(up_vector);
	// right_vector.xz -= initial_position.xz * 20.5 * (-0.5 + particle_normalized_time);
	// right_vector = normalize(right_vector);

	//up_vector.xy = right_vector + 0.3 * lerp(up_vector.xy,up_vector.yx,normalized_index * 0.6 + particle_normalized_time - 0.45);
	up_vector = normalize(up_vector);
	//right_vector.xy = right_vector + 0.3 * lerp(right_vector.xy,right_vector.yx,normalized_index * 0.6 + particle_normalized_time - 0.45);
	right_vector = normalize(right_vector);
	
	world_position.xyz = world_middle +  billboard_tex_cord.y * up_vector * particle_current_scale  + billboard_tex_cord.x * right_vector * particle_current_scale;
	Out.position = mul(g_view_proj, world_position);


	Out.world_position = world_position;

	Out.tex_coord.xy = In.tex_coord.xy;

	
	#if VDECL_HAS_DOUBLEUV
	Out.tex_coord.zw = In.tex_coord2.xy;
	#endif


	Out.shadow_tex_coord.w = length(g_camera_position.xyz - world_position.xyz);
	Out.world_normal.xyz = world_normal;
	
	
	
	return Out;
}


PS_OUTPUT main_ps_gpu ( VS_OUTPUT_STANDART_GPU_PARTICLE In)
{ 
	PS_OUTPUT Output;
	
	Output.RGBColor = float4(1,0,1,1);
	
	float3 view_direction_unorm = (g_camera_position.xyz - In.world_position.xyz);
	float view_len = length(view_direction_unorm);
	float3 view_direction = view_direction_unorm / view_len; //normalize
	
	//In.world_tangent.xyz = normalize(In.world_tangent.xyz);
	//In.world_binormal.xyz = normalize(In.world_binormal.xyz);
	In.world_normal.xyz = normalize(In.world_normal.xyz);
	
	#if VDECL_HAS_TANGENT_DATA
	float3x3 TBN = create_float3x3(In.world_tangent.xyz, In.world_binormal.xyz, In.world_normal.xyz);
	
	if(bool(USE_PARALLAXMAPPING))
	{
		float3 view_direction_ts = mul(TBN, view_direction_unorm);
		float2 plxCoeffs = float2(0.04, -0.02) * 2;	//adjustable?
	
		float height = sample_normal_texture(In.tex_coord.xy).a;
		float offset = height * plxCoeffs.x + plxCoeffs.y;
		In.tex_coord.xy += offset * normalize(view_direction_ts).xy; //view_direction.xy;
	}
	#endif
	
	float3 normal;

	#if VDECL_HAS_TANGENT_DATA
	{
		float3 normalTS;

		#if SYSTEM_DXT5_NORMALMAP
			normalTS.xy = (2.0f * sample_normal_texture(In.tex_coord.xy).ag - 1.0f);
			//normalTS.xy = sample_normal_texture(In.tex_coord.xy).rg;
			normalTS.z = sqrt(1.0f - dot(normalTS.xy, normalTS.xy));
		#elif SYSTEM_BC5_NORMALMAP
			normalTS.xy = (2.0f * sample_normal_texture(In.tex_coord.xy).rg - 1.0f);
			//normalTS.xy = sample_normal_texture(In.tex_coord.xy).rg;
			normalTS.z = sqrt(1.0f - dot(normalTS.xy, normalTS.xy));
		#else
			normalTS = (2.0f * sample_normal_texture(In.tex_coord.xy).rgb - 1.0f);
		#endif

		//normalTS = float3(0,0,1);
	
		//if(g_normalmap_power != 1.0f)
		{
			normalTS.xy *= g_normalmap_power;
			normalTS = normalize(normalTS);
		}
	
		if(bool(USE_DETAILNORMALMAP))
		{
			float3 detail_normal = sample_detail_normal_texture(In.tex_coord.xy * g_detailmap_scale * 10).rgb * 2.0f - 1.0f;
	
			detail_normal = normalize(detail_normal);
			{
				float3x3 normal_frame; 
				normal_frame[2] = normalTS;
				
				//use material_binormal to convert tangent space to g_world space
				normal_frame[0] = In.world_tangent.xyz;
				normal_frame[1] = normalize(cross(normal_frame[2], normal_frame[0]));
				normal_frame[0] = normalize(cross(normal_frame[1], normal_frame[2]));
				
				normalTS = normalize( mul(detail_normal, normal_frame) );
			}
		}
		
		normal = mul(normalTS, TBN);
		
		
		// Output.RGBColor.rgb = normal.rgb * 0.5f + 0.5f;
		// Output.RGBColor.a = 1;
		// return Output;
	}
	#else // VDECL_HAS_TANGENT_DATA
	{
		normal = In.world_normal.xyz;
	}
	#endif // VDECL_HAS_TANGENT_DATA
	
	float sun_amount = 1;
		
	float4 total_light = get_ambient_term_with_skyaccess(In.world_position, normal, In.position.xy * g_application_halfpixel_viewport_size_inv.zw);
			
	{
		total_light.rgb += (saturate(dot(-g_sun_direction.xyz, normal.xyz))) * sun_amount * g_sun_color.rgb;
	}
	
	#if VDECL_HAS_DOUBLEUV
	{
		float4 lightmap_color = sample_diffuse2_texture(In.tex_coord.zw);
		total_light.rgb = lightmap_color.rgb;
		//tex_col.rgb *= lightmap_color.rgb;
	}
	#endif
	
	Output.RGBColor.rgb = total_light.rgb;
		
	if(!bool(USE_COLORMAPPING))
	{
		Output.RGBColor.rgb *= g_mesh_factor_color.rgb;
	}
	
	float4 tex_col = sample_diffuse_texture(linear_sampler, In.tex_coord.xy);
	

	INPUT_TEX_GAMMA(tex_col.rgb);
	
	
	//area map and self illumination uses same texture target (diffuse 2)

	if(bool(USE_AREAMAP))
	{
		float3 big_color = sample_diffuse2_texture(In.tex_coord.xy / g_areamap_scale).rgb;
		//tex_col *= sample_diffuse_texture(Diffuse2Sampler, In.tex_coord.xy * g_areamap_scale);
		INPUT_TEX_GAMMA(big_color.rgb);
		
		tex_col.rgb = lerp(tex_col.rgb, tex_col.rgb * big_color, g_areamap_amount);
	}
	else if(bool(USE_SELF_ILLUMINATION))
	{
		float3 self_color = sample_diffuse2_texture(In.tex_coord.xy).rgb;
		float tc_eff = (In.tex_coord.x + normal.y + normal.z) * 0.35f;
		float illum_amount = 0.2f + (sin( tc_eff + g_time_var * 6.5f) + cos( tc_eff + g_time_var * 4.15f) + 4.0f) * 0.25f;
		
		Output.RGBColor.rgb += g_debug_vector.x * 1000 * float4(1,0,0, 1);//self_color * illum_amount;
	}
	else if(bool(USE_COLORMAPPING))
	{
		//we are always using 2 team colors on meshes
		float4 colormap = sample_diffuse2_texture(In.tex_coord.xy);
		tex_col = lerp(tex_col, tex_col * g_mesh_factor_color, colormap.r);
		tex_col = lerp(tex_col, tex_col * g_mesh_factor2_color, colormap.g);	
	}

	float spec_tex_factor = sample_specular_texture(In.tex_coord.xy).r;
	
	Output.RGBColor.rgb *= tex_col.rgb;
	Output.RGBColor.rgb *= In.vertex_color.rgb;
	
	//add specular terms 
	
	if(HAS_MATERIAL_FLAG(g_mf_use_specular))
	{
		float3 specColor = 1;

		specColor.rgb *= spec_tex_factor;
		
		specColor.rgb *= g_mesh_factor2_color.rgb;
		
		float3 sun_specColor = specColor.rgb * In.vertex_color.rgb * g_sun_color.rgb * sun_amount;
		
		//sun specular
		float3 vHalf = normalize(view_direction + (-g_sun_direction.xyz));
		float3 fSpecular = sun_specColor.rgb * pow(saturate(dot(vHalf, normal)), 32 * g_mesh_factor2_color.a);
		
		Output.RGBColor.rgb += fSpecular.xyz;
	}
	
	//if we dont use alpha channel for specular-> use it for alpha

	Output.RGBColor.a = saturate(2 - In.vertex_color.a);	//we dont control bUseMotionBlur to fit in 64 instruction
	if(!HAS_MATERIAL_FLAG(g_mf_do_not_use_alpha))
	{
		Output.RGBColor.a *= tex_col.a;
		//Output.RGBColor *= tex_col.a;
	}
	if(bool(USE_GROUND_SLOPE_ALPHA))
	{
		float a_ = saturate(1.0f - normal.z);
		a_ += (Output.RGBColor.a - 0.6f);
		Output.RGBColor.a = saturate( (a_ * 2) - 1 );
	}
	
	Output.RGBColor.rgb = In.vertex_color;
	
	apply_advanced_fog(Output.RGBColor.rgb, view_direction, view_direction_unorm.z * -1.0f, In.shadow_tex_coord.w, 1.0f);
	
	
	//Output.RGBColor.rgb = saturate(normal.z);
	//Output.RGBColor.rgb = saturate(dot(-g_sun_direction, normal));
	//Output.RGBColor.rgb = total_light;
	//Output.RGBColor.rgb = float3(0.0,0.0,0.1);
	//Output.RGBColor = tex_col;
	//Output.RGBColor.rgb = saturate(dot(-g_sun_direction.xyz, normal.xyz)) * sun_amount * g_sun_color.rgb;

	
	
	float life_time = In.vertex_color.a;
	float3 sparkle_color = lerp(float3(1.5,0,0),float3(0.5,0,0), saturate(life_time - 0.2)); 
	sparkle_color = float3(8.5,0.01,0.01);
	Output.RGBColor.rgb = tex_col.rgb;// * sparkle_color;
	Output.RGBColor.a = tex_col.a * (1 - life_time) * life_time * 2;

	
	
	Output.RGBColor.rgb = output_color(Output.RGBColor.rgb);
	
	//Output.RGBColor.rgb = get_ambient_term_with_skyaccess(1, view_direction, normal, -g_skylight_direction.xyz, sun_amount).rgb;
	//Output.RGBColor.rgb = normal.rgb * 0.5f + 0.5f;
	//Output.RGBColor.rgb = get_ambient_term_with_skyaccess(ambientTermType, view_direction, normal, -g_skylight_direction.xyz, sun_amount);

	//Output.RGBColor.rgb = In.vertex_color;
	//clip(Output.RGBColor.a - 0.03);
	
	return Output;
}

#endif
