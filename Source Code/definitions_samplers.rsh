#ifndef DEFINITIONS_SAMPLERS_RSH
#define DEFINITIONS_SAMPLERS_RSH

#include "definitions_shader_resource_indices.rsh"
	
SamplerState point_sampler : register(s_point);
SamplerState point_clamp_sampler : register(s_point_clamp);
SamplerState linear_sampler : register(s_linear);
SamplerState linear_clamp_sampler : register(s_linear_clamp);
SamplerState linear_mirror_sampler : register(s_linear_mirror);
SamplerState anisotropic_sampler : register(s_anisotropic);
SamplerComparisonState compare_lequal_sampler : register(s_compare_lequal);
SamplerComparisonState compare_gequal_sampler : register(s_compare_gequal);
SamplerComparisonState compare_lequal_bordered_sampler : register(s_compare_lequal_bordered);

#endif // DEFINITIONS_SAMPLERS_RSH
