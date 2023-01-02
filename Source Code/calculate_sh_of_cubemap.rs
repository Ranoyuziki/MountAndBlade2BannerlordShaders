
#include "definitions.rsh"

#ifdef USE_DIRECTX12
#define cubemap (TextureCube_table[indices.t_custom_0])
#define output (RWBuffer_float4_table[indices.u_custom_0])
#else
TextureCube cubemap : register (t_custom_0);
RWBuffer<float4> output : register(u_custom_0);
#endif

//#define basis1_up float3(-0.40,-0.70,0.57)
//#define basis1_side float3(-0.91 , 0.31f, -0.25f)
//#define basis1_forward float3(0 , 0.63f , 0.77)
//
//#define basis2_up float3(-0.40,0.70,0.57)
//#define basis2_side float3(-0.91 , -0.31f, -0.25f)
//#define basis2_forward float3(0 , 0.63f , -0.77)
//
//#define basis3_up float3(0.8164,0,0.57)
//#define basis3_side float3(-0.57 , 0.0f, 0.81f)
//#define basis3_forward float3(0 , 1.0f , 0.57)

struct SH_coefs
{
	float3 coefs0;
	float3 coefs1;
	float3 coefs2;
	float3 coefs3;
};


float4 get_sh1_of_direction(float3 direction)
{
	float p_1_1 = -0.488602511902919920;
	float4 coefs;
	coefs.x = 0.282094791773878140;
	coefs.y = p_1_1 * direction.y;
	coefs.z = 0.488602511902919920 * direction.z;
	coefs.w = p_1_1 * direction.x;
	
	return coefs;
}

static const float PI = 3.14159265359;
static const int TOTAL_SAMPLE_COUNT = 256;
static const float INV_DIMENSION = (1.0f / (float)TOTAL_SAMPLE_COUNT);
static const int SAMPLER_PER_THREAD_PER_AXIS = 32;
static const int THREAD_COUNT_PER_AXIS = TOTAL_SAMPLE_COUNT / SAMPLER_PER_THREAD_PER_AXIS;
static const float FINAL_MULTIPLIER = (2.0f * PI / (float)(TOTAL_SAMPLE_COUNT * TOTAL_SAMPLE_COUNT));

groupshared SH_coefs colors_of_rows[THREAD_COUNT_PER_AXIS * THREAD_COUNT_PER_AXIS];
groupshared SH_coefs results1[THREAD_COUNT_PER_AXIS];

float sinc(float x) 
{               
	/* Supporting sinc function */
	if (abs(x) < 1.0e-4)
	{
		return 1.0;
	}
	else 
	{
		return(sin(x)/x) ;
	}
}


[numthreads(THREAD_COUNT_PER_AXIS, THREAD_COUNT_PER_AXIS, 1)]
void main_cs(uint3 globalIdx : SV_DispatchThreadID, uint3 localIdx : SV_GroupThreadID, uint3 groupIdx : SV_GroupID)
{	
	SH_coefs accumulated_color = (SH_coefs)0;

	[loop]
	for(int i = 0 ; i < SAMPLER_PER_THREAD_PER_AXIS; i++)
	{
		[loop]
		for(int j = 0 ; j < SAMPLER_PER_THREAD_PER_AXIS; j++)
		{
			uint height_id = localIdx.x * SAMPLER_PER_THREAD_PER_AXIS + i;
			uint width_id = localIdx.y * SAMPLER_PER_THREAD_PER_AXIS + j;
			
			float dx = (width_id * INV_DIMENSION) + INV_DIMENSION * 0.5f;
			float dy = (height_id * INV_DIMENSION) + INV_DIMENSION * 0.5f;
			
			float theta = acos(sqrt(1 - dx)); //vertical 90* rotation vector
			float phi = 2 * PI * dy;				//horizontal 360* rotation vector
		
			float right_vector = sin(theta)*cos(phi);
			float forward_vector = sin(theta)*sin(phi);
			float up_vector = cos(theta);
	
			float3 current_direction = normalize(float3(right_vector , forward_vector , up_vector));

			float3 color = cubemap.SampleLevel(linear_sampler, current_direction.xzy, 0).rgb / g_postfx_target_exposure;
			float4 sh_coefs = get_sh1_of_direction(current_direction);

			accumulated_color.coefs0 += color * sh_coefs.x;
			accumulated_color.coefs1 += color * sh_coefs.y;
			accumulated_color.coefs2 += color * sh_coefs.z;
			accumulated_color.coefs3 += color * sh_coefs.w;
		}
	}
	
	colors_of_rows[ localIdx.y *  THREAD_COUNT_PER_AXIS + localIdx.x ] = accumulated_color;
	
	GroupMemoryBarrierWithGroupSync();

	// now sum the results of each elements in rows
	accumulated_color = (SH_coefs)0;
	
	if(localIdx.x == 0)
	{
		//sum columns
		[loop]
		for(int i = 0 ; i < THREAD_COUNT_PER_AXIS; i++)
		{
			int current_index = i + THREAD_COUNT_PER_AXIS * localIdx.y;
			accumulated_color.coefs0 += colors_of_rows[current_index].coefs0;
			accumulated_color.coefs1 += colors_of_rows[current_index].coefs1;
			accumulated_color.coefs2 += colors_of_rows[current_index].coefs2;
			accumulated_color.coefs3 += colors_of_rows[current_index].coefs3;
		}
		
		results1[ localIdx.y ] = accumulated_color;
	}

	GroupMemoryBarrierWithGroupSync();
	
	// now sum the results of each faces
	accumulated_color = (SH_coefs)0;
	
	if(localIdx.x == 0 && localIdx.y == 0)
	{
		//sum faces
		for(int i = 0 ; i < THREAD_COUNT_PER_AXIS; i++)
		{
			int current_index = i;
			accumulated_color.coefs0 += results1[current_index].coefs0;
			accumulated_color.coefs1 += results1[current_index].coefs1;
			accumulated_color.coefs2 += results1[current_index].coefs2;
			accumulated_color.coefs3 += results1[current_index].coefs3;
		}
		
		output[0] = float4(accumulated_color.coefs0 * FINAL_MULTIPLIER,0);
		output[1] = float4(accumulated_color.coefs1 * FINAL_MULTIPLIER,0);
		output[2] = float4(accumulated_color.coefs2 * FINAL_MULTIPLIER,0);
		output[3] = float4(accumulated_color.coefs3 * FINAL_MULTIPLIER,0);		
	}
}    
