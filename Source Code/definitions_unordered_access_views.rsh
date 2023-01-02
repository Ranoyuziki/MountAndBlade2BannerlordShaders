#ifndef DEFINITIONS_UNORDERED_ACCESS_VIEWS_RSH
#define DEFINITIONS_UNORDERED_ACCESS_VIEWS_RSH

#include "definitions_shader_resource_indices.rsh"

#if defined(USE_DIRECTX11) || defined(USE_GNM)

RWTexture2D<uint> lockUAV : register(u_custom_0);
RWTexture2D<uint> overdrawUAV : register(u_custom_1);
RWTexture2D<uint> liveCountUAV : register(u_custom_2);
RWBuffer<uint> liveStatsUAV : register(u_custom_3);

#elif defined(USE_DIRECTX12) 

RWTexture2D<uint> RWTexture2D_uint_table[] : register(u1, space0);
RWTexture2D<float> RWTexture2D_float_table[] : register(u1, space1);
RWTexture2D<float3> RWTexture2D_float3_table[] : register(u1, space2);
RWTexture2D<float4> RWTexture2D_float4_table[] : register(u1, space3);
RWBuffer<uint> RWBuffer_uint_table[] : register(u1, space4);
RWBuffer<float> RWBuffer_float_table[] : register(u1, space5);
RWBuffer<float4> RWBuffer_float4_table[] : register(u1, space6);
AppendStructuredBuffer<BokehPoint> AppendStructuredBuffer_BokehPoint_table[] : register(u1, space7);
RWStructuredBuffer<float2> RWStructuredBuffer_float2_table[] : register(u1, space8);
RWStructuredBuffer<float> RWStructuredBuffer_float_table[] : register(u1, space9);
RWTexture2D<uint2> RWTexture2D_uint2_table[] : register(u1, space10);
RWTexture2DArray<float4> RWTexture2DArray_float4_table[] : register(u1, space11);
RWTexture2D<min16float4> RWTexture2D_half4_table[] : register(u1, space12);

#endif

#endif
