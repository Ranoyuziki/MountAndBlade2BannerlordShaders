
#include "deferred_blood_terrain.rsh"

VS_OUTPUT_DEFERRED_DECAL main_vs(RGL_VS_INPUT In)
{
	return deferred_blood_terrain_vs(In); 
	 
}         
           
PS_OUTPUT main_ps(VS_OUTPUT_DEFERRED_DECAL In)        
{                                        
	return deferred_blood_terrain_ps(In);                         
}                                                                                                                                             
