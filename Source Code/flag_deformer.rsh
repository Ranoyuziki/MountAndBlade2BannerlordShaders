#ifndef FLAG_DEFORMER_RSH
#define FLAG_DEFORMER_RSH

// __________________/\____________________
// phase difference is normalized(0,1)changes the location of the pulse
// interval is based on secs
float long_interval_pulse_generator(float interval, float pulse_strength, float phase, float pulse_width)
{
	float minus_pulse_width = 1.0f - pulse_width;
	float long_signal = saturate(cos(g_time_var * RGL_PI * 2 / interval) - minus_pulse_width) * (1.0f / pulse_width) *  pulse_strength;
	float small_signal = abs(cos(g_time_var * RGL_PI * 2));
	return long_signal /** small_signal*/;
}

float3 apply_flag_deform(inout RGL_VS_INPUT In)	//used for default flags
{
	float3 input_pos = In.position;
	float4 vertex_color = In.color;

	float3 r = input_pos;

	float3 flag_dir = float3(0, 0.5, 0);
	float time_accum = g_time_var;

	//float3 flag_dir = normalize(flag_dir);

	const float amplitude1 = 0.24;
	const float amplitude2 = 0.020;
	const float wave_speed1 = 9;
	const float wave_speed2 = 31;
	const float freq1 = 12.0;
	const float freq2 = 40.1;

	const float wave1_dirx = 0.866;
	const float wave1_diry = 0.50;

	float x = input_pos.x;//saturate(input_pos.x -0.05f);
	float y = input_pos.y;
	float z = input_pos.z;

	float d = (x * wave1_dirx + z * wave1_diry);

	float factor = get_vertex_color(vertex_color).r;

	//float freq_mod = 0.0035;
	// better for big flags but not needed for small ones.
	//float wave = amplitude1 * x * sin( d * ( 1- d * freq_mod) * freq1  - wave_speed1 * time_accum) +  amplitude2 * x * sin(x * freq2 - wave_speed2 * time_accum);

	const float frequency_multiplier = 3.5;
	float small_wave = 0.32 * sin(((x * 0.6 + z * 0.3) + time_accum) * freq1 * 0.17 * frequency_multiplier);
	float long_wave = 0.16 * sin(((x * 0.1 + z * 0.3) * small_wave + 2.8f + time_accum) * freq1 * 0.05 * frequency_multiplier);
	float long_wave_2 = 0.16 * sin(((x * 0.2 + z * 0.2) * small_wave + 1.3f + time_accum) * freq1 * 0.05 * frequency_multiplier);
	float wave_4 = 0.1 * saturate(long_wave_2) * sin((float2(x * 0.1, z * 0.25) + time_accum.xx).x * smooth_triangle_wave(saturate(long_wave * 0.7 + small_wave * 0.3)).x * 0.0005 * frequency_multiplier);

	float x_movement = saturate(long_wave * 0.6 + 0.4f * long_wave_2) * small_wave * 0.1 + long_wave_2 * 0.1 + wave_4 * 0.3;
	float y_movement = /*wave_4 * 0.8 +*/ long_wave * 1.8 * small_wave + saturate(long_wave * 0.3 + 0.7f * long_wave_2) * small_wave * 0.21;
	float z_movement = small_wave * 0.1 + wave_4 * 0.2 * saturate(long_wave * 0.3 - 0.7f * long_wave_2);

	float x_amount = long_wave * 0.2 + long_wave_2  * 0.5 + small_wave * 0.3;

	float small_factor = saturate(pow(abs(factor), 0.3));
	float big_factor = saturate(pow(abs(factor), 0.1));

	float3 wave = float3(x_movement * 0.44 * big_factor, y_movement * 0.35 * big_factor, z_movement * 0.45 * small_factor) * 1.45;

	float small_pulse = long_interval_pulse_generator(4.5, 1.23 * (x_movement + z_movement), x * 0.7 + z * 0.6, 0.05);
	float3 wave_without_pulse = wave;
	wave.x += small_pulse * big_factor;
	wave.z += small_pulse * small_factor * 0.8;
	r += wave;

	float3 diff = (r - input_pos) * 1.73f;

	float ao = saturate(abs(wave_without_pulse.x * 2.6) + abs(wave_without_pulse.y * 2.6) + abs(wave_without_pulse.z * 2.6) + 0.1) * 1.7;
	float4 ambient_occlusion = pow(saturate(float4(ao.xxx, 1)), 0.98);
	float4 new_color;
	set_vertex_color(ambient_occlusion, new_color);

	//In.color = float4(1.0f, 1.0f, 1.0f, 1.0f) * (1.0f - small_factor) + small_factor * new_color;

	return r;
}

float3 apply_flag_deform_simple(float3 input_pos, float4 vertex_color, out float3 normal)	//used for campaign map party banners
{
	float3 r = input_pos;

	float3 flag_dir = float3(0, 1, 0);
	float time_accum = g_time_var; //g_mesh_vector_argument.w;

								   //float3 flag_dir = normalize(flag_dir);

	const float amplitude1 = 0.14;
	const float amplitude2 = 0.020;
	const float wave_speed1 = 5;
	const float wave_speed2 = 31;
	const float freq1 = 12.0;
	const float freq2 = 40.1;

	const float wave1_dirx = 0.866;
	const float wave1_diry = 0.50;

	float side = saturate(abs(input_pos.x) - 0.05f);
	float x = input_pos.x;
	float y = input_pos.y;
	float z = input_pos.z;

	float d = (x * wave1_dirx + z * wave1_diry);


	//float freq_mod = 0.0035;
	// better for big flags but not needed for small ones.s
	//float wave = amplitude1 * x * sin( d * ( 1- d * freq_mod) * freq1  - wave_speed1 * time_accum) +  amplitude2 * x * sin(x * freq2 - wave_speed2 * time_accum);

	float wave = amplitude1 * sin(d * freq1 - wave_speed1 * time_accum) * vertex_color.r;
	float normal_component = cos(d * freq1 - wave_speed1 * time_accum) * 0.19 * vertex_color.r;
	//	float3 dwave = float3( amplitude1 * ( sin( d * freq1  - wave_speed1 * time_accum)  + wave1_dirx * x * cos( d * freq1  - wave_speed1 * time_accum) ) ,
	//				  0,
	//				  amplitude1 * x * cos( d * freq1  - wave_speed1 * time_accum) * wave1_diry );

	r.y += 0.12 * wave;
	r.x -= 0.2 * wave;

	r.z = r.z + x * flag_dir.x;
	r.x = r.x - x * (1 - flag_dir.y);

	normal.y = 1;
	normal.x = normal_component * 0.9;
	normal.z = normal_component * 0.9;

	return r;
}


void apply_flag_deform_delegate(inout RGL_VS_INPUT input)
{
	input.position = apply_flag_deform(input);
}

void apply_flag_deform_simple_delegate(inout RGL_VS_INPUT input)
{
	float4 qtangent = normalize(input.qtangent);
	float3 normal = quat_to_mat_zAxis(qtangent);
	input.position = apply_flag_deform_simple(input.position, input.color, normal);
}

#endif
