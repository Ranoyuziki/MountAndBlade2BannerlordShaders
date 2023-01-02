
#include "definitions.rsh"

#define MONTE_CARLO_WIDTH 512
#define MONTE_CARLO_HEIGHT 256
#define INV_MONTE_CARLO_HEIGHT (1.0f / (float)MONTE_CARLO_HEIGHT)
#define INV_MONTE_CARLO_WIDTH (1.0f / (float)MONTE_CARLO_WIDTH)

#define PI 3.14

#ifdef USE_DIRECTX12
#define cubemap (TextureCube_table[indices.t_custom_0])
#define output (RWBuffer_float4_table[indices.u_custom_0])
#else
TextureCube cubemap : register (t_custom_0);
RWBuffer<float4> output : register(u_custom_0);
#endif

groupshared float4 colors_of_rows[MONTE_CARLO_HEIGHT * 6];

float3 get_direction_from_sample_index(float a, float b)
{
	float theta = acos(sqrt(1 - a));	//vertical 90* rotation vector
	float phi = 2 * PI * b;				//horizontal 360* rotation vector

	float right_vector = sin(theta)*cos(phi);
	float forward_vector = sin(theta)*sin(phi);
	float up_vector = cos(theta);
	
	return normalize(float3(right_vector, forward_vector, up_vector));
}

#define BASIS_XY_0 float3(1,0,0)
#define BASIS_XY_1 float3(0,1,0)
#define BASIS_XY_2 float3(-1,0,0)
#define BASIS_XY_3 float3(0,-1,0)
#define BASIS_DOWN float3(0,0,-1)
#define BASIS_UP float3(0,0,1)


float3 sample_skybox_cubemap(float3 final_dir)
{
	return cubemap.SampleLevel(point_sampler, final_dir.xzy, 0).rgb / g_postfx_target_exposure;
}

/*
float3 sample_skybox_180(float3 view_dir)
{
	float theta = g_sky_rotation * 0.0174532925199433f;
	float ct = cos(theta);
	float st = sin(theta);

	float3 rotated_dir = view_dir;
	rotated_dir.x = ct * view_dir.x - st * view_dir.y;
	rotated_dir.y = st * view_dir.x + ct * view_dir.y;
	rotated_dir.z = view_dir.z;

	//rotated_dir.y *= -1;
	float3 final_dir;
	final_dir.x = rotated_dir.x;
	final_dir.y = rotated_dir.z;
	final_dir.z = rotated_dir.y;
	final_dir.y *= -1;

	float r = (1 / PI) * acos(final_dir.z) / sqrt(final_dir.x * final_dir.x + final_dir.y * final_dir.y);
	float2 uv = float2(atan2(final_dir.z, final_dir.x) + PI, acos(final_dir.y));
	uv.x /= 2.0 * PI;
	uv.y /= PI;

	uv.y = 1.0 - uv.y;
	uv.y = uv.y * 2.0;
	
	return cubemap.SampleLevel(point_sampler, uv, 0);
}*/

[numthreads(MONTE_CARLO_HEIGHT, 1, 1)]
void main_cs(uint3 globalIdx : SV_DispatchThreadID, uint3 localIdx : SV_GroupThreadID, uint3 groupIdx : SV_GroupID)
{
	uint row_id = localIdx.x;
	uint basis_id = localIdx.y;

	float4 total_colors[6];
	total_colors[0] = float4(0,0,0,0);
	total_colors[1] = float4(0,0,0,0);
	total_colors[2] = float4(0,0,0,0);
	total_colors[3] = float4(0,0,0,0);
	total_colors[4] = float4(0,0,0,0);
	total_colors[5] = float4(0,0,0,0);
	
	float row_normalized = INV_MONTE_CARLO_HEIGHT * row_id;
	for(int i = 0 ; i < MONTE_CARLO_WIDTH; i++)
	{
		float column_normalized = i * INV_MONTE_CARLO_WIDTH;
		float3 direction = get_direction_from_sample_index(column_normalized , row_normalized);
		
		float3 sky_color_sampled = sample_skybox_cubemap(direction);
		
		float ndotls[6];
		ndotls[0] = saturate(dot(direction, BASIS_XY_0));
		ndotls[1] = saturate(dot(direction, BASIS_XY_1));
		ndotls[2] = saturate(dot(direction, BASIS_XY_2));
		ndotls[3] = saturate(dot(direction, BASIS_XY_3));
		ndotls[4] = saturate(dot(direction, BASIS_DOWN));
		ndotls[5] = saturate(dot(direction, BASIS_UP));
		
		/*if(direction.y < 0)
		{
			ndotls[0] = 0;
			ndotls[1] = 0;
			ndotls[2] = 0;
			ndotls[3] = 0;
			ndotls[4] = 0;
			ndotls[5] = 0;
		}*/
		
		total_colors[0].rgb += sky_color_sampled * ndotls[0];
		total_colors[1].rgb += sky_color_sampled * ndotls[1];
		total_colors[2].rgb += sky_color_sampled * ndotls[2];
		total_colors[3].rgb += sky_color_sampled * ndotls[3];
		total_colors[4].rgb += sky_color_sampled * ndotls[4];
		total_colors[5].rgb += sky_color_sampled * ndotls[5];
		
		total_colors[0].a += ndotls[0];
		total_colors[1].a += ndotls[1];
		total_colors[2].a += ndotls[2];
		total_colors[3].a += ndotls[3];
		total_colors[4].a += ndotls[4];
		total_colors[5].a += ndotls[5];
		
		
	}

	colors_of_rows[row_id * 6 + 0] = total_colors[0];
	colors_of_rows[row_id * 6 + 1] = total_colors[1];
	colors_of_rows[row_id * 6 + 2] = total_colors[2];
	colors_of_rows[row_id * 6 + 3] = total_colors[3];
	colors_of_rows[row_id * 6 + 4] = total_colors[4];
	colors_of_rows[row_id * 6 + 5] = total_colors[5];
	
	GroupMemoryBarrierWithGroupSync();
	
	if(row_id == 0)
	{
		total_colors[0] = float4(0,0,0,0);
		total_colors[1] = float4(0,0,0,0);
		total_colors[2] = float4(0,0,0,0);
		total_colors[3] = float4(0,0,0,0);
		total_colors[4] = float4(0,0,0,0);
		total_colors[5] = float4(0,0,0,0);

		[loop]
		for(int sample_id = 0; sample_id < MONTE_CARLO_HEIGHT; sample_id++)
		{
			[unroll]
			for(int basis_id = 0; basis_id < 6; basis_id++)
			{
				total_colors[basis_id] += colors_of_rows[sample_id * 6 + basis_id];
			}
		}

		output[0] = float4(total_colors[0].rgb * 2.0f / (total_colors[0].a + 0.01), 1);
		output[1] = float4(total_colors[1].rgb * 2.0f / (total_colors[1].a + 0.01), 1);
		output[2] = float4(total_colors[2].rgb * 2.0f / (total_colors[2].a + 0.01), 1);
		output[3] = float4(total_colors[3].rgb * 2.0f / (total_colors[3].a + 0.01), 1);
		output[4] = float4(total_colors[4].rgb * 2.0f / (total_colors[4].a + 0.01), 1);
		output[5] = float4(total_colors[5].rgb * 2.0f / (total_colors[5].a + 0.01), 1);
	}
}


