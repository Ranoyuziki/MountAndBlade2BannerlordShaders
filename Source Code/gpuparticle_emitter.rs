#include "../shader_configuration.h"

//#include "definitions.rsh"


static const float3 g_uniform_normals[16] = 
{
	float3(0.53812504, 0.18565957, -0.43192),
	float3(0.13790712, 0.24864247, 0.44301823),
	float3(0.33715037, 0.56794053, -0.005789503),
	float3(-0.6999805, -0.04511441, -0.0019965635),
	
	float3(0.06896307, -0.15983082, -0.85477847),
	float3(0.056099437, 0.006954967, -0.1843352),
	float3(-0.014653638, 0.14027752, 0.0762037),
	float3(0.010019933, -0.1924225, -0.034443386),
	
	float3(-0.35775623, -0.5301969, -0.43581226),
	float3(-0.3169221, 0.106360726, 0.015860917),
	float3(0.010350345, -0.58698344, 0.0046293875),
	float3(-0.08972908, -0.49408212, 0.3287904),
	
	float3(0.7119986, -0.0154690035, -0.09183723),
	float3(-0.053382345, 0.059675813, -0.5411899),
	float3(0.035267662, -0.063188605, 0.54602677),
	float3(-0.47761092, 0.2847911, -0.0271716)
};

static const float g_gravity = -9.81;

struct Emitter_buffer
{
	float3	position;
	int		num_particle_to_emit;
	
	float3	random_vec;
	float	emit_sphere_radius;

	float	particle_life;
	float	gravity_constant;
	float2	alpha_timings;
	//x t0
	//y t1

	float3	emit_velocity;
	float	rotation_speed;

	float4	scale_params;
	//x: scale_starting_time
	//y: scale_ending_time
	//z: start_scale
	//w: end_scale

	float3	emit_direction_randomness;
	float	linear_damping;
	
	float	angular_damping;
	float3	padding;
};

struct Particle_buffer
{
	float3	position;
	float	life;

	float3	velocity;
	float gravity_constant;

	float2 alpha_timings;
	//x t0
	//y t1
	float	cur_scale;//In order to avoid calculation in gs/vs
	float	cur_alpha;

	float4	scale_params;
	//x: scale_starting_time
	//y: scale_ending_time
	//z: start_scale
	//w: end_scale
	
	float linear_damping;
	float angular_damping;
	float cur_rotation;
	float rotation_speed;
	
	float elapsed_time;
	float3 padding;
};

cbuffer emitter_buffer : register(b_custom_0)
{
	Emitter_buffer	g_emitters[8];
}

AppendStructuredBuffer<Particle_buffer>		append_buffer	: register(u_custom_0);

Texture2D g_random_texture : register(t_custom_0);
Buffer<uint4> counter_buffer : register(t_custom_1);

//Should be multiple of 64
[numthreads(8,8,1)]
void main_cs(uint3 groupId : SV_GroupThreadID)
{
	Emitter_buffer emitter = g_emitters[groupId.y];
	
	float2 fCounter = float2(emitter.random_vec.z, float(groupId.x) / float(emitter.num_particle_to_emit));
	fCounter.x += fCounter.y;
	
	for(int i=groupId.x ; i < emitter.num_particle_to_emit ; i += 8)
	{
		Particle_buffer new_particle;
		
		float4 random_texture = g_random_texture.SampleLevel(linear_sampler, emitter.random_vec.xy * fCounter.x , 0.0);
		
		random_texture.rgb = random_texture.rgb * 2.0 - 1.0;
		
		random_texture.rgb = normalize(random_texture.rgb);
		
		new_particle.position = emitter.position + random_texture.rgb * emitter.emit_sphere_radius * random_texture.a;
		new_particle.life = emitter.particle_life.x;
		new_particle.elapsed_time = 0;
		//float3 random_direction = reflect(g_uniform_normals[groupId.x + groupId.y],emitter.random_vec);
		
		//new_particle.position = emitter.life.x;
		new_particle.velocity = emitter.emit_velocity + random_texture.rgb * emitter.emit_direction_randomness * fCounter.x;
		fCounter.x += fCounter.y;
		new_particle.gravity_constant = emitter.gravity_constant * g_gravity;
		new_particle.scale_params = emitter.scale_params;
		new_particle.padding = 0;
		new_particle.alpha_timings = emitter.alpha_timings;
		new_particle.cur_scale = 0.0;
		new_particle.cur_alpha = 1.0;
		new_particle.linear_damping = emitter.linear_damping;
		new_particle.angular_damping = emitter.angular_damping;
		new_particle.rotation_speed = emitter.rotation_speed;//emitter.rotation_speed;
		new_particle.cur_rotation = -emitter.random_vec.x * 6.0;
		
		append_buffer.Append(new_particle);
	}	
}
