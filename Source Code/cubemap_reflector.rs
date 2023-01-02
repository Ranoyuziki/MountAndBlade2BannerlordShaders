
#define DecalDiffuseMap	texture7
#define DecalNormalMap	texture8
#define DecalSpecularMap	texture9

#ifndef Vertex_shader_output_type
#define Vertex_shader_output_type VS_OUTPUT_REFLECTOR
#endif

#include "definitions.rsh"
#include "shared_functions.rsh"


//======================================================================================
// Vertex Shader
//======================================================================================

struct VS_OUTPUT_REFLECTOR
{
	float4 position					: RGL_POSITION	;	
	float3 world_normal				: TEXCOORD0		;
	float3 world_position			: TEXCOORD1		;
#ifdef ANISOTROPIC_ENVMAP_DEBUG
	float3 world_binormal			: TEXCOORD2		;
	float3 world_tangent			: TEXCOORD3		;
#endif
};



#if VERTEX_SHADER
VS_OUTPUT_REFLECTOR main_vs(RGL_VS_INPUT input)
{
    VS_OUTPUT_REFLECTOR output;

	float4 object_position, object_tangent;
	float3 object_normal, object_binormal, prev_object_position,object_color;
	
	rgl_vertex_transform_with_binormal(input, object_position, object_normal, object_tangent, object_binormal, prev_object_position, object_color);

	output.world_normal = mul((float3x3)g_world, object_normal);
	output.world_position = mul(g_world, float4(object_position.xyz,1)).xyz;
	output.position = mul(g_view_proj, float4(output.world_position.xyz, 1));

#ifdef ANISOTROPIC_ENVMAP_DEBUG
	output.world_binormal = mul((float3x3)g_world, object_binormal);
	output.world_tangent  = mul((float3x3)g_world, object_tangent);
#endif

	return output;
}
#endif

//======================================================================================
// Pixel Shader
//======================================================================================

#if PIXEL_SHADER
PS_OUTPUT main_ps(VS_OUTPUT_REFLECTOR input)
{
	PS_OUTPUT Output;

#ifdef ANISOTROPIC_ENVMAP_DEBUG
	float3 _view_dir_unorm = normalize(g_camera_position.xyz - input.world_position.xyz);
	float3 anisotropicTangent = normalize(cross(-_view_dir_unorm, normalize(input.world_binormal.xyz)));
	float3 anisotropicNormal = normalize(cross(anisotropicTangent.xyz, normalize(input.world_binormal.xyz)));
	anisotropicNormal  = normalize(lerp(input.world_normal, anisotropicNormal, g_debug_vector.z));
	//float3 reflect_normal = _view_dir_unorm - 2 * dot(anisotropicNormal, _view_dir_unorm) * anisotropicNormal;

	anisotropicNormal = reflect(-_view_dir_unorm, anisotropicNormal);

	float4 out_col = sample_cubic_global_texture_level(float4(anisotropicNormal.xyz, 0)) / g_target_exposure;
#else
	float2 screen_space_position = input.position.xy * g_application_halfpixel_viewport_size_inv.zw;
	float3 view_vector = normalize(g_root_camera_position.xyz - input.world_position.xyz);

	float4 out_col = sample_custom_cubic_texture_level(float4(input.world_normal.xyz, g_debug_vector.y)) / g_target_exposure;

 	//float4 new_tex_coord = float4(input.world_normal, g_debug_vector.w);
 	//out_col.rgb = scatter_cubemap.SampleLevel(linear_sampler, input.world_normal.xzy, g_debug_vector.y).rgb;
#endif

	Output.RGBColor = out_col;
	Output.RGBColor.rgb = output_color(out_col.rgb);
	//DEBUG_OUTPUT(0.5,0.5,0.5,1);

    return Output;
}
#endif
