
#include "../shader_configuration.h"

#include "definitions.rsh"
#include "ui_shaders.rsh"

#if VERTEX_SHADER
VS_OUTPUT_FONT main_vs(RGL_VS_INPUT In)
{
	return vs_font(In);
}
#endif

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_FONT In)
{
	PS_OUTPUT outputData;
	outputData =  main_ps_no_shadow(In);
	
	float desaturation_level = g_mesh_vector_argument.x;
	if (desaturation_level > 0.4)
	{
		if(desaturation_level < 0.6)
		{	
			//make availiable perks which player haven't yet darker 
			outputData.RGBColor.rgb *= 0.45f;
		}
		else
		{
			//make unavailiable perks grayscale & darker
			float3 LUMINANCE_WEIGHTS = float3(0.299f, 0.587f, 0.114f);
			float luminance = dot(outputData.RGBColor.rgb, LUMINANCE_WEIGHTS);
			outputData.RGBColor.rgb = lerp(outputData.RGBColor.rgb, luminance, desaturation_level);
			
			outputData.RGBColor.rgb *= 0.3f;
		}
	}
	
	return outputData;
}
#endif
