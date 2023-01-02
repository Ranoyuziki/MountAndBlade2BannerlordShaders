#define	GRA_HLSL_5	1
#define	SampleLevel	SampleLOD
#define	SampleGrad	SampleGradient
#define	CalculateLevelOfDetail	GetLOD
#define	RWTexture2D	RW_Texture2D
#define	Texture2DArray	Texture2D_Array
#define GRA_NO_UNORM
#define	static 

#include "GraniteShaderLib3_src.h"


#undef	GRA_HLSL_5
#undef	SampleLevel
#undef	SampleGrad
#undef	CalculateLevelOfDetail
#undef	RWTexture2D
#undef	Texture2DArray
#undef  GRA_NO_UNORM
#undef	static 