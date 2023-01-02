         
#include "deferred_decal.rsh"

VS_OUTPUT_DEFERRED_DECAL main_vs(RGL_VS_INPUT In)
{
	return deferred_decal_vs(In); 
	 
}         
           
PS_OUTPUT main_ps(VS_OUTPUT_DEFERRED_DECAL In)        
{                                      
	return deferred_decal_ps(In);                        
}                                                                                                                                             
