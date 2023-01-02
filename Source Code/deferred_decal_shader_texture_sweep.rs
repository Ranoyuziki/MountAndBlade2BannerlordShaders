#undef USE_TEXTURE_SWEEP
#define USE_TEXTURE_SWEEP 1
         
#include "deferred_decal.rsh"

VS_OUTPUT_DEFERRED_DECAL main_vs(RGL_VS_INPUT In)
{
	//return deferred_decal_vs(In); 
	VS_OUTPUT_DEFERRED_DECAL output = (VS_OUTPUT_DEFERRED_DECAL)0;
	return output;
	 
}         
           
PS_OUTPUT main_ps(VS_OUTPUT_DEFERRED_DECAL In)        
{         
	PS_OUTPUT output = (PS_OUTPUT)0;
	return output;                      
}                                                                                                                                             
