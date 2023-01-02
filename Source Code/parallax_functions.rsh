#ifndef PARALLAX_FUNCTIONS_RSH
#define PARALLAX_FUNCTIONS_RSH

#include "modular_struct_definitions.rsh"

//---------------------------------------------------------------------------------//
// Parallax occlusion mapping algorithm implementation. Pixel shader.
//
// NOTE: Since we want to make convenient ways to turn features rendering on and
//       off (for example, for turning on / off visualization of current level of
//       details, shadows, etc), the shader presented here is less efficient than
//       it would in a real game scenario.
//---------------------------------------------------------------------------------//

#if (my_material_id == MATERIAL_ID_TERRAIN) || USE_PARALLAXMAPPING

float2 apply_pom(
	Texture2D heightmap,
	float2 i_texCoord,
	float2 i_vParallaxOffsetTS, float3 i_vViewWS,
	float3 i_vNormalWS, float3 i_vLightTS, out float shadow, int terrain_layer_index,
	float4 dfx, float4 dfy, float direction_coef, float fHeightMapRange,
	float min_sample_count, float max_sample_count, out float parallaxed_depth, inout Per_pixel_modifiable_variables pp_modifiable, float parallax_offset, float fParallaxLength)
{
	const int   nLODThreshold = 7;
	//const float fShadowSoftening = 1.58f * g_debug_vector.x;

	// Adaptive in-shader level-of-detail system implementation. Compute the
	// current mip level explicitly in the pixel shader and use this information
	// to transition between different levels of detail from the full effect to
	// simple bump mapping. See the above paper for more discussion of the approach
	// and its benefits.

	// Compute all 4 derivatives in x and y in a single instruction to optimize:
	float2 dxSize, dySize;
	float2 dx, dy;

	dxSize = dfx.xy;
	dx = dfx.zw;

	dySize = dfy.xy;
	dy = dfy.zw;

	float  fMipLevel;
	float  fMipLevelInt;    // mip level integer portion
	float  fMipLevelFrac;   // mip level fractional amount for blending in between levels

	float  fMinTexCoordDelta;
	float2 dTexCoords;

	// Find min of change in u and v across quad: compute du and dv magnitude across quad
	dTexCoords = dxSize * dxSize + dySize * dySize;

	// Standard mipmapping uses max here
	fMinTexCoordDelta = max(dTexCoords.x, dTexCoords.y);

	// Compute the current mip level  (* 0.5 is effectively computing a square root before )
	fMipLevel = max(0.5 * log2(fMinTexCoordDelta), 0);

	// Start the current sample located at the input texture coordinate, which would correspond
	// to computing a bump mapping result:
	float2 absolute_fractional_texcoord = i_texCoord + i_vParallaxOffsetTS * parallax_offset;//abs(frac(i_texCoord));
	float2 texSample = absolute_fractional_texcoord;

	float cur_offset_height = parallax_offset;

	float fOcclusionShadow = 1.0f;

	if (fMipLevel <= float(nLODThreshold))
	{
		//===============================================//
		// Parallax occlusion mapping offset computation //
		//===============================================//

		// Utilize dynamic flow control to change the number of samples per ray
		// depending on the viewing angle for the surface. Oblique angles require
		// smaller step sizes to achieve more accurate precision for computing displacement.
		// We express the sampling rate as a linear function of the angle between
		// the geometric normal and the view direction ray:
		int nNumSteps = int(lerp(max_sample_count, min_sample_count, abs(dot(i_vViewWS, i_vNormalWS))));
		// Intersect the view ray with the height field profile along the direction of
		// the parallax offset ray (computed in the vertex shader. Note that the code is
		// designed specifically to take advantage of the dynamic flow control constructs
		// in HLSL and is very sensitive to specific syntax. When converting to other examples,
		// if still want to use dynamic flow control in the resulting assembly shader,
		// care must be applied.
		//
		// In the below steps we approximate the height field profile as piecewise linear
		// curve. We find the pair of endpoints between which the intersection between the
		// height field profile and the view ray is found and then compute line segment
		// intersection for the view ray and the line segment formed by the two endpoints.
		// This intersection is the displacement offset from the original texture coordinate.
		// See the above paper for more details about the process and derivation.
		//

		float fCurrHeight = 0.0;
		float fStepSize = 1.0 / float(nNumSteps);
		float fPrevHeight = 1.0;
		float fNextHeight = 0.0;

		int    nStepIndex = 0;
		bool   bCondition = true;

		float2 vTexOffsetPerStep = fStepSize * i_vParallaxOffsetTS;
		float2 vTexCurrentOffset = absolute_fractional_texcoord;
		float  fCurrentBound = 1.0;
		float  fParallaxAmount = 0.0;

		float2 pt1 = float2(0, 0);
		float2 pt2 = float2(0, 0);

		[loop]
		while (nStepIndex < nNumSteps)// && nStepIndex < max_sample_count )
		{
			vTexCurrentOffset -= vTexOffsetPerStep;

			//TODO_DX11: dx11 version!
			// Sample height map which in this case is stored in the alpha channel of the normal map:
			//fCurrHeight = tex2Dgrad( heightmap_sampler, vTexCurrentOffset, dx, dy ).a;
#if (my_material_id != MATERIAL_ID_TERRAIN)
			if (HAS_MATERIAL_FLAG(g_mf_separate_displacement_map))
			{
				fCurrHeight = sample_texture_grad(heightmap, linear_sampler, vTexCurrentOffset, dx, dy).r;
			}
			else
			{
				fCurrHeight = sample_texture_grad(normal_texture, linear_sampler, vTexCurrentOffset, dx, dy).a;
			}
#else
#ifndef USE_TERRAIN_GET_HEIGHT_FOR_PARALLAX
#error include parallax_functions after terrain_header_data.rsh pls
#endif
			fCurrHeight = get_terrain_displacement_texture(vTexCurrentOffset, terrain_layer_index, dx, dy).r;

#endif

			fCurrentBound -= fStepSize;

			//fCurrHeight = fCurrHeight - 0.5f;
			fCurrHeight = lerp(fCurrHeight, (1.0 - fCurrHeight), direction_coef);
			//fCurrHeight += 1.0 / 255.0;

			[branch]
			if (fCurrHeight > fCurrentBound)
			{
				pt1 = float2(fCurrentBound, fCurrHeight);
				pt2 = float2(fCurrentBound + fStepSize, fPrevHeight);

				break;
			}
			else
			{
				nStepIndex++;
				fPrevHeight = fCurrHeight;
			}
		}   // End of while ( nStepIndex < nNumSteps )

		float fDelta2 = pt2.x - pt2.y;
		float fDelta1 = pt1.x - pt1.y;

		float fDenominator = fDelta2 - fDelta1;
		float abs_fDenominator = abs(fDenominator);
		float final_denom = abs_fDenominator > 1e-6 ? fDenominator : 1e-6;
		fParallaxAmount = (pt1.x * fDelta2 - pt2.x * fDelta1) / final_denom;
		parallaxed_depth = (1.0 - fParallaxAmount);

		cur_offset_height -= (1.0 - fParallaxAmount);
		float2 vParallaxOffset = i_vParallaxOffsetTS * (1.0 - fParallaxAmount);

		// The computed texture offset for the displaced point on the pseudo-extruded surface:
		float2 texSampleBase = absolute_fractional_texcoord - vParallaxOffset;
		texSample = texSampleBase;

		// Lerp to bump mapping only if we are in between, transition section:

		if (fMipLevel > float((nLODThreshold - 1)))
		{
			// Lerp based on the fractional part:
			fMipLevelFrac = modf(fMipLevel, fMipLevelInt);

			// Lerp the texture coordinate from parallax occlusion mapped coordinate to bump mapping
			// smoothly based on the current mip level:
			texSample = lerp(texSampleBase, absolute_fractional_texcoord, fMipLevelFrac);

		}  // End of if ( fMipLevel > fThreshold - 1 )


		//if(g_debug_vector.x)
		{
			float2 vLightRayTS = i_vLightTS.xy * fHeightMapRange * 2;
			vLightRayTS = direction_coef ? -1 * vLightRayTS : vLightRayTS;

			float2 tex_coord_for_occlusion = texSampleBase;

			// Compute the soft blurry shadows taking into account self-occlusion for
			// features of the height field:
			float2 jitter = 0;//its soft enough

			float fShadowSoftening = 0.6;
			vLightRayTS = lerp(vLightRayTS, -vLightRayTS, direction_coef);

#if (my_material_id != MATERIAL_ID_TERRAIN)
			float sh0 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion, dx, dy).r);
			float shA = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.88, dx, dy).r - sh0 - 0.88 * 0.4) * 1 * fShadowSoftening;
			float sh9 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.77, dx, dy).r - sh0 - 0.77 * 0.4) * 2 * fShadowSoftening;
			float sh8 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.66, dx, dy).r - sh0 - 0.66 * 0.4) * 4 * fShadowSoftening;
			float sh7 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.55, dx, dy).r - sh0 - 0.55 * 0.4) * 6 * fShadowSoftening;
			float sh6 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.44, dx, dy).r - sh0 - 0.44 * 0.4) * 8 * fShadowSoftening;
			float sh5 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.33, dx, dy).r - sh0 - 0.33 * 0.4) * 10 * fShadowSoftening;
			float sh4 = (sample_texture_grad(heightmap, linear_sampler, jitter + tex_coord_for_occlusion + vLightRayTS * 0.22, dx, dy).r - sh0 - 0.22 * 0.4) * 12 * fShadowSoftening;
#else
			float sh0 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion, terrain_layer_index, dx, dy).r);
			float shA = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.88, terrain_layer_index, dx, dy).r - sh0 - 0.88 * 0.4) * 1 * fShadowSoftening;
			float sh9 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.77, terrain_layer_index, dx, dy).r - sh0 - 0.77 * 0.4) * 2 * fShadowSoftening;
			float sh8 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.66, terrain_layer_index, dx, dy).r - sh0 - 0.66 * 0.4) * 4 * fShadowSoftening;
			float sh7 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.55, terrain_layer_index, dx, dy).r - sh0 - 0.55 * 0.4) * 6 * fShadowSoftening;
			float sh6 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.44, terrain_layer_index, dx, dy).r - sh0 - 0.44 * 0.4) * 8 * fShadowSoftening;
			float sh5 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.33, terrain_layer_index, dx, dy).r - sh0 - 0.33 * 0.4) * 10 * fShadowSoftening;
			float sh4 = (get_terrain_displacement_texture(jitter + tex_coord_for_occlusion + vLightRayTS * 0.22, terrain_layer_index, dx, dy).r - sh0 - 0.22 * 0.4) * 12 * fShadowSoftening;
#endif

			// Compute the actual shadow strength:
			fOcclusionShadow = saturate(1 - max(max(max(max(max(max(shA, sh9), sh8), sh7), sh6), sh5), sh4));


			// The previous computation overbrightens the image, let's adjust for that:
			//fOcclusionShadow = saturate(fOcclusionShadow * 0.6 + 0.4);

		}   // End of if ( bAddShadows )

	}   // End of if ( fMipLevel <= (float) nLODThreshold )

	shadow = fOcclusionShadow;
#if PARALLAX_DEBUG_MODE
	if (direction_coef > 0)
	{
		if (cur_offset_height >= 1e-16)
		{
			pp_modifiable.albedo_color.rgb = float4(1, 0, 0, 1);
		}
		else
		{
			pp_modifiable.albedo_color.rgb = float4(1, 1, 1, 1);
		}
	}
	else
	{
		if (cur_offset_height >= 1e-16)
		{
			pp_modifiable.albedo_color.rgb = float4(1, 1, 1, 1);
		}
		else
		{
			pp_modifiable.albedo_color.rgb = float4(1, 0, 0, 1);
		}
	}

#endif

	//clip(texSample.xy);
	//clip(1 - texSample.xy);

	return texSample;
}

#endif


#if USE_PARALLAXMAPPING
float apply_parallax(Pixel_shader_input_type In, Texture2D heightmap, inout float2 tex_coord, float3 view_vector_unorm, float3x3 _TBN, float3 world_space_normal, out float parallaxed_depth, inout Per_pixel_modifiable_variables pp_modifiable)
{
	float shadow = 1;

	float3 view_direction_ts = mul(_TBN, view_vector_unorm);
	float _view_len = length(view_vector_unorm);

	float3 sun_direction_ts = mul(_TBN, g_sun_direction_inv);

#if defined(BASIC_PARALLAX)
	float scaled_offset = 0.12f * g_mesh_parallax_amount;
	float2 plxCoeffs = float2(scaled_offset, -0.5 * scaled_offset);

	float height;

	if (HAS_MATERIAL_FLAG(g_mf_separate_displacement_map))
	{
		height = sample_displacement_map_texture(tex_coord.xy);
	}
	else
	{
		height = sample_detail_normal_texture(tex_coord.xy).a;
	}
	float offset = height * plxCoeffs.x + plxCoeffs.y;
	tex_coord.xy += offset * normalize(view_direction_ts).xy; //view_direction.xy;
#else
#if (my_material_id != MATERIAL_ID_TERRAIN)
	float2 vTextureDims;
	if (HAS_MATERIAL_FLAG(g_mf_separate_displacement_map))
	{
		displacement_texture.GetDimensions(vTextureDims.x, vTextureDims.y);
	}
	else
	{
		normal_texture.GetDimensions(vTextureDims.x, vTextureDims.y);
	}
#else
#ifndef USE_TERRAIN_GET_HEIGHT_FOR_PARALLAX
#error include parallax_functions after terrain_header_data.rsh pls
#endif
	fCurrHeight = get_terrain_displacement_texture(vTexCurrentOffset, 0, dx, dy).r;
#endif

	float dist = _view_len;

	float2 fTexCoordsPerSize = tex_coord * vTextureDims;
	float4 dfx = rgl_ddx(float4(fTexCoordsPerSize.x, fTexCoordsPerSize.y, tex_coord.x, tex_coord.y));
	float4 dfy = rgl_ddy(float4(fTexCoordsPerSize.x, fTexCoordsPerSize.y, tex_coord.x, tex_coord.y));

	{
		float fHeightMapRange = 0.12f * g_mesh_parallax_amount;

		float3 dx = ddx(In.world_normal.xyz);
		float3 dy = ddy(In.world_normal.xyz);
		float depth = length(In.world_position - g_camera_position);
		float max_diff = max(dot(dx, dx), dot(dy, dy)) / depth;
		float curvature = pow(abs(1.0 - max_diff), 100000);
		fHeightMapRange *= saturate(curvature * 5).x;


		if (HAS_MATERIAL_FLAG(g_mf_use_vertex_color_green_modified_parallax))
		{
			fHeightMapRange *= In.vertex_color.g;
		}

		float2 vParallaxDirection = normalize(view_direction_ts.xy);

		// The length of this vector determines the furthest amount of displacement:
		float fLength = length(view_direction_ts);
		float fParallaxLength = sqrt(fLength * fLength - view_direction_ts.z * view_direction_ts.z) / (view_direction_ts.z + 0.00001);

		// Compute the actual reverse parallax displacement vector
		float2 parallax_offset_ts = vParallaxDirection * fParallaxLength * fHeightMapRange;

		float coef = step(0.0, -fHeightMapRange);
		tex_coord.xy = apply_pom(heightmap, tex_coord.xy, parallax_offset_ts, normalize(view_vector_unorm), world_space_normal, sun_direction_ts, shadow, 0, dfx, dfy, coef, fHeightMapRange, 8.0, 48.0, parallaxed_depth, pp_modifiable, g_parallax_offset, fParallaxLength);
	}
#endif

	return shadow;
}

#endif

float2 into_boundaries(float2 tex_coord, DecalParams decal_render_params)
{
	if (decal_render_params.decal_flags & rgl_decal_flag_is_road)
	{
		tex_coord.x += tex_coord.x < decal_render_params.d_atlas_uv_n.z ? decal_render_params.d_atlas_uv_n.x : (tex_coord.x > decal_render_params.d_atlas_uv_n.x + decal_render_params.d_atlas_uv_n.z ? -decal_render_params.d_atlas_uv_n.x : 0);
		if (decal_render_params.decal_flags & rgl_decal_flag_road_tile_side)
		{
			tex_coord.y += tex_coord.y < decal_render_params.d_atlas_uv_n.w ? decal_render_params.d_atlas_uv_n.y : (tex_coord.y > decal_render_params.d_atlas_uv_n.y + decal_render_params.d_atlas_uv_n.w ? -decal_render_params.d_atlas_uv_n.y : 0);
		}
	}

	return tex_coord;
}

float2 apply_pom_atlassed_decal(
	Texture2D heightmap,
	float2 i_texCoord,
	float2 i_vParallaxOffsetTS, float3 i_vViewWS,
	float3 i_vNormalWS, float3 i_vLightTS, out float shadow, int terrain_layer_index,
	float4 dfx, float4 dfy, float direction_coef, float fHeightMapRange,
	float min_sample_count, float max_sample_count, out float parallaxed_depth, inout Per_pixel_modifiable_variables pp_modifiable, DecalParams decal_render_params, float fParallaxLength = 1.0)
{
	const int nLODThreshold = decal_render_params.decal_flags & rgl_decal_flag_is_road ? 12 : 5;
	//const float fShadowSoftening = 1.58f * g_debug_vector.x;

	// Adaptive in-shader level-of-detail system implementation. Compute the
	// current mip level explicitly in the pixel shader and use this information
	// to transition between different levels of detail from the full effect to
	// simple bump mapping. See the above paper for more discussion of the approach
	// and its benefits.

	// Compute all 4 derivatives in x and y in a single instruction to optimize:
	float2 dxSize, dySize;
	float2 dx, dy;

	dxSize = dfx.xy;
	dx = dfx.zw;

	dySize = dfy.xy;
	dy = dfy.zw;

	float  fMipLevel;
	float  fMipLevelInt;    // mip level integer portion
	float  fMipLevelFrac;   // mip level fractional amount for blending in between levels

	float  fMinTexCoordDelta;
	float2 dTexCoords;

	// Find min of change in u and v across quad: compute du and dv magnitude across quad
	dTexCoords = dxSize * dxSize + dySize * dySize;

	// Standard mipmapping uses max here
	fMinTexCoordDelta = max(dTexCoords.x, dTexCoords.y);

	// Compute the current mip level  (* 0.5 is effectively computing a square root before )
	fMipLevel = max(0.5 * log2(fMinTexCoordDelta), 0);

	// Start the current sample located at the input texture coordinate, which would correspond
	// to computing a bump mapping result:
	float2 absolute_fractional_texcoord = i_texCoord;//abs(frac(i_texCoord));
	float2 texSample = absolute_fractional_texcoord;

	float fOcclusionShadow = 1.0f;

	if (fMipLevel <= float(nLODThreshold))
	{
		//===============================================//
		// Parallax occlusion mapping offset computation //
		//===============================================//

		// Utilize dynamic flow control to change the number of samples per ray
		// depending on the viewing angle for the surface. Oblique angles require
		// smaller step sizes to achieve more accurate precision for computing displacement.
		// We express the sampling rate as a linear function of the angle between
		// the geometric normal and the view direction ray:
		int nNumSteps = int(lerp(max_sample_count, min_sample_count, abs(dot(i_vViewWS, i_vNormalWS))));
		// Intersect the view ray with the height field profile along the direction of
		// the parallax offset ray (computed in the vertex shader. Note that the code is
		// designed specifically to take advantage of the dynamic flow control constructs
		// in HLSL and is very sensitive to specific syntax. When converting to other examples,
		// if still want to use dynamic flow control in the resulting assembly shader,
		// care must be applied.
		//
		// In the below steps we approximate the height field profile as piecewise linear
		// curve. We find the pair of endpoints between which the intersection between the
		// height field profile and the view ray is found and then compute line segment
		// intersection for the view ray and the line segment formed by the two endpoints.
		// This intersection is the displacement offset from the original texture coordinate.
		// See the above paper for more details about the process and derivation.
		//

		float fCurrHeight = 0.0;
		float fStepSize = 1.0 / float(nNumSteps);
		float fPrevHeight = 1.0;
		float fNextHeight = 0.0;

		int    nStepIndex = 0;
		bool   bCondition = true;

		float2 vTexOffsetPerStep = fStepSize * i_vParallaxOffsetTS;
		float2 vTexCurrentOffset = absolute_fractional_texcoord;
		float  fCurrentBound = 1.0;
		float  fParallaxAmount = 0.0;
		float decal_height_contribution = 0.0;

		float2 pt1 = float2(0, 0);
		float2 pt2 = float2(0, 0);

		[loop]
		while (nStepIndex < nNumSteps)// && nStepIndex < max_sample_count )
		{
			vTexCurrentOffset -= vTexOffsetPerStep;
			float2 vTexCurrentOffset2 = into_boundaries(vTexCurrentOffset, decal_render_params);

			//TODO_DX11: dx11 version!
			// Sample height map which in this case is stored in the alpha channel of the normal map:
			//fCurrHeight = tex2Dgrad( heightmap_sampler, vTexCurrentOffset, dx, dy ).a;
			fCurrHeight = sample_texture_grad(decal_atlas_texture, linear_sampler, vTexCurrentOffset2, dx, dy).a;

#if (my_material_id != MATERIAL_ID_TERRAIN)
#else

#ifndef USE_TERRAIN_GET_HEIGHT_FOR_PARALLAX
#error include parallax_functions after terrain_header_data.rsh pls
#endif			
			fCurrHeight = get_terrain_displacement_texture(vTexCurrentOffset2, terrain_layer_index, dx, dy).r;
#endif
			fCurrentBound -= fStepSize;

			fCurrHeight = lerp(fCurrHeight, (1.0 - fCurrHeight), direction_coef);
			//fCurrHeight += 1.0 / 255.0;

			[branch]
			if (fCurrHeight > fCurrentBound)
			{
				pt1 = float2(fCurrentBound, fCurrHeight);
				pt2 = float2(fCurrentBound + fStepSize, fPrevHeight);

				break;
			}
			else
			{
				nStepIndex++;
				fPrevHeight = fCurrHeight;
			}
		}   // End of while ( nStepIndex < nNumSteps )

		float fDelta2 = pt2.x - pt2.y;
		float fDelta1 = pt1.x - pt1.y;

		float fDenominator = fDelta2 - fDelta1;
		float abs_fDenominator = abs(fDenominator);
		float final_denom = abs_fDenominator > 1e-6 ? fDenominator : 1e-6;
		fParallaxAmount = (pt1.x * fDelta2 - pt2.x * fDelta1) / final_denom;
		parallaxed_depth = (1.0 - fParallaxAmount);

		float2 vParallaxOffset = i_vParallaxOffsetTS * (1.0 - fParallaxAmount);

		// The computed texture offset for the displaced point on the pseudo-extruded surface:
		float2 texSampleBase = into_boundaries(absolute_fractional_texcoord - vParallaxOffset, decal_render_params);
		texSample = texSampleBase;

		// Lerp to bump mapping only if we are in between, transition section:

		if (fMipLevel > float((nLODThreshold - 1)))
		{
			// Lerp based on the fractional part:
			fMipLevelFrac = modf(fMipLevel, fMipLevelInt);

			// Lerp the texture coordinate from parallax occlusion mapped coordinate to bump mapping
			// smoothly based on the current mip level:
			texSample = lerp(texSampleBase, absolute_fractional_texcoord, fMipLevelFrac);

		}  // End of if ( fMipLevel > fThreshold - 1 )


		{
			float2 vLightRayTS = i_vLightTS.xy * fHeightMapRange * 2;

			float2 tex_coord_for_occlusion = texSampleBase;

			// Compute the soft blurry shadows taking into account self-occlusion for
			// features of the height field:
			float2 jitter = 1;// noise(tex_coord_for_occlusion * 80 * 32).rr * g_debug_vector.x / 2048.0;

			float fShadowSoftening = 0.6;
			float sh0 = (sample_texture_grad(heightmap, linear_sampler, tex_coord_for_occlusion, dx, dy).a);
			float shA = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.88, decal_render_params), dx, dy).a - sh0 - 0.88) * 1 * fShadowSoftening;
			float sh9 = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.77, decal_render_params), dx, dy).a - sh0 - 0.77) * 2 * fShadowSoftening;
			float sh8 = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.66, decal_render_params), dx, dy).a - sh0 - 0.66) * 4 * fShadowSoftening;
			float sh7 = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.55, decal_render_params), dx, dy).a - sh0 - 0.55) * 6 * fShadowSoftening;
			float sh6 = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.44, decal_render_params), dx, dy).a - sh0 - 0.44) * 8 * fShadowSoftening;
			float sh5 = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.33, decal_render_params), dx, dy).a - sh0 - 0.33) * 10 * fShadowSoftening;
			float sh4 = (sample_texture_grad(heightmap, linear_sampler, into_boundaries(tex_coord_for_occlusion + vLightRayTS * 0.22, decal_render_params), dx, dy).a - sh0 - 0.22) * 12 * fShadowSoftening;

			// Compute the actual shadow strength:
			fOcclusionShadow = 1 - max(max(max(max(max(max(shA, sh9), sh8), sh7), sh6), sh5), sh4);

			// The previous computation overbrightens the image, let's adjust for that:
			fOcclusionShadow = saturate(fOcclusionShadow * 0.6 + 0.4);

		}   // End of if ( bAddShadows )

	}   // End of if ( fMipLevel <= (float) nLODThreshold )

	shadow = fOcclusionShadow;

	//clip(texSample.xy);
	//clip(1 - texSample.xy);

	return texSample;
}

float apply_parallax_w_atlassed_texture(Pixel_shader_input_type In, Texture2D heightmap, inout float2 tex_coord, float3 view_vector_unorm, float3x3 _TBN, float3 world_space_normal, out float parallaxed_depth, inout Per_pixel_modifiable_variables pp_modifiable, float2 tex_dim, DecalParams decal_render_params, float4 dfx, float4 dfy)
{
	float shadow = 1;

	float2 vTextureDims = tex_dim;
	float3 view_direction_ts = mul(_TBN, view_vector_unorm);
	float _view_len = length(view_vector_unorm);

	float3 sun_direction_ts = mul(_TBN, g_sun_direction_inv);

	float dist = _view_len;

	float fHeightMapRange = 0.12 * 0.12f * decal_render_params.parallax_amount;

	if (HAS_MATERIAL_FLAG(g_mf_use_vertex_color_green_modified_parallax))
	{
		//fHeightMapRange *= In.vertex_color.g;
	}

	float2 vParallaxDirection = normalize(view_direction_ts.xy);
	vParallaxDirection.x *= vTextureDims.y / vTextureDims.x;

	// The length of this vector determines the furthest amount of displacement:
	float fLength = length(view_direction_ts);
	float fParallaxLength = sqrt(fLength * fLength - view_direction_ts.z * view_direction_ts.z) / view_direction_ts.z;

	// Compute the actual reverse parallax displacement vector
	float2 parallax_offset_ts = vParallaxDirection * fParallaxLength * fHeightMapRange;

	float minSample = (decal_render_params.decal_flags & rgl_decal_flag_is_road ? 16 : 8) / decal_render_params.mip_level;
	float maxSample = (decal_render_params.decal_flags & rgl_decal_flag_is_road ? 48 : 24) / decal_render_params.mip_level;

	float coef = step(0.0, -fHeightMapRange);
	tex_coord.xy = apply_pom_atlassed_decal(heightmap, tex_coord.xy, parallax_offset_ts, normalize(view_vector_unorm), world_space_normal, sun_direction_ts, shadow, 0, dfx, dfy, coef, fHeightMapRange, minSample, maxSample, parallaxed_depth, pp_modifiable, decal_render_params, fParallaxLength);

	return shadow;
}

#endif
