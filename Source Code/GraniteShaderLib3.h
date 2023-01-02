

/**
*	Graphine Granite Runtime Shader 3.0
*
*	Copyright (c) 2017 Graphine. All Rights Reserved
*
*	This shader library contains all shader functionality to sample
*	Granite tile sets. It should be included in the application-specific
*	shader code.
*
*	--------------
*	FUNCTION CALLS
*	--------------
*
*	To sample a layer from a tile set, first perform the lookup:
*
*		int Granite_Lookup[_UDIM](	in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord,
*									in GraniteTranslationTexture translationTable,
*									out GraniteLookupData graniteLookupData,
*									out gra_Float4 resolveResult);
*
*	It is now possible to sample from any layer in the tile set:
*
*		int Granite_Sample(	in GraniteConstantBuffers grCB,
*							in GraniteLookupData graniteLookupData,
*							in uint layer,
*							in GraniteCacheTexture cacheTexture,
*							out gra_Float4 result);
*
*
*	Depending on you resolve strategy, you will need to do the following
*
*		- Separate Resolver:
*
*			Calculate only the resolve output in the separate resolver pass:
*
*				gra_Float4	Granite_ResolverPixel[_UDIM](	in GraniteConstantBuffers grCB,
*															gra_Float2 inputTexCoord);
*
*			You can supply a dummy resolveResult parameter to the Granite_Lookup function when sampling.
*
*		- MRT Resolver:
*
*			Output the resolveResult parameter given by the Granite_Lookup function to the render target.
*
*		- RWTexture2D Resolver:
*
*			You can write the resolveResult parameter given by the Granite_Lookup function to a RWTexture as follows:
*
*			void Granite_DitherResolveOutput(	in gra_Float4 resolve,
*												in RWTexture2D<gra_Float4> resolveTexture,
*												in gra_Float2 screenPos,
*												in float alpha = 1.0f);
*
*			Don't forget to set GRA_RWTEXTURE2D_SCALE to the actual scale used!
*
*
*	To transform the texture coordinates when using atlassing use:
*
*	gra_Float4	Granite_Transform(	in GraniteStreamingTextureConstantBuffer grSTCB,
*									gra_Float2 inputTexCoord);
*
*	If you want to sample from a UDIM streaming texture use the Granite_Lookup_UDIM functions to perform the lookup.
*	If you want to sample with explicit derivatives, use the overloaded 'Lookup' and 'Resolve' functions that take additional ddX and ddY parameters.
*	If you want to sample with explicit level-of-detail, use the overloaded 'Lookup' and 'Resolve' functions that take an additional LOD parameter. Note that these take a special GraniteLodVTData parameter.
*	If you do not want to have texture wrapping of streaming textures when using atlassing, use the overloaded 'PreTransformed' Lookup functions. Call Granite_Transform (or transform the UVs at the CPU) yourself!
* If you want to sample a cube map, use the appropriate 'Lookup'' and 'Sample' functions.
* Pass in the complete texture coordinate ( NOT the fractional part of it) in order to avoid discontinuities!
*
*	---------------------
*	INTEGRATION CHECKLIST
*	---------------------
*
*	(1.) Define the following preprocessor directives to configure the shader:
*
*	define GRA_HLSL_3 1/0
*		Enable/disable HLSL 3 syntax
*		Default: disabled
*
*	define GRA_HLSL_4 1/0
*		Enable/disable HLSL 4 syntax
*		Default: disabled
*
*	define GRA_HLSL_5 1/0
*		Enable/disable HLSL 5 syntax
*		Default: disabled
*
*	define GRA_GLSL_120 1/0
*		Enable/disable GLSL version 1.2 syntax
*		Default: disabled
*
*	define GRA_GLSL_130 1/0
*		Enable/disable GLSL version 1.3 syntax
*		Default: disabled
*
*	define GRA_GLSL_330 1/0
*		Enable/disable GLSL version 3.2 syntax
*		Default: disabled
*
*	define GRA_VERTEX_SHADER 1/0
*		Define that we are compiling a vertex shader and limit the instruction set to valid instructions
*		Default: disabled
*
*	define GRA_PIXEL_SHADER 1/0
*		Define that we are compiling a pixel shader and limit the instruction set to valid instructions
*		Default: disabled
*
*	define GRA_HQ_CUBEMAPPING 1/0
*		Enable/disable high quality cubemapping
*		Default: disabled
*
*	define GRA_DEBUG 0
*		Enable/disable debug mode of shader. It recommended to set this to true when first integrating
*		Granite into your engine. It will catch some common mistakes with passing shader parameters etc.
*		Default: disabled
*
*	define GRA_DEBUG_TILES 1/0
*		Enable/disable visual debug output of tiles
*		Default: disabled
*
*	define GRA_BGRA 1/0
*		Enable shader output in BGRA format (else RGBA is used)
*		Default: disabled (rgba)
*
*	define GRA_ROW_MAJOR 1/0
*		Set row major or colum major order of arrays
*		Default: enabled (row major)
*
*	define GRA_64BIT_RESOLVER 1/0
*		Render the resolver pass to a 64bpp resolver instead of a 32 bit per pixel format.
*		Default: disabled
*
*	define GRA_RWTEXTURE2D_SCALE [1,16]
*		The scale we are resolving at in the RWTexture2D. Must match the resolveScale when creation the RWTexture2D resolver.
*		Default: 16
*
*	define GRA_DISABLE_TEX_LOAD 1/0
*		Prefer a texture sample over a texture load (Only has effect on shader models that support the texture load/fetch instruction)
*		Default: 0
*
*	define GRA_PACK_RESOLVE_OUTPUT 1/0
*		When enabled, pack the resolve output values. If disabled, you should pack the returned resolve value using Granite_PackTileId.
*		Use this when performing multiple VT samples and dithering the resolve output.
*		Default: 1
*
*	define GRA_TEXTURE_ARRAY_SUPPORT 1/0
*		Does the graphics API / shader model supports texture arrays ?
*		Default: 1 for shader models supporting texture arrays, else 0
*
*	(2.) Include the Shader library, "GraniteShaderLib.h"
*
*	(3.) Ensure a nearest-point sampler is passed for the translation texture,
*	     including the mipmap filter (e.g., D3DTEXF_POINT for D3D9, or
*		 NearestMipmapNearest for CG)
*
*/



#ifndef GRA_HLSL_3
#define GRA_HLSL_3 0
#endif

#ifndef GRA_HLSL_4
#define GRA_HLSL_4 0
#endif

#ifndef GRA_HLSL_5
#define GRA_HLSL_5 0
#endif

#ifndef GRA_GLSL_120
#define GRA_GLSL_120 0
#endif

#ifndef GRA_GLSL_130
#define GRA_GLSL_130 0
#endif

#ifndef GRA_GLSL_330
#define GRA_GLSL_330 0
#endif

#ifndef GRA_VERTEX_SHADER
#define GRA_VERTEX_SHADER 0
#endif

#ifndef GRA_PIXEL_SHADER
#define GRA_PIXEL_SHADER 0
#endif

#ifndef GRA_HQ_CUBEMAPPING
#define GRA_HQ_CUBEMAPPING 0
#endif

#ifndef GRA_DEBUG_TILES
#define GRA_DEBUG_TILES 0
#endif

#ifndef GRA_BGRA
#define GRA_BGRA 0
#endif

#ifndef GRA_ROW_MAJOR
#define GRA_ROW_MAJOR 1
#endif

#ifndef GRA_DEBUG
#define GRA_DEBUG 1
#endif

#ifndef GRA_64BIT_RESOLVER
#define GRA_64BIT_RESOLVER 0
#endif

#ifndef GRA_RWTEXTURE2D_SCALE
#define GRA_RWTEXTURE2D_SCALE 16
#endif

#ifndef GRA_DISABLE_TEX_LOAD
#define GRA_DISABLE_TEX_LOAD 0
#endif

#ifndef GRA_PACK_RESOLVE_OUTPUT
#define GRA_PACK_RESOLVE_OUTPUT 1
#endif

#ifndef GRA_FORCE_SM3
#define GRA_FORCE_SM3 0
#endif

// Temp workaround for PSSL's lack of unorm. Ideally there would be a whole seperate GRA_PSSL backend.
#ifdef GRA_NO_UNORM
	#define GRA_UNORM
#else	
	#define GRA_UNORM unorm
#endif

#ifndef GRA_TEXTURE_ARRAY_SUPPORT
	#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1) || (GRA_GLSL_330 == 1)
		#define GRA_TEXTURE_ARRAY_SUPPORT 1
	#else
		#define GRA_TEXTURE_ARRAY_SUPPORT 0
	#endif
#endif

#define GRA_HLSL_FAMILY ((GRA_HLSL_3 == 1) || (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1))
#define GRA_GLSL_FAMILY ((GRA_GLSL_120 == 1) || (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1))

#if GRA_HLSL_FAMILY
	#define gra_Float2 float2
	#define gra_Float3 float3
	#define gra_Float4 float4
	#define gra_Int3 int3
	#define gra_Float4x4 float4x4
	#define gra_Unroll [unroll]
	#define gra_Branch [branch]
#elif GRA_GLSL_FAMILY
	#if (GRA_VERTEX_SHADER == 0) && (GRA_PIXEL_SHADER ==0)
		#error GLSL requires knowledge of the shader stage! Neither GRA_VERTEX_SHADER or GRA_PIXEL_SHADER are defined!
	#else
		#define gra_Float2 vec2
		#define gra_Float3 vec3
		#define gra_Float4 vec4
		#define gra_Int3 ivec3
		#define gra_Float4x4 mat4
		#define gra_Unroll
		#define gra_Branch
		#if (GRA_VERTEX_SHADER == 1)
			#define ddx
			#define ddy
		#elif (GRA_PIXEL_SHADER == 1)
			#define ddx dFdx
			#define ddy dFdy
		#endif
		#define frac fract
		#define lerp mix
		/** This is not correct (http://stackoverflow.com/questions/7610631/glsl-mod-vs-hlsl-fmod) but it is for our case */
		#define fmod mod
	#endif
#else
	#error unknown shader architecture
#endif

#if (GRA_DISABLE_TEX_LOAD!=1)
	#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1) || (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1)
		#define GRA_LOAD_INSTR 1
	#else
		#define GRA_LOAD_INSTR 0
	#endif
#else
	#define GRA_LOAD_INSTR 0
#endif





/**
	a cross API texture handle
*/
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
	struct GraniteTranslationTexture
	{
		SamplerState Sampler;
		Texture2D Texture;
	};
	struct GraniteCacheTexture
	{
		SamplerState Sampler;

		#if GRA_TEXTURE_ARRAY_SUPPORT
			Texture2DArray TextureArray;
		#else
			Texture2D Texture;
		#endif
	};
#elif (GRA_HLSL_3 == 1) || (GRA_GLSL_120 == 1) || (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1)
	#define GraniteTranslationTexture sampler2D
	
	#if GRA_TEXTURE_ARRAY_SUPPORT
		#define GraniteCacheTexture sampler2DArray
	#else
		#define GraniteCacheTexture sampler2D
	#endif
	
#else
	#error unknow shader archtecture
#endif

/**
		Struct defining the constant buffer for each streaming texture.
		Use IStreamingTexture::GetConstantBuffer to fill this struct.
*/
struct GraniteStreamingTextureConstantBuffer
{
	#define _grStreamingTextureCBSize 2
	gra_Float4 data[_grStreamingTextureCBSize];
};

/**
		Struct defining the constant buffer for each cube streaming texture.
		Use multiple calls to IStreamingTexture::GetConstantBuffer this struct (one call for each face).
	*/
struct GraniteStreamingTextureCubeConstantBuffer
{
	#define _grStreamingTextureCubeCBSize 6
	GraniteStreamingTextureConstantBuffer data[_grStreamingTextureCubeCBSize];
};

/**
		Struct defining the constant buffer for each tileset.
		Use ITileSet::GetConstantBuffer to fill this struct.
*/
struct GraniteTilesetConstantBuffer
{
	#define _grTilesetCBSize 2
	gra_Float4x4 data[_grTilesetCBSize];
};

/**
		Utility struct used by the shaderlib to wrap up all required constant buffers needed to perform a VT lookup/sample.
	*/
struct GraniteConstantBuffers
{
	GraniteTilesetConstantBuffer 						tilesetBuffer;
	GraniteStreamingTextureConstantBuffer 	streamingTextureBuffer;
};

/**
		Utility struct used by the shaderlib to wrap up all required constant buffers needed to perform a Cube VT lookup/sample.
	*/
struct GraniteCubeConstantBuffers
{
	GraniteTilesetConstantBuffer 								tilesetBuffer;
	GraniteStreamingTextureCubeConstantBuffer 	streamingTextureCubeBuffer;
};

/**
	The Granite lookup data for the different sampling functions.
*/

// Granite lookup data for automatic mip level selecting sampling
struct GraniteLookupData
{
	gra_Float4 translationTableData;
	gra_Float2 textureCoordinates;
	gra_Float2 dX;
	gra_Float2 dY;
};

// Granite lookup data for explicit level-of-detail sampling
struct GraniteLODLookupData
{
	gra_Float4 translationTableData;
	gra_Float2 textureCoordinates;
	float cacheLevel;
};



/**
	The public interface of all Granite related shader calls
*/

/**
*	Transform the texture coordinates from [0...1]x[0...1] texture space in [0...1]x[0...1] tile set space.
*
*	@param grSTCB The Granite Shader Runtime streaming texture parameter block
*	@param textureCoord The texture coord that will be transformed
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float2 Granite_Transform(in GraniteStreamingTextureConstantBuffer grSTCB, in gra_Float2 textureCoord);


/**
	Merge two resolve output values into one.
	This can be used when you need multiple tile sets on the same geometry ( != multiple layers from one tile set).
*/
gra_Float4 Granite_MergeResolveOutputs(in gra_Float4 resolve0, in gra_Float4 resolve1, in gra_Float2 pixelLocation);


/**
	Convert the 64bit created resolver to 32bit resolver data.
	This is useful when debugging 64bit resolver resources.
	Only use in debug mode !
*/
gra_Float4 Granite_DebugPackedTileId64(in gra_Float4 PackedTile);


/**
	Convert the packed normal data to a normalized three-dimensional normal.

	@param PackedNormal The normal data sampled by Granite_Sample

	@return The normalized three-dimensional normal.
*/
gra_Float3 Granite_UnpackNormal(in gra_Float4 packedNormal);

/**
	Convert the packed normal data to a normalized three-dimensional normal.

	@param PackedNormal The normal data sampled by Granite_Sample
	@param scale scale to apply to the normal during unpacking

	@return The normalized three-dimensional normal.
*/
gra_Float3 Granite_UnpackNormal(in gra_Float4 packedNormal, float scale);

#if GRA_HLSL_FAMILY
/**
	Applies an additional resolution offset to the parameter block.
	@param INtsCB The Granite Shader Runtime tile set parameter block
	@param resolutionOffsetPow2 The additional resolution offset calculated as follows: resolutionOffsetPow2 = 2^resolutionOffset.
	@return The Granite Shader Runtime tile set parameter block transformed with the additional resolution offset.
*/
GraniteTilesetConstantBuffer Granite_ApplyResolutionOffset(in GraniteTilesetConstantBuffer INtsCB, in float resolutionOffsetPow2);

/**
	Applies an user provided maximum anisotropy to the parameter block.
	@param INtsCB The Granite Shader Runtime tile set parameter block
	@param resolutionOffsetPow2 The new anisotropy calculated as follows: maxAnisotropyLog2 = log2(maxAnisotropy).
	@return The Granite Shader Runtime tile set parameter block transformed with the new maximum anisotropy.
*/
GraniteTilesetConstantBuffer Granite_SetMaxAnisotropy(in GraniteTilesetConstantBuffer INtsCB, in float maxAnisotropyLog2);
#else
/**
	Applies an additional resolution offset to the parameter block.

	@param INtsCB The Granite Shader Runtime tile set parameter block
	@param resolutionOffsetPow2 The additional resolution offset calculated as follows: resolutionOffsetPow2 = 2^resolutionOffset.
*/
void Granite_ApplyResolutionOffset(inout GraniteTilesetConstantBuffer tsCB, in float resolutionOffsetPow2);

/**
	Applies an user provided maximum anisotropy to the parameter block.

	@param tsCB The Granite Shader Runtime tile set parameter block
	@param resolutionOffsetPow2 The new anisotropy calculated as follows: maxAnisotropyLog2 = log2(maxAnisotropy).
*/
void Granite_SetMaxAnisotropy(inout GraniteTilesetConstantBuffer tsCB, in float maxAnisotropyLog2);
#endif
/**
	Pack the (unpacked) returned resolve output.
	Should only be used when GRA_PACK_RESOLVE_OUTPUT equals 0.

	@param paramBlock The Granite Shader Runtime parameter block
	@param unpackedTileID The TileID you wish to pack

	@return The packed tile ID
*/
gra_Float4 Granite_PackTileId(in gra_Float4 unpackedTileID);

#if (GRA_HLSL_5 == 1)
/**
	Pack the (unpacked) returned resolve output.
	Should only be used when GRA_PACK_RESOLVE_OUTPUT equals 0.

	@param resolve The resolve output
	@param resolveTexture RWTexture2D resource where the resolve output is written to
	@param screenPos The pixel coordinates of the pixel on the screen (SV_Position)
*/
void Granite_DitherResolveOutput(in gra_Float4 resolve, in RWTexture2D<GRA_UNORM gra_Float4> resolveTexture, in gra_Float2 screenPos, in float alpha /*= 1.0f*/);
#endif

/**
	Get the dimensions (in pixels) of a streaming texture

	@param grSTCB The Granite Shader Runtime streaming texture parameter block

	@return The streaming texture dimensions
*/
gra_Float2 Granite_GetTextureDimensions(in GraniteStreamingTextureConstantBuffer grSTCB);





/**
*	Virtual texture lookup of a pretransformed tile set
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Linear(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a tile set using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Linear(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a pretransformed tile set with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Linear(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);


/**
*	Virtual texture lookup of a tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Linear(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a tile set
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Linear(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Linear(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		in gra_Float3 ddX, in gra_Float3 ddY,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);






/**
*	Virtual texture lookup of a pretransformed UDIM tile set
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_UDIM_Linear(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a UDIM tile set using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_UDIM_Linear(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a pretransformed UDIM tile set with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_UDIM_Linear(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);


/**
*	Virtual texture lookup of a UDIM tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_UDIM_Linear(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a UDIM tile set
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_UDIM_Linear(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a UDIM tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_UDIM_Linear(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		in gra_Float3 ddX, in gra_Float3 ddY,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);






/**
*	Virtual texture lookup of a pretransformed Clamped tile set
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Clamp_Linear(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a Clamped tile set using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Clamp_Linear(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a pretransformed Clamped tile set with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Clamp_Linear(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);


/**
*	Virtual texture lookup of a Clamped tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Clamp_Linear(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a Clamped tile set
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Clamp_Linear(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a Clamped tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Clamp_Linear(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		in gra_Float3 ddX, in gra_Float3 ddY,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);






/**
*	Virtual texture lookup of a pretransformed tile set
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Anisotropic(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a tile set using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Anisotropic(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a pretransformed tile set with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Anisotropic(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);


/**
*	Virtual texture lookup of a tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Anisotropic(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a tile set
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Anisotropic(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Anisotropic(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		in gra_Float3 ddX, in gra_Float3 ddY,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);






/**
*	Virtual texture lookup of a pretransformed UDIM tile set
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_UDIM_Anisotropic(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a UDIM tile set using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_UDIM_Anisotropic(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a pretransformed UDIM tile set with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_UDIM_Anisotropic(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);


/**
*	Virtual texture lookup of a UDIM tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_UDIM_Anisotropic(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a UDIM tile set
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_UDIM_Anisotropic(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a UDIM tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_UDIM_Anisotropic(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		in gra_Float3 ddX, in gra_Float3 ddY,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);






/**
*	Virtual texture lookup of a pretransformed Clamped tile set
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Clamp_Anisotropic(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a Clamped tile set using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Clamp_Anisotropic(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a pretransformed Clamped tile set with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the pretransformed input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Clamp_Anisotropic(	in GraniteConstantBuffers grCB,
																							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																							out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);


/**
*	Virtual texture lookup of a Clamped tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Clamp_Anisotropic(	in GraniteConstantBuffers grCB,
																in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY,
																out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a Clamped tile set
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Clamp_Anisotropic(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a Clamped tile set with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Clamp_Anisotropic(	in GraniteCubeConstantBuffers grCB,
																		in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord,
																		in gra_Float3 ddX, in gra_Float3 ddY,
																		out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);






/**
*	Virtual texture lookup of a preTransformed tile set with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed(	in GraniteConstantBuffers grCB,
							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in float LOD,
							out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a tile set with explicit level-of-detail using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param transform The transform to apply. This can be got with [GetTransform](@ref Graphine::Granite::IStreamingTexture::GetTransform).
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup(	in GraniteConstantBuffers grCB,
							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in float LOD,
							out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a tile set with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube(	in GraniteCubeConstantBuffers grCB,
								in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord, in float LOD,
								out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);





/**
*	Virtual texture lookup of a preTransformed UDIM tile set with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_UDIM(	in GraniteConstantBuffers grCB,
							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in float LOD,
							out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a UDIM tile set with explicit level-of-detail using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param transform The transform to apply. This can be got with [GetTransform](@ref Graphine::Granite::IStreamingTexture::GetTransform).
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_UDIM(	in GraniteConstantBuffers grCB,
							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in float LOD,
							out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a UDIM tile set with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_UDIM(	in GraniteCubeConstantBuffers grCB,
								in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord, in float LOD,
								out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);





/**
*	Virtual texture lookup of a preTransformed Clamped tile set with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_PreTransformed_Clamp(	in GraniteConstantBuffers grCB,
							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in float LOD,
							out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a Clamped tile set with explicit level-of-detail using wrapped texture addressing (tiling)
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param transform The transform to apply. This can be got with [GetTransform](@ref Graphine::Granite::IStreamingTexture::GetTransform).
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Clamp(	in GraniteConstantBuffers grCB,
							in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord, in float LOD,
							out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup of a cubemap in a Clamped tile set with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param LOD Specifies the explicit level-of-detail
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Cube_Clamp(	in GraniteCubeConstantBuffers grCB,
								in GraniteTranslationTexture translationTable, in gra_Float3 inputTexCoord, in float LOD,
								out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);





/**
*	Virtual texture lookup using wrapped texture addressing (tiling) and dynamic udim selection
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param asUDIM Should we sample using UDIM or regular (tiled) adressing
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Dynamic_Linear(	in GraniteConstantBuffers grCB,
									in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
									in bool asUDIM,
									out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup using wrapped texture addressing (tiling) and dynamic udim selection
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param asUDIM Should we sample using UDIM or regular (tiled) adressing
*	@param LOD The Level of Detail to sample.
*	@param graniteLODLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/

int Granite_Lookup_Dynamic_Linear(	in GraniteConstantBuffers grCB,
									in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
									in bool asUDIM, in float LOD,
									out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);





/**
*	Virtual texture lookup using wrapped texture addressing (tiling) and dynamic udim selection
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param asUDIM Should we sample using UDIM or regular (tiled) adressing
*	@param graniteLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/
int Granite_Lookup_Dynamic_Anisotropic(	in GraniteConstantBuffers grCB,
									in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
									in bool asUDIM,
									out GraniteLookupData graniteLookupData, out gra_Float4 resolveResult);

/**
*	Virtual texture lookup using wrapped texture addressing (tiling) and dynamic udim selection
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param translationTable GraniteTranslationTexture object that contains the translation texture
*	@param inputTexCoord the input texture coordinates
*	@param asUDIM Should we sample using UDIM or regular (tiled) adressing
*	@param LOD The Level of Detail to sample.
*	@param graniteLODLookupData the Granite lookup data
*	@param resolveResult Resolve analysis output. Supply a dummy variable if you don't need it.
*
*	@return 1 in case sampling was successful.
*/

int Granite_Lookup_Dynamic_Anisotropic(	in GraniteConstantBuffers grCB,
									in GraniteTranslationTexture translationTable, in gra_Float2 inputTexCoord,
									in bool asUDIM, in float LOD,
									out GraniteLODLookupData graniteLookupData, out gra_Float4 resolveResult);





/**
*	Samples a single layer of a tile set.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param graniteLookupData The Granite Lookup data ((@ref Granite_Lookup)
*	@param cacheTexture The GraniteCacheTexture object of the cache texture of the tile set layer
*	@param layer The layer index in the tile set you want to sample from
*	@param result The sampled texel
*
*	@return 1 in case sampling was successful.
*/
int Granite_Sample(	in GraniteConstantBuffers grCB,
										in GraniteLookupData graniteLookupData,
										in GraniteCacheTexture cacheTexture, in int layer,
										out gra_Float4 result);

/**
*	Samples a single layer of a cube tile set.
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param graniteLookupData The Granite Lookup data ((@ref Granite_Lookup)
*	@param cacheTexture The GraniteCacheTexture object of the cache texture of the tile set layer
*	@param layer The layer index in the tile set you want to sample from
*	@param result The sampled texel
*
*	@return 1 in case sampling was successful.
*/
int Granite_Sample(	in GraniteCubeConstantBuffers grCB,
										in GraniteLookupData graniteLookupData,
										in GraniteCacheTexture cacheTexture, in int layer,
										out gra_Float4 result);

/**
*	Samples a single layer of a tile set with high quality filtering
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param graniteLookupData The Granite Lookup data ((@ref Granite_Lookup)
*	@param cacheTexture The GraniteCacheTexture object of the cache texture of the tile set layer
*	@param layer The layer index in the tile set you want to sample from
*	@param result The sampled texel
*
*	@return 1 in case sampling was successful.
*/
int Granite_Sample_HQ(	in GraniteConstantBuffers grCB,
												in GraniteLookupData graniteLookupData,
												in GraniteCacheTexture cacheTexture, in int layer,
												out gra_Float4 result);

/**
*	Samples a single layer of a cube tile set with high quality filtering
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param graniteLookupData The Granite Lookup data ((@ref Granite_Lookup)
*	@param cacheTexture The GraniteCacheTexture object of the cache texture of the tile set layer
*	@param layer The layer index in the tile set you want to sample from
*	@param result The sampled texel
*
*	@return 1 in case sampling was successful.
*/
int Granite_Sample_HQ(	in GraniteCubeConstantBuffers grCB,
												in GraniteLookupData graniteLookupData,
												in GraniteCacheTexture cacheTexture, in int layer,
												out gra_Float4 result);

/**
*	Samples a single layer of a tile set with explicit level-of-detail.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param graniteLookupData The Granite lookup data ((@ref Granite_Lookup)
*	@param cacheTexture The GraniteCacheTexture object of the cache texture of the tile set layer
*	@param layer The layer index in the tile set you want to sample from
*	@param result The sampled texel
*
*	@return 1 in case sampling was successful.
*/
int Granite_Sample(	in GraniteConstantBuffers grCB,
										in GraniteLODLookupData graniteLookupData,
										in GraniteCacheTexture cacheTexture, in int layer,
										out gra_Float4 result);

/**
*	Samples a single layer of a cube tile set with explicit level-of-detail.
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param graniteLookupData The Granite lookup data ((@ref Granite_Lookup)
*	@param cacheTexture The GraniteCacheTexture object of the cache texture of the tile set layer
*	@param layer The layer index in the tile set you want to sample from
*	@param result The sampled texel
*
*	@return 1 in case sampling was successful.
*/
int Granite_Sample(	in GraniteCubeConstantBuffers grCB,
										in GraniteLODLookupData graniteLookupData,
										in GraniteCacheTexture cacheTexture, in int layer,
										out gra_Float4 result);





/**
*	Calculate the pretransformed resolver output
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return The packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the pretransformed resolver output with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);

/**
*	Calculate the resolver output using wrapping texture addressing
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);


/**
*	Calculate the resolver output of a cubemap
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Linear(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord);

/**
*	Calculate the resolver output of a cubemap with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Linear(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in gra_Float3 ddX, in gra_Float3 ddY);






/**
*	Calculate the pretransformed resolver output
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return The packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_UDIM_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the pretransformed resolver output with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_UDIM_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);

/**
*	Calculate the resolver output using wrapping texture addressing
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_UDIM_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_UDIM_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);


/**
*	Calculate the resolver output of a cubemap
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_UDIM_Linear(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord);

/**
*	Calculate the resolver output of a cubemap with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_UDIM_Linear(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in gra_Float3 ddX, in gra_Float3 ddY);






/**
*	Calculate the pretransformed resolver output
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return The packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Clamp_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the pretransformed resolver output with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Clamp_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);

/**
*	Calculate the resolver output using wrapping texture addressing
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Clamp_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Clamp_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);


/**
*	Calculate the resolver output of a cubemap
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Clamp_Linear(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord);

/**
*	Calculate the resolver output of a cubemap with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Clamp_Linear(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in gra_Float3 ddX, in gra_Float3 ddY);






/**
*	Calculate the pretransformed resolver output
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return The packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the pretransformed resolver output with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);

/**
*	Calculate the resolver output using wrapping texture addressing
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);


/**
*	Calculate the resolver output of a cubemap
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Anisotropic(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord);

/**
*	Calculate the resolver output of a cubemap with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Anisotropic(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in gra_Float3 ddX, in gra_Float3 ddY);






/**
*	Calculate the pretransformed resolver output
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return The packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_UDIM_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the pretransformed resolver output with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_UDIM_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);

/**
*	Calculate the resolver output using wrapping texture addressing
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_UDIM_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_UDIM_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);


/**
*	Calculate the resolver output of a cubemap
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_UDIM_Anisotropic(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord);

/**
*	Calculate the resolver output of a cubemap with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_UDIM_Anisotropic(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in gra_Float3 ddX, in gra_Float3 ddY);






/**
*	Calculate the pretransformed resolver output
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return The packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Clamp_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the pretransformed resolver output with explicit derivatives
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Clamp_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);

/**
*	Calculate the resolver output using wrapping texture addressing
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Clamp_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit derivatives
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Clamp_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in gra_Float2 ddX, in gra_Float2 ddY);


/**
*	Calculate the resolver output of a cubemap
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Clamp_Anisotropic(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord);

/**
*	Calculate the resolver output of a cubemap with explicit derivatives
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param ddX Specifies the explicit partial derivative with respect to X
*	@param ddY Specifies the explicit partial derivative with respect to Y
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Clamp_Anisotropic(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in gra_Float3 ddX, in gra_Float3 ddY);






/**
*	Calculate the pretransformed resolver output with explicit level-of-detail
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in float LOD);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@param transform The transform to apply. This can be got with [GetTransform](@ref Graphine::Granite::IStreamingTexture::GetTransform).
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in float LOD);

/**
*	Calculate the resolver output of a cubemap with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in float LOD);





/**
*	Calculate the pretransformed resolver output with explicit level-of-detail
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_UDIM(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in float LOD);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@param transform The transform to apply. This can be got with [GetTransform](@ref Graphine::Granite::IStreamingTexture::GetTransform).
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_UDIM(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in float LOD);

/**
*	Calculate the resolver output of a cubemap with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_UDIM(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in float LOD);





/**
*	Calculate the pretransformed resolver output with explicit level-of-detail
* Caller needs to either already called Granite_Transform in the shader or used [TransformTextureCoordinates](@ref Graphine::Granite::IStreamingTexture::TransformTextureCoordinates) on the vertex data.
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_PreTransformed_Clamp(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in float LOD);

/**
*	Calculate the resolver output using wrapping texture addressing with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@param transform The transform to apply. This can be got with [GetTransform](@ref Graphine::Granite::IStreamingTexture::GetTransform).
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Clamp(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in float LOD);

/**
*	Calculate the resolver output of a cubemap with explicit level-of-detail
*
*	@param grCB the Granite Shader Runtime Cube parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param LOD Specifies the explicit level-of-detail
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Cube_Clamp(in GraniteCubeConstantBuffers grCB, in gra_Float3 inputTexCoord, in float LOD);





/**
*	Calculate the resolver output using wrapping texture addressing with dynamic UDIM selection
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param asUDIM Should we sample using UDIM or regular (tiled) adressing
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Dynamic_Linear(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in bool asUDIM);





/**
*	Calculate the resolver output using wrapping texture addressing with dynamic UDIM selection
*
*	@param grCB the Granite Shader Runtime parameter block
*	@param inputTexCoord The texture coordinate that will be used to sample the texture
*	@param asUDIM Should we sample using UDIM or regular (tiled) adressing
*	@return a gra_Float4 containing the packed tile id
*/
gra_Float4 Granite_ResolverPixel_Dynamic_Anisotropic(in GraniteConstantBuffers grCB, in gra_Float2 inputTexCoord, in bool asUDIM);



#define _135 floor
#define _136 frac
#define _137 fmod
#define _138 dot
#define _139 max
#define _140 min
#define _141 log2
#define _142 ddx
#define _143 ddy
#define _144 pow
#define _145 smoothstep
#define _146 sqrt
#define _147 saturate
#define _148 clamp
#define _149 float
#define _150 gra_Float2
#define _151 gra_Float3
#define _152 gra_Float4
#define _153 gra_Float4x4
#define _154 int
#define _155 int2
#define _156 uint2
#define _157 const
#define _158 bool
#define _159 if
#define _160 else
#define _161 for
#define _162 translationTable
#define _163 cacheTexture
#define _164 inputTexCoord
#define _165 tileXY
#define _166 resolveOutput
#define _167 result
#define _168 texCoord
#define _169 return
#define _170 paramBlock0
#define _171 paramBlock1
#define _172 class
#define _173 in
#define _174 out
#define _175 inout
#define _176 Texture
#define _177 TextureArray
#define _178 Sampler
#define _179 GraniteCacheTexture
#define _180 GraniteTranslationTexture
#define _181 GraniteLookupData
#define _182 GraniteLODLookupData
#define _183 RWTexture2D
#define _184 tex2Dlod
#define _185 tex2D
#define _186 tex2Dbias
#define _187 dX
#define _188 dY
#define _189 textureCoordinates
#define _190 translationTableData
#define _191 layer
#define _192 cacheLevel
#define _193 StreamingTextureConstantBuffer
#define _194 StreamingTextureCubeConstantBuffer
#define _195 TilesetConstantBuffer
#define _196 GraniteConstantBuffers
#define _197 GraniteCubeConstantBuffers

#define _115 _124.tilesetBuffer
#define _116  _125.data[0]
#define _117  _125.data[1]
#define _118 _124.streamingTextureBuffer
#define _119 _124.streamingTextureCubeBuffer
#define _120 _124.streamingTextureBuffer.data[0]
#define _121 _124.streamingTextureCubeBuffer.data
#define _122 _126.data[0]
#define _123 _126.data[1]
#define _17 _123.x
#define _133 _123.y
#define _134 _123.z
#if GRA_ROW_MAJOR == 1
#define _0 			_116[0][0]
#define _1 				_116[1][0]
#define _2 		_150(_116[2][0], _116[3][0])
#define _3 	_116[2][0]
#define _4 	_116[3][0]
#define _5								_116[0][1]
#define _18 				_150(_116[0][2], _116[1][2])
#define _10						_116[0][3]
#define _14						_116[1][3]
#define _11							_116[2][3]
#define _12 								_116[3][3]
#define _19(l)				_150(_117[0][l], _117[1][l])
#define _20(l)		_150(_117[2][l], _117[3][l])
#else
#define _0 			_116[0][0]
#define _1 				_116[0][1]
#define _2 		_150(_116[0][2], _116[0][3])
#define _3 	_116[0][2]
#define _4 	_116[0][3]
#define _5								_116[1][0]
#define _18 				_150(_116[2][0], _116[2][1])
#define _10						_116[3][0]
#define _14						_116[3][1]
#define _11							_116[3][2]
#define _12 								_116[3][3]
#define _19(l)				_150(_117[l][0], _117[l][1])
#define _20(l)		_150(_117[l][2], _117[l][3])
#endif
#if (GRA_GLSL_120==1)
#extension GL_ARB_shader_texture_lod : enable
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_bit_encoding : enable
#endif
#if (GRA_TEXTURE_ARRAY_SUPPORT==1)
_152 _99(_173 _179 _75, _173 _151 _168)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._177.Sample(_75._178,_168);
#elif (GRA_GLSL_330 == 1)
_169 texture(_75,_168);
#else
#error using unsupported function
#endif
}
_152 _101(_173 _179 _75, _173 _151 _168, _173 _150 _187, _173 _150 _188)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._177.SampleGrad(_75._178,_168,_187,_188);
#elif (GRA_GLSL_330 == 1)
_169 textureGrad(_75,_168,_187,_188);
#else
#error using unsupported function
#endif
}
_152 _100(_173 _179 _75, _173 _151 _168, _173 _149 _51)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._177.SampleLevel(_75._178,_168,_51);
#elif (GRA_GLSL_330 == 1)
_169 textureLod(_75,_168,_51);
#else
#error using unsupported function
#endif
}
#else
_152 _96(_173 _179 _75, _173 _150 _168)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._176.Sample(_75._178,_168);
#elif (GRA_HLSL_3 == 1)
_169 _185(_75,_168);
#elif (GRA_GLSL_120 == 1) || (GRA_GLSL_130 == 1)
_169 texture2D(_75,_168);
#elif (GRA_GLSL_330 == 1)
_169 texture(_75,_168);
#endif
}
_152 _97(_173 _179 _75, _173 _150 _168, _173 _149 _51)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._176.SampleLevel(_75._178,_168,_51);
#elif (GRA_HLSL_3 == 1)
_169 _184(_75,_152(_168,0.0,_51));
#elif (GRA_GLSL_120 == 1)
_169 texture2DLod(_75,_168,_51);
#elif (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1)
_169 textureLod(_75,_168,_51);
#endif
}
_152 _98(_173 _179 _75, _173 _150 _168, _173 _150 _187, _173 _150 _188)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._176.SampleGrad(_75._178,_168,_187,_188);
#elif (GRA_HLSL_3 == 1)
_169 _185(_75,_168,_187,_188);
#elif (GRA_GLSL_120 == 1)
_169 texture2DGrad(_75,_168,_187,_188);
#elif (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1)
_169 textureGrad(_75,_168,_187,_188);
#endif
}
#endif 
#if (GRA_LOAD_INSTR==1)
_152 _106(_173 _180 _75, _173 gra_Int3 location)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._176.Load(location);
#elif (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1)
_169 texelFetch(_75,location.xy,location.z);
#elif (GRA_HLSL_3 == 1) || (GRA_GLSL_120 == 1)
#error using unsupported function
#endif
}
#endif
_152 GranitePrivate_SampleLevel_Translation(_173 _180 _75, _173 _150 _168, _173 _149 _51)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 _75._176.SampleLevel(_75._178,_168,_51);
#elif (GRA_HLSL_3 == 1)
_169 _184(_75,_152(_168,0.0,_51));
#elif (GRA_GLSL_120 == 1)
_169 texture2DLod(_75,_168,_51);
#elif (GRA_GLSL_130 == 1) || (GRA_GLSL_330 == 1)
_169 textureLod(_75,_168,_51);
#endif
}
_149 _103(_173 _149 _79)
{
#if GRA_HLSL_FAMILY
_169 _147(_79);
#elif GRA_GLSL_FAMILY
_169 _148(_79,0.0f,1.0f);
#endif
}
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1) || (GRA_GLSL_330 == 1)
uint _107(_149 _79)
{
#if (GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1)
_169 asuint(_79);
#elif (GRA_GLSL_330 == 1)
_169 floatBitsToUint(_79);
#endif
}
#endif
_149 _108(_154 _114)
{
#if GRA_HLSL_FAMILY
_169 _144(2.0,_114);
#else
_169 _144(2.0,_149(_114));
#endif
}
_149 _108(uint _114)
{
#if GRA_HLSL_FAMILY
_169 _144(2.0,_114);
#else
_169 _144(2.0,_149(_114));
#endif
}
_150 _129(_173 _150 uv, _173 GraniteStreamingTextureConstantBuffer _126)
{_169 _136(uv);}
_150 _130(_173 _150 uv, _173 GraniteStreamingTextureConstantBuffer _126)
{_169 uv;}
_150 _131(_173 _150 uv, _173 GraniteStreamingTextureConstantBuffer _126)
{_150 epsilon2=_150(_133,_134);_169 _148(uv,epsilon2,_150(1,1)-epsilon2);}
_150 _132(_173 _150 uv, _173 GraniteStreamingTextureConstantBuffer _126)
{_150 t=_136(uv*0.5)*2.0;_150 l=_150(1.0,1.0);_169 l-abs(t-l);}
_152 _92(_173 _150 _165, _173 _149 _51, _173 _149 textureID);
_152 Granite_DebugPackedTileId64(_173 _152 PackedTile)
{
#if GRA_64BIT_RESOLVER
_152 _77;_157 _149 _76=1.0f/65535.0f;_152 _78=PackedTile/_76;_77.x=_137(_78.x,256.0f);_77.y=_135(_78.x/256.0f)+_137(_78.y,16.0f)*16.0f;_77.z=_135(_78.y/16.0f);_77.w=_78.z+_78.a*16.0f;_169 _152((_149)_77.x/255.0f,(_149)_77.y/255.0f,(_149)_77.z/255.0f,(_149)_77.w/255.0f);
#else
_169 PackedTile;
#endif
}
_151 Granite_UnpackNormal(_173 _152 PackedNormal, _149 _76)
{_150 reconstructed=_150(PackedNormal.x*PackedNormal.a,PackedNormal.y)*2.0f-1.0f;reconstructed*=_76;_149 z=_146(1.0f-_103(_138(reconstructed,reconstructed)));_169 _151(reconstructed,z);}
_151 Granite_UnpackNormal(_173 _152 PackedNormal)
{_169 Granite_UnpackNormal(PackedNormal,1.0);}
#if GRA_HLSL_FAMILY
GraniteTilesetConstantBuffer Granite_ApplyResolutionOffset(_173 GraniteTilesetConstantBuffer INtsCB, _173 _149 resolutionOffsetPow2)
{GraniteTilesetConstantBuffer _125=INtsCB;_5*=resolutionOffsetPow2;_3*=resolutionOffsetPow2;_4*=resolutionOffsetPow2;_169 _125;}
GraniteTilesetConstantBuffer Granite_SetMaxAnisotropy(_173 GraniteTilesetConstantBuffer INtsCB, _173 _149 maxAnisotropyLog2)
{GraniteTilesetConstantBuffer _125=INtsCB;_1=_140(_1,maxAnisotropyLog2);_169 _125;}
#else
void Granite_ApplyResolutionOffset(_175 GraniteTilesetConstantBuffer _125, _173 _149 resolutionOffsetPow2)
{_5*=resolutionOffsetPow2;_3*=resolutionOffsetPow2;_4*=resolutionOffsetPow2;}
void Granite_SetMaxAnisotropy(_175 GraniteTilesetConstantBuffer _125, _173 _149 maxAnisotropyLog2)
{_1=_140(_1,maxAnisotropyLog2);}
#endif
_150 Granite_Transform(_173 GraniteStreamingTextureConstantBuffer _126, _173 _150 _60)
{_169 _60*_122.zw+_122.xy;}
_152 Granite_MergeResolveOutputs(_173 _152 resolve0, _173 _152 resolve1, _173 _150 _63)
{_150 _64=_136(_63*0.5f);_158 _68=(_64.x !=_64.y);_169(_68)? resolve0 : resolve1;}
_152 Granite_PackTileId(_173 _152 unpackedTileID)
{_169 _92(unpackedTileID.xy,unpackedTileID.z,unpackedTileID.w);}
#if (GRA_HLSL_5 == 1)
void Granite_DitherResolveOutput(_173 _152 resolve, _173 _183<GRA_UNORM _152> _65, _173 _150 _64, _173 _149 alpha)
{_157 _156 _66=_155(_64);_157 _156 _63=_66 % GRA_RWTEXTURE2D_SCALE;_158 _68=(_63.x==0)&&(_63.y==0);_156 _67=_66/GRA_RWTEXTURE2D_SCALE;_159(alpha==0){_68=false;}_160 _159(alpha !=1.0){_150 pixelLocationAlpha=_136(_64*0.25f);_154 pixelId=(_154)(pixelLocationAlpha.y*16+pixelLocationAlpha.x*4);alpha=_140(_139(alpha,0.0625),0.9375);_157 _149 thresholdMaxtrix[16]={1.0f/17.0f,9.0f/17.0f,3.0f/17.0f,11.0f/17.0f,13.0f/17.0f,5.0f/17.0f,15.0f/17.0f,7.0f/17.0f,4.0f/17.0f,12.0f/17.0f,2.0f/17.0f,10.0f/17.0f,16.0f/17.0f,8.0f/17.0f,14.0f/17.0f,6.0f/17.0f};_149 threshold=thresholdMaxtrix[pixelId];_159(alpha < threshold){_68=false;}}gra_Branch _159(_68){
#if (GRA_PACK_RESOLVE_OUTPUT==0)
_65[_67]=Granite_PackTileId(resolve);
#else
_65[_67]=resolve;
#endif
}}
#endif
_149 _91(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126, _173 _150 _52, _173 _150 _53)
{_52*=_2;_53*=_2;_149 _32=_138(_52,_52);_149 _33=_138(_53,_53);_149 _34=_139(_32,_33);_149 _35=_140(_32,_33);_149 _36=0.5*_141(_34);_149 _37=0.5*_141(_35);_149 _38=_36-_37;_38=_140(_38,_1);_149 _167=_139(_36-_38-0.5f,0.0f);_169 _140(_167,_17);}
_149 _109(_173  GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126, _173 _150 _52, _173 _150 _53)
{_52*=_2;_53*=_2;_149 _32=_138(_52,_52);_149 _33=_138(_53,_53);_149 _34=_139(_32,_33);_149 _36=0.5*_141(_34)-0.5f;_169 _148(_36,0.0f,_17);}
_152 _92(_173 _150 _165, _173 _149 _51, _173 _149 textureID)
{
#if GRA_64BIT_RESOLVER == 0
_152 _46;_46.x=_137(_165.x,256.0f);_46.y=_135(_165.x/256.0f)+_137(_165.y,32.0f)*8.0f;_46.z=_135(_165.y/32.0f)+_137(_51,4.0f)*64.0f;_46.w=_135(_51/4.0f)+textureID*4.0f;_157 _149 _76=1.0f/255.0f;
#if GRA_BGRA == 0
_169 _76*_152(_149(_46.x),_149(_46.y),_149(_46.z),_149(_46.w));
#else
_169 _76*_152(_149(_46.z),_149(_46.y),_149(_46.x),_149(_46.w));
#endif
#else
_157 _149 _76=1.0f/65535.0f;_169 _152(_165.x,_165.y,_51,textureID)*_76;
#endif
}
_152 _93(_173 _152 _69)
{_152 _47;
#if GRA_BGRA == 0
_47=_69;
#else
_47=_69.zyxw;
#endif
_47*=255.0f;_149 _73=_47.x+_137(_47.y,16.0f)*256.0f;_149 _72=_135(_47.y/16.0f)+_47.z*16.0f;_149 _51=_137(_47.w,16.0f);_149 _75=_135(_47.w/16.0f);_169 _152(_73,_72,_51,_75);}
_151 _94(_173 GraniteTilesetConstantBuffer _125, _173 _150 _164, _173 _152 _40, _173 _154 _191, _174 _150 _27)
{
#if (GRA_FORCE_SM3 == 0) && ((GRA_HLSL_5 == 1) || (GRA_HLSL_4 == 1) || (GRA_GLSL_330 == 1))
uint data=_107(_40[_191]);uint slice=(data >> 24u)& 0x7Fu;uint _83=(data >> 14u)& 0x3FFu;uint _84=(data >> 4u)& 0x3FFu;uint revLevel=data & 0xFu;
#else
_154 data=_154(_40[_191]);_154 slice=0;_154 _83=(data/16384);_154 _84=(data % 16384)/16;_154 revLevel=(data % 16);
#endif
_150 _82;_82.x=_108(revLevel);_82.y=_82.x*_14;_150 _127=_136(_164*_82);_150 tileTexCoordCache=_127*_18+_150(_83,_84);_151 final=_151(tileTexCoordCache*_19(_191)+_20(_191),slice);_27=_82*_18*_19(_191);_169 final;}
_152 _95(_173 _152 _49, _173 _150 _60, _173 _150 _27)
{_150 _70=_136(_60*_27);_149 _39=_139(_70.x,1.0-_70.x);_39=_139(_139(_70.y,1.0-_70.y),_39);_149 _74=_145(0.98,0.99,_39);_152 _50=_152(1,1,1,1);_169 lerp(_49,_50,_74);}
_152 _113(_173 GraniteTilesetConstantBuffer _125, _173 _150 _165, _173 _149 _51)
{
#if GRA_PACK_RESOLVE_OUTPUT
_169 _92(_165,_51,_12);
#else
_169 _152(_165,_51,_12);
#endif
}
_152 _110(_173 GraniteTilesetConstantBuffer _125, _173 _150 _164, _173 _149 _80)
{_149 _51=_135(_80+0.5f);_150 _48;_48.x=_10;_48.y=_10*_14;_150 _41=_135(_164*_48*_144(0.5,_51));_169 _113(_125,_41,_51);}
void _112(_173 _151 _164, _173 _151 _88, _173 _151 _89, _173 GraniteStreamingTextureCubeConstantBuffer _128, _174 _154 _45, _174 _150 _168, _174 _150 _187, _174 _150 _188)
{_150 _85;_151 _86;_151 _87;_149 _90;_159(abs(_164.z)>=abs(_164.x)&& abs(_164.z)>=abs(_164.y)){_159(_164.z < 0.0){_45=5;_168.x=-_164.x;}_160{_45=4;_168.x=_164.x;}_168.y=-_164.y;_90=_164.z;_85=_150(_164.x,_164.y);_86=_151(_88.x,_88.y,_88.z);_87=_151(_89.x,_89.y,_89.z);}_160 _159(abs(_164.y)>=abs(_164.x)){_159(_164.y < 0.0){_45=3;_168.y=-_164.z;}_160{_45=2;_168.y=_164.z;}_168.x=_164.x;_90=_164.y;_85=_150(_164.x,_164.z);_86=_151(_88.x,_88.z,_88.y);_87=_151(_89.x,_89.z,_89.y);}_160{_159(_164.x < 0.0){_45=1;_168.x=_164.z;}_160{_45=0;_168.x=-_164.z;}_168.y=-_164.y;_90=_164.x;_85=_150(_164.z,_164.y);_86=_151(_88.z,_88.y,_88.x);_87=_151(_89.z,_89.y,_89.x);}_168=(_168+_90)/(2.0*abs(_90));
#if GRA_HQ_CUBEMAPPING
_187=((_85+_86.xy)/(2.0*(_90+_86.z))-(_85/(2.0*_90)));_188=((_85+_87.xy)/(2.0*(_90+_87.z))-(_85/(2.0*_90)));
#else
_187=((_86.xy)/(2.0*abs(_90)));_188=((_87.xy)/(2.0*abs(_90)));
#endif
_187*=_128.data[_45].data[0].zw;_188*=_128.data[_45].data[0].zw;}
void _112(_173 _151 _164, _173 GraniteStreamingTextureCubeConstantBuffer _128, _174 _154 _45, _174 _150 _168, _174 _150 _187, _174 _150 _188)
{_151 _88=_142(_164);_151 _89=_143(_164);_112(_164,_88,_89,_128,_45,_168,_187,_188);}
_150 Granite_GetTextureDimensions(_173 GraniteStreamingTextureConstantBuffer _126)
{_169 _150(1.0/_133,1.0/_134);}
_154 _198(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _180 _162,_174 _181 _81, _174 _152 _61,_173 _150 _187, _173 _150 _188)
{_149 _57=_109(_125,_126,_187,_188);_149 _51=_135(_57+0.5f);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_57);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_81._190=_42;_81._189=_164;_81._187=_187;_81._188=_188;_169 1;}
_154 _200(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_129(_164,_118);_169 _198(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _200(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=_129(_164,_118);_169 _198(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 _199(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_129(_164,_118));_169 _198(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _199(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_129(_164,_118));_43*=_120.zw;_44*=_120.zw;_169 _198(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 Granite_Lookup_PreTransformed_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _200(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _200(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _199(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _199(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Cube_Linear(	_173 _197 _124,_173 _180 _162, _173 _151 _164,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_169 _198(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Cube_Linear(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _151 _43, _173 _151 _44,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_169 _198(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 _201(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _180 _162,_174 _181 _81, _174 _152 _61,_173 _150 _187, _173 _150 _188)
{_149 _57=_109(_125,_126,_187,_188);_149 _51=_135(_57+0.5f);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_57);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_81._190=_42;_81._189=_164;_81._187=_187;_81._188=_188;_169 1;}
_154 _203(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_130(_164,_118);_169 _201(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _203(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=_130(_164,_118);_169 _201(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 _202(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_130(_164,_118));_169 _201(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _202(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_130(_164,_118));_43*=_120.zw;_44*=_120.zw;_169 _201(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 Granite_Lookup_PreTransformed_UDIM_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _203(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_UDIM_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _203(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_UDIM_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _202(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_UDIM_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _202(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Cube_UDIM_Linear(	_173 _197 _124,_173 _180 _162, _173 _151 _164,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_169 _201(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Cube_UDIM_Linear(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _151 _43, _173 _151 _44,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_169 _201(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 _204(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _180 _162,_174 _181 _81, _174 _152 _61,_173 _150 _187, _173 _150 _188)
{_149 _57=_109(_125,_126,_187,_188);_149 _51=_135(_57+0.5f);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_57);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_81._190=_42;_81._189=_164;_81._187=_187;_81._188=_188;_169 1;}
_154 _206(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_131(_164,_118);_169 _204(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _206(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=_131(_164,_118);_169 _204(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 _205(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_131(_164,_118));_169 _204(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _205(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_131(_164,_118));_43*=_120.zw;_44*=_120.zw;_169 _204(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 Granite_Lookup_PreTransformed_Clamp_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _206(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_Clamp_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _206(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Clamp_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _205(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_Clamp_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _205(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Cube_Clamp_Linear(	_173 _197 _124,_173 _180 _162, _173 _151 _164,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_169 _204(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Cube_Clamp_Linear(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _151 _43, _173 _151 _44,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_169 _204(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 _207(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _180 _162,_174 _181 _81, _174 _152 _61,_173 _150 _187, _173 _150 _188)
{_149 _57=_91(_125,_126,_187,_188);_149 _51=_135(_57+0.5f);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_57);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_81._190=_42;_81._189=_164;_81._187=_187;_81._188=_188;_169 1;}
_154 _209(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_129(_164,_118);_169 _207(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _209(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=_129(_164,_118);_169 _207(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 _208(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_129(_164,_118));_169 _207(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _208(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_129(_164,_118));_43*=_120.zw;_44*=_120.zw;_169 _207(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 Granite_Lookup_PreTransformed_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _209(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _209(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _208(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _208(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Cube_Anisotropic(	_173 _197 _124,_173 _180 _162, _173 _151 _164,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_169 _207(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Cube_Anisotropic(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _151 _43, _173 _151 _44,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_169 _207(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 _210(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _180 _162,_174 _181 _81, _174 _152 _61,_173 _150 _187, _173 _150 _188)
{_149 _57=_91(_125,_126,_187,_188);_149 _51=_135(_57+0.5f);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_57);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_81._190=_42;_81._189=_164;_81._187=_187;_81._188=_188;_169 1;}
_154 _212(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_130(_164,_118);_169 _210(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _212(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=_130(_164,_118);_169 _210(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 _211(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_130(_164,_118));_169 _210(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _211(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_130(_164,_118));_43*=_120.zw;_44*=_120.zw;_169 _210(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 Granite_Lookup_PreTransformed_UDIM_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _212(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_UDIM_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _212(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_UDIM_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _211(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_UDIM_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _211(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Cube_UDIM_Anisotropic(	_173 _197 _124,_173 _180 _162, _173 _151 _164,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_169 _210(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Cube_UDIM_Anisotropic(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _151 _43, _173 _151 _44,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_169 _210(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 _213(_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _180 _162,_174 _181 _81, _174 _152 _61,_173 _150 _187, _173 _150 _188)
{_149 _57=_91(_125,_126,_187,_188);_149 _51=_135(_57+0.5f);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_57);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_81._190=_42;_81._189=_164;_81._187=_187;_81._188=_188;_169 1;}
_154 _215(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_131(_164,_118);_169 _213(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _215(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=_131(_164,_118);_169 _213(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 _214(_173 _196 _124, _173 _150 _164, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_131(_164,_118));_169 _213(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 _214(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44, _173 _180 _162, _174 _181 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_131(_164,_118));_43*=_120.zw;_44*=_120.zw;_169 _213(_115,_118,_164,_162,_81,_61,_43,_44);}
_154 Granite_Lookup_PreTransformed_Clamp_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _215(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_Clamp_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _215(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Clamp_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_174 _181 _81, _174 _152 _61)
{_169 _214(_124,_164,_162,_81,_61);}
_154 Granite_Lookup_Clamp_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _150 _43, _173 _150 _44,_174 _181 _81, _174 _152 _61)
{_169 _214(_124,_164,_43,_44,_162,_81,_61);}
_154 Granite_Lookup_Cube_Clamp_Anisotropic(	_173 _197 _124,_173 _180 _162, _173 _151 _164,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_169 _213(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Cube_Clamp_Anisotropic(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _151 _43, _173 _151 _44,_174 _181 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_169 _213(_115,_121[_45],_168,_162,_81,_61,_187,_188);}
_154 _216(	_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _149 _80, _173 _180 _162,_174 _182 _81, _174 _152 _61)
{_80=_148(_80,0.0f,_17);_149 _51=_135(_80);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_80);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_149 _192=_136(_80);_81._190=_42;_81._189=_164;_81._192=_192;_169 1;}
_154 _218(_173 _196 _124, _173 _150 _164, _149 _80, _173 _180 _162, _174 _182 _81, _174 _152 _61)
{_169 _216(_115,_118,_164,_80,_162,_81,_61);}
_154 _217(_173 _196 _124, _173 _150 _164, _149 _80, _173 _180 _162, _174 _182 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_129(_164,_118));_169 _216(_115,_118,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_169 _218(_124,_164,_80,_162,_81,_61);}
_154 Granite_Lookup(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_169 _217(_124,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_Cube(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_169 _216(_115,_121[_45],_168,_80,_162,_81,_61);}
_154 _219(	_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _149 _80, _173 _180 _162,_174 _182 _81, _174 _152 _61)
{_80=_148(_80,0.0f,_17);_149 _51=_135(_80);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_80);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_149 _192=_136(_80);_81._190=_42;_81._189=_164;_81._192=_192;_169 1;}
_154 _221(_173 _196 _124, _173 _150 _164, _149 _80, _173 _180 _162, _174 _182 _81, _174 _152 _61)
{_169 _219(_115,_118,_164,_80,_162,_81,_61);}
_154 _220(_173 _196 _124, _173 _150 _164, _149 _80, _173 _180 _162, _174 _182 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_130(_164,_118));_169 _219(_115,_118,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_UDIM(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_169 _221(_124,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_UDIM(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_169 _220(_124,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_Cube_UDIM(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_169 _219(_115,_121[_45],_168,_80,_162,_81,_61);}
_154 _222(	_173 GraniteTilesetConstantBuffer _125, _173 GraniteStreamingTextureConstantBuffer _126,_173 _150 _164, _173 _149 _80, _173 _180 _162,_174 _182 _81, _174 _152 _61)
{_80=_148(_80,0.0f,_17);_149 _51=_135(_80);_150 _48=_150(_10,_10*_14);_150 _41=_135(_164*_48*_144(0.5,_51));_61=_113(_125,_41,_51);
#if (GRA_LOAD_INSTR==0)
_152 _42=GranitePrivate_SampleLevel_Translation(_162,_164,_80);
#else
_152 _42=_106(_162,gra_Int3(_41,_51));
#endif
_149 _192=_136(_80);_81._190=_42;_81._189=_164;_81._192=_192;_169 1;}
_154 _224(_173 _196 _124, _173 _150 _164, _149 _80, _173 _180 _162, _174 _182 _81, _174 _152 _61)
{_169 _222(_115,_118,_164,_80,_162,_81,_61);}
_154 _223(_173 _196 _124, _173 _150 _164, _149 _80, _173 _180 _162, _174 _182 _81, _174 _152 _61)
{_164=Granite_Transform(_118,_131(_164,_118));_169 _222(_115,_118,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_PreTransformed_Clamp(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_169 _224(_124,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_Clamp(	_173 _196 _124,_173 _180 _162, _173 _150 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_169 _223(_124,_164,_80,_162,_81,_61);}
_154 Granite_Lookup_Cube_Clamp(	_173 _197 _124,_173 _180 _162, _173 _151 _164, _173 _149 _80,_174 _182 _81, _174 _152 _61)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_169 _222(_115,_121[_45],_168,_80,_162,_81,_61);}
_154 Granite_Lookup_Dynamic_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_173 _158 asUDIM,_174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_150 actualUV=asUDIM ? _164 : _136(_164);_164=Granite_Transform(_118,actualUV);_169 _198(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Dynamic_Linear(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_173 _158 asUDIM, _173 _149 _80,_174 _182 graniteLODLookupData, _174 _152 _61)
{_150 actualUV=asUDIM ? _164 : _136(_164);_164=Granite_Transform(_118,actualUV);_169 _216(_115,_118,_164,_80,_162,graniteLODLookupData,_61);}
_154 Granite_Lookup_Dynamic_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_173 _158 asUDIM,_174 _181 _81, _174 _152 _61)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_150 actualUV=asUDIM ? _164 : _136(_164);_164=Granite_Transform(_118,actualUV);_169 _207(_115,_118,_164,_162,_81,_61,_187,_188);}
_154 Granite_Lookup_Dynamic_Anisotropic(	_173 _196 _124,_173 _180 _162, _173 _150 _164,_173 _158 asUDIM, _173 _149 _80,_174 _182 graniteLODLookupData, _174 _152 _61)
{_150 actualUV=asUDIM ? _164 : _136(_164);_164=Granite_Transform(_118,actualUV);_169 _216(_115,_118,_164,_80,_162,graniteLODLookupData,_61);}
_154 Granite_Sample_Internal(_173 GraniteTilesetConstantBuffer _125, _173 _181 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_150 _29;_151 _28=_94(_125,_81._189,_81._190,_191,_29);
#if GRA_TEXTURE_ARRAY_SUPPORT
_167=_99(_163,_28);
#else
_167=_96(_163,_28.xy);
#endif
#if GRA_DEBUG == 1
_159(_11 !=2202.0f){_167=_152(1,0,0,1);}
#endif
#if GRA_DEBUG_TILES == 1
#endif
_169 1;}
_154 Granite_Sample_HQ_Internal(_173 GraniteTilesetConstantBuffer _125, _173 _181 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_150 _29;_151 _28=_94(_125,_81._189,_81._190,_191,_29);_29*=_5;_150 _30=_81._187*_29;_150 _31=_81._188*_29;
#if GRA_TEXTURE_ARRAY_SUPPORT
_167=_101(_163,_28,_30,_31);
#else
_167=_98(_163,_28.xy,_30,_31);
#endif
#if GRA_DEBUG == 1
_159(_11 !=2202.0f){_167=_152(1,0,0,1);}
#endif
#if GRA_DEBUG_TILES == 1
#endif
_169 1;}
_154 Granite_Sample_Interal(_173 GraniteTilesetConstantBuffer _125, _173 _182 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_150 _29;_151 _28=_94(_125,_81._189,_81._190,_191,_29);
#if GRA_TEXTURE_ARRAY_SUPPORT
_167=_100(_163,_28,_81._192);
#else
_167=_97(_163,_28.xy,_81._192);
#endif
#if GRA_DEBUG == 1
_159(_11 !=2202.0f){_167=_152(1,0,0,1);}
#endif
#if GRA_DEBUG_TILES == 1
#endif
_169 1;}
_154 Granite_Sample(_173 _196 _124, _173 _181 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_169 Granite_Sample_Internal(_115,_81,_163,_191,_167);}
_154 Granite_Sample(_173 _197 _124, _173 _181 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_169 Granite_Sample_Internal(_115,_81,_163,_191,_167);}
_154 Granite_Sample_HQ(_173 _196 _124, _173 _181 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_169 Granite_Sample_HQ_Internal(_115,_81,_163,_191,_167);}
_154 Granite_Sample_HQ(_173 _197 _124, _173 _181 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_169 Granite_Sample_HQ_Internal(_115,_81,_163,_191,_167);}
_154 Granite_Sample(_173 _196 _124, _173 _182 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_169 Granite_Sample_Interal(_115,_81,_163,_191,_167);}
_154 Granite_Sample(_173 _197 _124, _173 _182 _81, _173 _179 _163, _173 _154 _191, _174 _152 _167)
{_169 Granite_Sample_Interal(_115,_81,_163,_191,_167);}
_152 Granite_ResolverPixel_PreTransformed_Linear(_173 _196 _124, _173 _150 _164)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_129(_164,_118);_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_PreTransformed_Linear(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=_129(_164,_118);_149 _51=_109(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Linear(_173 _196 _124, _173 _150 _164)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_129(_164,_118));_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Linear(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=Granite_Transform(_118,_129(_164,_118));_149 _51=_109(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Cube_Linear(_173 _197 _124, _173 _151 _164)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_149 _51=_109(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_Cube_Linear(_173 _197 _124, _173 _151 _164, _173 _151 _43, _173 _151 _44)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_149 _51=_109(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_PreTransformed_UDIM_Linear(_173 _196 _124, _173 _150 _164)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_130(_164,_118);_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_PreTransformed_UDIM_Linear(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=_130(_164,_118);_149 _51=_109(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_UDIM_Linear(_173 _196 _124, _173 _150 _164)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_130(_164,_118));_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_UDIM_Linear(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=Granite_Transform(_118,_130(_164,_118));_149 _51=_109(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Cube_UDIM_Linear(_173 _197 _124, _173 _151 _164)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_149 _51=_109(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_Cube_UDIM_Linear(_173 _197 _124, _173 _151 _164, _173 _151 _43, _173 _151 _44)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_149 _51=_109(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_PreTransformed_Clamp_Linear(_173 _196 _124, _173 _150 _164)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_131(_164,_118);_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_PreTransformed_Clamp_Linear(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=_131(_164,_118);_149 _51=_109(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Clamp_Linear(_173 _196 _124, _173 _150 _164)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_131(_164,_118));_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Clamp_Linear(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=Granite_Transform(_118,_131(_164,_118));_149 _51=_109(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Cube_Clamp_Linear(_173 _197 _124, _173 _151 _164)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_149 _51=_109(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_Cube_Clamp_Linear(_173 _197 _124, _173 _151 _164, _173 _151 _43, _173 _151 _44)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_149 _51=_109(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_PreTransformed_Anisotropic(_173 _196 _124, _173 _150 _164)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_129(_164,_118);_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_PreTransformed_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=_129(_164,_118);_149 _51=_91(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Anisotropic(_173 _196 _124, _173 _150 _164)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_129(_164,_118));_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=Granite_Transform(_118,_129(_164,_118));_149 _51=_91(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Cube_Anisotropic(_173 _197 _124, _173 _151 _164)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_149 _51=_91(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_Cube_Anisotropic(_173 _197 _124, _173 _151 _164, _173 _151 _43, _173 _151 _44)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_149 _51=_91(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_PreTransformed_UDIM_Anisotropic(_173 _196 _124, _173 _150 _164)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_130(_164,_118);_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_PreTransformed_UDIM_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=_130(_164,_118);_149 _51=_91(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_UDIM_Anisotropic(_173 _196 _124, _173 _150 _164)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_130(_164,_118));_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_UDIM_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=Granite_Transform(_118,_130(_164,_118));_149 _51=_91(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Cube_UDIM_Anisotropic(_173 _197 _124, _173 _151 _164)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_149 _51=_91(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_Cube_UDIM_Anisotropic(_173 _197 _124, _173 _151 _164, _173 _151 _43, _173 _151 _44)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_149 _51=_91(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_PreTransformed_Clamp_Anisotropic(_173 _196 _124, _173 _150 _164)
{_150 _187=_142(_164);_150 _188=_143(_164);_164=_131(_164,_118);_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_PreTransformed_Clamp_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=_131(_164,_118);_149 _51=_91(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Clamp_Anisotropic(_173 _196 _124, _173 _150 _164)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_164=Granite_Transform(_118,_131(_164,_118));_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Clamp_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _150 _43, _173 _150 _44)
{_164=Granite_Transform(_118,_131(_164,_118));_149 _51=_91(_115,_118,_43,_44);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Cube_Clamp_Anisotropic(_173 _197 _124, _173 _151 _164)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_149 _51=_91(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_Cube_Clamp_Anisotropic(_173 _197 _124, _173 _151 _164, _173 _151 _43, _173 _151 _44)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_43,_44,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_149 _51=_91(_115,_121[_45],_187,_188);_169 _110(_115,_168,_51);}
_152 Granite_ResolverPixel_PreTransformed(_173 _196 _124, _173 _150 _164, _173 _149 _80)
{_164=_129(_164,_118);_169 _110(_115,_164,_80);}
_152 Granite_ResolverPixel(_173 _196 _124, _173 _150 _164, _173 _149 _80)
{_164=Granite_Transform(_118,_129(_164,_118));_169 _110(_115,_164,_80);}
_152 Granite_ResolverPixel_Cube(_173 _197 _124, _173 _151 _164, _173 _149 _80)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_129(_168,_121[_45]));_169 _110(_115,_168,_80);}
_152 Granite_ResolverPixel_PreTransformed_UDIM(_173 _196 _124, _173 _150 _164, _173 _149 _80)
{_164=_130(_164,_118);_169 _110(_115,_164,_80);}
_152 Granite_ResolverPixel_UDIM(_173 _196 _124, _173 _150 _164, _173 _149 _80)
{_164=Granite_Transform(_118,_130(_164,_118));_169 _110(_115,_164,_80);}
_152 Granite_ResolverPixel_Cube_UDIM(_173 _197 _124, _173 _151 _164, _173 _149 _80)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_130(_168,_121[_45]));_169 _110(_115,_168,_80);}
_152 Granite_ResolverPixel_PreTransformed_Clamp(_173 _196 _124, _173 _150 _164, _173 _149 _80)
{_164=_131(_164,_118);_169 _110(_115,_164,_80);}
_152 Granite_ResolverPixel_Clamp(_173 _196 _124, _173 _150 _164, _173 _149 _80)
{_164=Granite_Transform(_118,_131(_164,_118));_169 _110(_115,_164,_80);}
_152 Granite_ResolverPixel_Cube_Clamp(_173 _197 _124, _173 _151 _164, _173 _149 _80)
{_154 _45;_150 _168;_150 _187;_150 _188;_112(_164,_119,_45,_168,_187,_188);_168=Granite_Transform(_121[_45],_131(_168,_121[_45]));_169 _110(_115,_168,_80);}
_152 Granite_ResolverPixel_Dynamic_Linear(_173 _196 _124, _173 _150 _164, _173 _158 asUDIM)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_150 actualUV=asUDIM ? _164 : _136(_164);_164=Granite_Transform(_118,actualUV);_149 _51=_109(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
_152 Granite_ResolverPixel_Dynamic_Anisotropic(_173 _196 _124, _173 _150 _164, _173 _158 asUDIM)
{_150 _187=_120.zw*_142(_164);_150 _188=_120.zw*_143(_164);_150 actualUV=asUDIM ? _164 : _136(_164);_164=Granite_Transform(_118,actualUV);_149 _51=_91(_115,_118,_187,_188);_169 _110(_115,_164,_51);}
