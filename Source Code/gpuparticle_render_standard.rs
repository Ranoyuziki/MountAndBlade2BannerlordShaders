
#include "../shader_configuration.h"


#include "definitions.rsh"
#include "shared_functions.rsh"

static const float2 gTexCoords[4] =
{
	float2(0,0),
	float2(0,1.0),
	float2(1.0,1.0),
	float2(1.0,0)
};

static const float2 gGradientPoints[4] =
{
	float2(-0.6,-0.6),
	float2(-0.6,0.6),
	float2(0.6,0.6),
	float2(0.6,-0.6)
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

StructuredBuffer<Particle_buffer> g_particles	: register(t17);
//ConsumeStructuredBuffer<Particle_buffer> consume_buffer		;

struct VS_OUTPUT_GPU_PARTICLE
{
	float3 pos : Position;
	float scale : Scale;
	float rotation : Rotation;
	float alpha : Alpha;
	float2 velocity : Velocity;
};

struct GS_OUTPUT_GPU_PARTICLE
{
	float4 pos	: SV_Position;
	float2 tex0 : TEXCOORD0;
	float3 normal : TEXCOORD1;
	float2 gradient_point : TEXCOORD2; //Fake gradient normal
	float alpha : Alpha;
};

VS_OUTPUT_GPU_PARTICLE main_vs(uint vid : SV_VertexID)
{
	VS_OUTPUT_GPU_PARTICLE Out;
	Out.pos = g_particles[vid].position.xyz;
	Out.scale = g_particles[vid].cur_scale;
	Out.rotation = g_particles[vid].cur_rotation;
	Out.alpha = g_particles[vid].cur_alpha;
	Out.velocity = g_particles[vid].velocity.xy;
	//Out.pos.y += vid * 0.1;
	return Out;
}

[maxvertexcount(4)]
void main_gs(point VS_OUTPUT_GPU_PARTICLE In[1], inout TriangleStream<GS_OUTPUT_GPU_PARTICLE> Out)
{
	GS_OUTPUT_GPU_PARTICLE center;
	
	float aspect_ratio = (g_application_halfpixel_viewport_size_inv.y / g_application_halfpixel_viewport_size_inv.x);
	float3 world_normal = normalize(g_camera_position.rgb - In[0].pos);
	world_normal = float3(normalize(In[0].velocity.rg),0);
	// float4 offset[4] =
	// {
		// {-0.05 * In[0].scale,	0.05 * aspect_ratio * In[0].scale	,0,0},
		// {-0.05 * In[0].scale,	-0.05 * aspect_ratio * In[0].scale	,0,0},
		// {0.05 * In[0].scale,	-0.05 * aspect_ratio * In[0].scale	,0,0},
		// {0.05 * In[0].scale,	0.05 * aspect_ratio * In[0].scale	,0,0}
	// };
	
	
	float cosTheta;
	float sinTheta;
	sincos(In[0].rotation, sinTheta, cosTheta);
	//float cosTheta =  cos(In[0].rotation);
	//float sinTheta = sqrt(1.0 - cosTheta * cosTheta);
	
	float2x2 rotMtx =
	{
		{cosTheta, -sinTheta},
		{sinTheta, cosTheta}
	};
	
	
	/*float2x2 rot_mtx[4] =
	{
		{0,		0.05,	,0	,0},
		{-0.05,	0		,0	,0},
		{0,		-0.05	,0	,0},
		{0.05,	0		,0	,0}
	};*/
	
	center.pos = mul(g_view_proj, float4(In[0].pos,1.0) );
	//center.pos = float4(In[0].pos,1);
	
	//center.pos.z = 0;
	//center.pos.w = 1.0;sa
		
	
	GS_OUTPUT_GPU_PARTICLE vertex;
	
	vertex.alpha = In[0].alpha;
	
	float4 vertex_pos = float4(0,0.05 * In[0].scale,0,0);
	//vertex_pos.xy = mul(vertex_pos.xy, rotMtx);
	vertex_pos.xy = mul(rotMtx, vertex_pos.xy);
	vertex_pos.y *= aspect_ratio;
	vertex.tex0 = gTexCoords[3];
	vertex.pos = center.pos + vertex_pos;
	vertex.gradient_point = gGradientPoints[3];
	vertex.normal = world_normal;
	Out.Append(vertex);
	
	
	
	
	vertex_pos = float4(-0.05 * In[0].scale,0,0,0);
	vertex_pos.xy = mul(rotMtx, vertex_pos.xy);
	vertex_pos.y *= aspect_ratio;
	vertex.tex0 = gTexCoords[0];
	vertex.gradient_point = gGradientPoints[0];
	vertex.pos = center.pos + vertex_pos;
	Out.Append(vertex);
	
	
	
	
	
	vertex_pos = float4(0.05 * In[0].scale,0,0,0);
	vertex_pos.xy = mul(rotMtx, vertex_pos.xy);
	vertex_pos.y *= aspect_ratio;
	vertex.tex0 = gTexCoords[2];
	vertex.gradient_point = gGradientPoints[2];
	vertex.pos = center.pos + vertex_pos;
	Out.Append(vertex);
	
	
	
	
	
	vertex_pos = float4(0,-0.05 * In[0].scale,0,0);
	vertex_pos.xy = mul(rotMtx, vertex_pos.xy);
	vertex_pos.y *= aspect_ratio;
	vertex.tex0 = gTexCoords[1];
	vertex.gradient_point = gGradientPoints[1];
	vertex.pos = center.pos + vertex_pos;
	Out.Append(vertex);
	
	
	//for(int i=0 ; i < 4 ; i++)
	//{
	//	float3 g_camera_position.rgb +
	//	vertex.pos = float4(In[0].pos, 1.0);
	//	Out.Append(vertex);
	//}
	
	Out.RestartStrip();
}

#if PIXEL_SHADER
float4 main_ps(GS_OUTPUT_GPU_PARTICLE input) : SV_Target
{

	float4 Output;
	
	Output = sample_diffuse_texture(linear_sampler, input.tex0);
	
	float3 total_light = get_ambient_term_with_skyaccess(input.pos, input.normal, input.pos.xy * g_application_halfpixel_viewport_size_inv.zw);

	//total_light += SimpleLambert(input.normal, -g_sun_direction.xyz) * g_sun_color.rgb;
	float sun_amount = dot(normalize(input.normal.xy),normalize(-g_sun_direction.xy));
	sun_amount = sun_amount * 0.5 + 0.5;
	sun_amount = (sun_amount + 0.7) / (1.7);
	total_light += sun_amount * g_sun_color.rgb;
	
	Output.rgb *= total_light;	
	
	//Output.rgb = dot(normalize(input.normal.xy),normalize(-g_sun_direction.xy)).rrr;
	
	Output.rgb = output_color(Output.rgb);
		
	Output.a *= input.alpha;
	
	return Output;
}
#endif
