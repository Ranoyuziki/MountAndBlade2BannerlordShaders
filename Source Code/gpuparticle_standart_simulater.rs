#include "../shader_configuration.h"

//#include "definitions.rsh"

static const float dT = 0.0099999998;
static const float3 g_gravity = -9.81;

cbuffer Simulation_buffer : register(b_custom_1)
{
	float3 g_wind_direction;
	float g_dT;
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

Texture2D g_random_texture : register(t_custom_0);
Buffer<uint4> counter_buffer : register(t_custom_1);

AppendStructuredBuffer<Particle_buffer>		append_buffer	: register(u_custom_0);
ConsumeStructuredBuffer<Particle_buffer>	consume_buffer	: register(u_custom_1);


[numthreads(512,1,1)]
void main_cs(uint3 dtID : SV_DispatchThreadID, uint3 gID : SV_GroupID)
{
	if(dtID.x < counter_buffer[0].x)
	{		
	
		Particle_buffer particle = consume_buffer.Consume();
		
		particle.elapsed_time += g_dT;
		
		if(particle.elapsed_time < particle.life)
		{			
			float3 dS = particle.velocity;
			
			particle.velocity.z += particle.gravity_constant * g_dT;
			
			particle.velocity *= 1.0 - g_dT * particle.linear_damping;
			
			particle.rotation_speed *= 1.0 - g_dT * particle.angular_damping;
				
			particle.cur_rotation = particle.cur_rotation - particle.rotation_speed * g_dT;
				
			if(particle.elapsed_time < particle.alpha_timings.y)
			{	
				particle.cur_alpha = saturate(particle.elapsed_time / particle.alpha_timings.x);
			}
			else
			{
				particle.cur_alpha = 1.0 - saturate((particle.elapsed_time - particle.alpha_timings.y) / (particle.life - particle.alpha_timings.y));
			}
			
			if(particle.elapsed_time < particle.scale_params.y)
			{	
				if(particle.elapsed_time > particle.scale_params.x)
				{
					particle.cur_scale = lerp(particle.scale_params.z,particle.scale_params.w,saturate((particle.elapsed_time - particle.scale_params.x) / (particle.scale_params.y - particle.scale_params.x)));
				}
				else
				{
					particle.cur_scale = saturate(particle.elapsed_time / particle.scale_params.x) * particle.scale_params.z;
				}
			}
			else
			{
				particle.cur_scale = (1.0 - ((particle.elapsed_time - particle.scale_params.y) / (particle.life - particle.scale_params.y))) * particle.scale_params.w;
			}
			
			//particle.cur_scale = lerp(particle.scale_params.z, particle.scale_params.w, saturate((particle.scale_params.y - particle.remaining_life) / (particle.scale_params.y - particle.scale_params.x)));
			
			dS = (dS + particle.velocity) * 0.5 * g_dT;
			
			//particle.position += dS;
			particle.position += dS;
		
			append_buffer.Append(particle);
		}
	}
}
