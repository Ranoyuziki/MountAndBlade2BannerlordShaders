
#include "definitions.rsh"

#ifdef USE_DIRECTX12
#define in_texture (Texture2D_table[indices.t_custom_0])
#define out_texture (RWTexture2D_uint2_table[indices.u_custom_1])
#else
Texture2D in_texture : register(t_custom_0);
RWTexture2D<uint2> out_texture : register(u_custom_1);
#endif


static const float offset = 0.5f;

float colorDistance(float3 c0, float3 c1)
{
	return dot(c0 - c1, c0 - c1);
}

float colorDistance(float2 c0, float2 c1)
{
	return dot(c0 - c1, c0 - c1);
}

void ExtractColorBlockXY(out float2 col[16], Texture2D image, int3 texcoord)
{
	col[0] = image.Load(texcoord, int2(0, 0)).rg;
	col[1] = image.Load(texcoord, int2(1, 0)).rg;
	col[2] = image.Load(texcoord, int2(2, 0)).rg;
	col[3] = image.Load(texcoord, int2(3, 0)).rg;
	col[4] = image.Load(texcoord, int2(0, 1)).rg;
	col[5] = image.Load(texcoord, int2(1, 1)).rg;
	col[6] = image.Load(texcoord, int2(2, 1)).rg;
	col[7] = image.Load(texcoord, int2(3, 1)).rg;
	col[8] = image.Load(texcoord, int2(0, 2)).rg;
	col[9] = image.Load(texcoord, int2(1, 2)).rg;
	col[10] = image.Load(texcoord, int2(2, 2)).rg;
	col[11] = image.Load(texcoord, int2(3, 2)).rg;
	col[12] = image.Load(texcoord, int2(0, 3)).rg;
	col[13] = image.Load(texcoord, int2(1, 3)).rg;
	col[14] = image.Load(texcoord, int2(2, 3)).rg;
	col[15] = image.Load(texcoord, int2(3, 3)).rg;
}

void ExtractColorBlockRGB(out float3 col[16], Texture2D image, int3 texcoord)
{
	col[0] = image.Load(texcoord, int2(0, 0)).rgb;
	col[1] = image.Load(texcoord, int2(1, 0)).rgb;
	col[2] = image.Load(texcoord, int2(2, 0)).rgb;
	col[3] = image.Load(texcoord, int2(3, 0)).rgb;
	col[4] = image.Load(texcoord, int2(0, 1)).rgb;
	col[5] = image.Load(texcoord, int2(1, 1)).rgb;
	col[6] = image.Load(texcoord, int2(2, 1)).rgb;
	col[7] = image.Load(texcoord, int2(3, 1)).rgb;
	col[8] = image.Load(texcoord, int2(0, 2)).rgb;
	col[9] = image.Load(texcoord, int2(1, 2)).rgb;
	col[10] = image.Load(texcoord, int2(2, 2)).rgb;
	col[11] = image.Load(texcoord, int2(3, 2)).rgb;
	col[12] = image.Load(texcoord, int2(0, 3)).rgb;
	col[13] = image.Load(texcoord, int2(1, 3)).rgb;
	col[14] = image.Load(texcoord, int2(2, 3)).rgb;
	col[15] = image.Load(texcoord, int2(3, 3)).rgb;
}

float3 toYCoCg(float3 c)
{
	float Y = (c.r + 2 * c.g + c.b) * 0.25;
	float Co = ((2 * c.r - 2 * c.b) * 0.25 + offset);
	float Cg = ((-c.r + 2 * c.g - c.b) * 0.25 + offset);

	return float3(Y, Co, Cg);
}

void ExtractColorBlockYCoCg(out float3 col[16], Texture2D image, int3 texcoord)
{
	col[0] = toYCoCg(image.Load(texcoord, int2(0, 0)).rgb);
	col[1] = toYCoCg(image.Load(texcoord, int2(1, 0)).rgb);
	col[2] = toYCoCg(image.Load(texcoord, int2(2, 0)).rgb);
	col[3] = toYCoCg(image.Load(texcoord, int2(3, 0)).rgb);
	col[4] = toYCoCg(image.Load(texcoord, int2(0, 1)).rgb);
	col[5] = toYCoCg(image.Load(texcoord, int2(1, 1)).rgb);
	col[6] = toYCoCg(image.Load(texcoord, int2(2, 1)).rgb);
	col[7] = toYCoCg(image.Load(texcoord, int2(3, 1)).rgb);
	col[8] = toYCoCg(image.Load(texcoord, int2(0, 2)).rgb);
	col[9] = toYCoCg(image.Load(texcoord, int2(1, 2)).rgb);
	col[10] = toYCoCg(image.Load(texcoord, int2(2, 2)).rgb);
	col[11] = toYCoCg(image.Load(texcoord, int2(3, 2)).rgb);
	col[12] = toYCoCg(image.Load(texcoord, int2(0, 3)).rgb);
	col[13] = toYCoCg(image.Load(texcoord, int2(1, 3)).rgb);
	col[14] = toYCoCg(image.Load(texcoord, int2(2, 3)).rgb);
	col[15] = toYCoCg(image.Load(texcoord, int2(3, 3)).rgb);
}

// find minimum and maximum colors based on bounding box in color space
void FindMinMaxColorsBox(float3 block[16], out float3 mincol, out float3 maxcol)
{
	mincol = float3(1, 1, 1);
	maxcol = float3(0, 0, 0);

	for (int i = 0; i < 16; i++) 
	{
		mincol = min(mincol, block[i]);
		maxcol = max(maxcol, block[i]);
	}
}

void InsetBBox(in out float3 mincol, in out float3 maxcol)
{
	float3 inset = (maxcol - mincol) / 16.0 - (8.0 / 255.0) / 16;
	mincol = saturate(mincol + inset);
	maxcol = saturate(maxcol - inset);
}

void InsetYBBox(in out float mincol, in out float maxcol)
{
	float inset = (maxcol - mincol) / 32.0 - (16.0 / 255.0) / 32.0;
	mincol = saturate(mincol + inset);
	maxcol = saturate(maxcol - inset);
}

void InsetCoCgBBox(in out float2 mincol, in out float2 maxcol)
{
	float inset = length(maxcol - mincol) / 16.0 - (8.0 / 255.0) / 16;
	mincol = saturate(mincol + inset);
	maxcol = saturate(maxcol - inset);
}

void SelectDiagonal(float3 block[16], in out float3 mincol, in out float3 maxcol)
{
	float3 center = (mincol + maxcol) * 0.5;

	float2 cov = 0;
	for (int i = 0; i < 16; i++)
	{
		float3 t = block[i] - center;
		cov.x += t.x * t.z;
		cov.y += t.y * t.z;
	}

	if (cov.x < 0) 
	{
		float temp = maxcol.x;
		maxcol.x = mincol.x;
		mincol.x = temp;
	}

	if (cov.y < 0) 
	{
		float temp = maxcol.y;
		maxcol.y = mincol.y;
		mincol.y = temp;
	}
}

float3 RoundAndExpand(float3 v, out uint w)
{
	int3 c = round(v * float3(31, 63, 31));
	w = (c.r << 11) | (c.g << 5) | c.b;

	c.rb = (c.rb << 3) | (c.rb >> 2);
	c.g = (c.g << 2) | (c.g >> 4);

	return (float3)c * (1.0 / 255.0);
}

uint EmitEndPointsDXT1(in out float3 mincol, in out float3 maxcol)
{
	uint2 output;
	maxcol = RoundAndExpand(maxcol, output.x);
	mincol = RoundAndExpand(mincol, output.y);

	// We have to do this in case we select an alternate diagonal.
	if (output.x < output.y)
	{
		float3 tmp = mincol;
		mincol = maxcol;
		maxcol = tmp;
		return output.y | (output.x << 16);
	}

	return output.x | (output.y << 16);
}

uint EmitIndicesDXT1(float3 col[16], float3 mincol, float3 maxcol)
{
	// Compute palette
	float3 c[4];
	c[0] = maxcol;
	c[1] = mincol;
	c[2] = lerp(c[0], c[1], 1.0 / 3.0);
	c[3] = lerp(c[0], c[1], 2.0 / 3.0);

	// Compute indices
	uint indices = 0;
	for (int i = 0; i < 16; i++) {

		// find index of closest color
		float4 dist;
		dist.x = colorDistance(col[i], c[0]);
		dist.y = colorDistance(col[i], c[1]);
		dist.z = colorDistance(col[i], c[2]);
		dist.w = colorDistance(col[i], c[3]);

		uint4 b = dist.xyxy > dist.wzzw;
		uint b4 = dist.z > dist.w;

		uint index = (b.x & b4) | (((b.y & b.z) | (b.x & b.w)) << 1);
		indices |= index << (i * 2);
	}

	// Output indices
	return indices;
}

int GetYCoCgScale(float2 minColor, float2 maxColor)
{
	float2 m0 = abs(minColor - offset);
	float2 m1 = abs(maxColor - offset);

	float m = max(max(m0.x, m0.y), max(m1.x, m1.y));

	const float s0 = 64.0 / 255.0;
	const float s1 = 32.0 / 255.0;

	int scale = 1;
	if (m < s0) scale = 2;
	if (m < s1) scale = 4;

	return scale;
}

void SelectYCoCgDiagonal(const float3 block[16], in out float2 minColor, in out float2 maxColor)
{
	float2 mid = (maxColor + minColor) * 0.5;

	float cov = 0;
	for (int i = 0; i < 16; i++)
	{
		float2 t = block[i].yz - mid;
		cov += t.x * t.y;
	}
	if (cov < 0) {
		float tmp = maxColor.y;
		maxColor.y = minColor.y;
		minColor.y = tmp;
	}
}

uint EmitEndPointsYCoCgDXT5(in out float2 mincol, in out float2 maxcol, int scale)
{
	maxcol = (maxcol - offset) * scale + offset;
	mincol = (mincol - offset) * scale + offset;

	InsetCoCgBBox(mincol, maxcol);

	maxcol = round(maxcol * float2(31, 63));
	mincol = round(mincol * float2(31, 63));

	int2 imaxcol = maxcol;
	int2 imincol = mincol;

	uint2 output;
	output.x = (imaxcol.r << 11) | (imaxcol.g << 5) | (scale - 1);
	output.y = (imincol.r << 11) | (imincol.g << 5) | (scale - 1);

	imaxcol.r = (imaxcol.r << 3) | (imaxcol.r >> 2);
	imaxcol.g = (imaxcol.g << 2) | (imaxcol.g >> 4);
	imincol.r = (imincol.r << 3) | (imincol.r >> 2);
	imincol.g = (imincol.g << 2) | (imincol.g >> 4);

	maxcol = (float2)imaxcol * (1.0 / 255.0);
	mincol = (float2)imincol * (1.0 / 255.0);

	// Undo rescale.
	maxcol = (maxcol - offset) / scale + offset;
	mincol = (mincol - offset) / scale + offset;

	return output.x | (output.y << 16);
}

uint EmitIndicesYCoCgDXT5(float3 block[16], float2 mincol, float2 maxcol)
{
	// Compute palette
	float2 c[4];
	c[0] = maxcol;
	c[1] = mincol;
	c[2] = lerp(c[0], c[1], 1.0 / 3.0);
	c[3] = lerp(c[0], c[1], 2.0 / 3.0);

	// Compute indices
	uint indices = 0;
	for (int i = 0; i < 16; i++)
	{
		// find index of closest color
		float4 dist;
		dist.x = colorDistance(block[i].yz, c[0]);
		dist.y = colorDistance(block[i].yz, c[1]);
		dist.z = colorDistance(block[i].yz, c[2]);
		dist.w = colorDistance(block[i].yz, c[3]);

		uint4 b = dist.xyxy > dist.wzzw;
		uint b4 = dist.z > dist.w;

		uint index = (b.x & b4) | (((b.y & b.z) | (b.x & b.w)) << 1);
		indices |= index << (i * 2);
	}

	// Output indices
	return indices;
}

uint EmitAlphaEndPointsYCoCgDXT5(inout float mincol, inout float maxcol)
{
	InsetYBBox(mincol, maxcol);

	uint c0 = round(mincol * 255);
	uint c1 = round(maxcol * 255);

	return (c0 << 8) | c1;
}

uint2 EmitAlphaIndicesYCoCgDXT5(float3 block[16], float minAlpha, float maxAlpha)
{
	const int ALPHA_RANGE = 7;

	float mid = (maxAlpha - minAlpha) / (2.0 * ALPHA_RANGE);

	float ab1 = minAlpha + mid;
	float ab2 = (6 * maxAlpha + 1 * minAlpha) * (1.0 / ALPHA_RANGE) + mid;
	float ab3 = (5 * maxAlpha + 2 * minAlpha) * (1.0 / ALPHA_RANGE) + mid;
	float ab4 = (4 * maxAlpha + 3 * minAlpha) * (1.0 / ALPHA_RANGE) + mid;
	float ab5 = (3 * maxAlpha + 4 * minAlpha) * (1.0 / ALPHA_RANGE) + mid;
	float ab6 = (2 * maxAlpha + 5 * minAlpha) * (1.0 / ALPHA_RANGE) + mid;
	float ab7 = (1 * maxAlpha + 6 * minAlpha) * (1.0 / ALPHA_RANGE) + mid;

	uint2 indices = 0;

	uint index;
	int i;
	for (i = 0; i < 6; i++)
	{
		float a = block[i].x;
		index = 1;
		index += (a <= ab1);
		index += (a <= ab2);
		index += (a <= ab3);
		index += (a <= ab4);
		index += (a <= ab5);
		index += (a <= ab6);
		index += (a <= ab7);
		index &= 7;
		index ^= (2 > index);
		indices.x |= index << (3 * i + 16);
	}

	indices.y = index >> 1;

	for (i = 6; i < 16; i++)
	{
		float a = block[i].x;
		index = 1;
		index += (a <= ab1);
		index += (a <= ab2);
		index += (a <= ab3);
		index += (a <= ab4);
		index += (a <= ab5);
		index += (a <= ab6);
		index += (a <= ab7);
		index &= 7;
		index ^= (2 > index);
		indices.y |= index << (3 * i - 16);
	}

	return indices;
}


void InsetNormalsBBoxDXT5(in out float2 mincol, in out float2 maxcol)
{
	float2 inset;
	inset.x = (maxcol.x - mincol.x) / 32.0 - (16.0 / 255.0) / 32.0;      // ALPHA scale-bias.
	inset.y = (maxcol.y - mincol.y) / 16.0 - (8.0 / 255.0) / 16;      // GREEN scale-bias.
	mincol = saturate(mincol + inset);
	maxcol = saturate(maxcol - inset);
}

void InsetNormalsBBoxLATC(in out float2 mincol, in out float2 maxcol)
{
	float2 inset = (maxcol - mincol) / 32.0 - (16.0 / 255.0) / 32.0;  // ALPHA scale-bias.
	mincol = saturate(mincol + inset);
	maxcol = saturate(maxcol - inset);
}


uint EmitGreenEndPoints(in out float ming, in out float maxg)
{
	uint c0 = round(ming * 63);
	uint c1 = round(maxg * 63);

	ming = float((c0 << 2) | (c0 >> 4)) * (1.0 / 255.0);
	maxg = float((c1 << 2) | (c1 >> 4)) * (1.0 / 255.0);

	return (c0 << 21) | (c1 << 5);
}

uint EmitGreenIndices(float2 block[16], float minGreen, float maxGreen)
{
	const int GREEN_RANGE = 3;

	float bias = maxGreen + (maxGreen - minGreen) / (2.0 * GREEN_RANGE);
	float scale = 1.0f / (maxGreen - minGreen);

	// Compute indices
	uint indices = 0;
	for (int i = 0; i < 16; i++)
	{
		uint index = saturate((bias - block[i].y) * scale) * GREEN_RANGE;
		indices |= index << (i * 2);
	}

	uint i0 = (indices & 0x55555555);
	uint i1 = (indices & 0xAAAAAAAA) >> 1;
	indices = ((i0 ^ i1) << 1) | i1;

	// Output indices
	return indices;
}

uint EmitAlphaEndPoints(float mincol, float maxcol)
{
	uint c0 = round(mincol * 255);
	uint c1 = round(maxcol * 255);

	return (c0 << 8) | c1;
}

uint2 EmitAlphaIndices(float2 block[16], float minAlpha, float maxAlpha)
{
	const int ALPHA_RANGE = 7;

	float bias = maxAlpha + (maxAlpha - minAlpha) / (2.0 * ALPHA_RANGE);
	float scale = 1.0f / (maxAlpha - minAlpha);

	uint2 indices = 0;
	int i;
	for (i = 0; i < 6; i++)
	{
		uint index = saturate((bias - block[i].x) * scale) * ALPHA_RANGE;
		indices.x |= index << (3 * i);
	}

	for (i = 6; i < 16; i++)
	{
		uint index = saturate((bias - block[i].x) * scale) * ALPHA_RANGE;
		indices.y |= index << (3 * i - 18);
	}

	uint2 i0 = (indices >> 0) & 0x09249249;
	uint2 i1 = (indices >> 1) & 0x09249249;
	uint2 i2 = (indices >> 2) & 0x09249249;

	i2 ^= i0 & i1;
	i1 ^= i0;
	i0 ^= (i1 | i2);

	indices.x = (i2.x << 2) | (i1.x << 1) | i0.x;
	indices.y = (((i2.y << 2) | (i1.y << 1) | i0.y) << 2) | (indices.x >> 16);
	indices.x <<= 16;

	return indices;
}

uint2 EmitLuminanceIndices(float2 block[16], float minAlpha, float maxAlpha)
{
	const int ALPHA_RANGE = 7;

	float bias = maxAlpha + (maxAlpha - minAlpha) / (2.0 * ALPHA_RANGE);
	float scale = 1.0f / (maxAlpha - minAlpha);

	uint2 indices = 0;
	int i;
	for (i = 0; i < 6; i++)
	{
		uint index = saturate((bias - block[i].y) * scale) * ALPHA_RANGE;
		indices.x |= index << (3 * i);
	}

	for (i = 6; i < 16; i++)
	{
		uint index = saturate((bias - block[i].y) * scale) * ALPHA_RANGE;
		indices.y |= index << (3 * i - 18);
	}

	uint2 i0 = (indices >> 0) & 0x09249249;
	uint2 i1 = (indices >> 1) & 0x09249249;
	uint2 i2 = (indices >> 2) & 0x09249249;

	i2 ^= i0 & i1;
	i1 ^= i0;
	i0 ^= (i1 | i2);

	indices.x = (i2.x << 2) | (i1.x << 1) | i0.x;
	indices.y = (((i2.y << 2) | (i1.y << 1) | i0.y) << 2) | (indices.x >> 16);
	indices.x <<= 16;

	return indices;
}

[numthreads(4, 4, 1)]
#ifdef DXT5_NORMAL_COMPRESSION
void main_cs(uint3 globalIdx : SV_DispatchThreadID, uint3 localIdx : SV_GroupThreadID, uint3 groupIdx : SV_GroupID)
{
	// read block
	uint3 in_texel = int3(globalIdx.xy * 4, 0);
	uint2 out_texel = globalIdx.xy;
	float2 block[16];
	ExtractColorBlockXY(block, in_texture, in_texel);

	// find min and max colors
	float2 mincol, maxcol;
	FindMinMaxColorsBox(block, mincol, maxcol);
	InsetNormalsBBoxDXT5(mincol, maxcol);

	uint4 output;

	// Output X in DXT5 green channel.
	output.z = EmitGreenEndPoints(mincol.y, maxcol.y);
	output.w = EmitGreenIndices(block, mincol.y, maxcol.y);

	// Output Y in DXT5 alpha block.
	output.x = EmitAlphaEndPoints(mincol.x, maxcol.x);

	uint2 indices = EmitAlphaIndices(block, mincol.x, maxcol.x);
	output.x |= indices.x;
	output.y = indices.y;

	out_texture[out_texel].rg = output;
}
#elif YCOCG_DXT5_COMPRESSION // REMARK_OZGUR requires color reconstruction on sample
void main_cs(uint3 globalIdx : SV_DispatchThreadID, uint3 localIdx : SV_GroupThreadID, uint3 groupIdx : SV_GroupID)
{
	uint3 in_texel = int3(globalIdx.xy * 4, 0);
	uint2 out_texel = globalIdx.xy;

	float3 block[16];
	ExtractColorBlockYCoCg(block, in_texture, in_texel);

	float3 mincol, maxcol;
	FindMinMaxColorsBox(block, mincol, maxcol);

	SelectYCoCgDiagonal(block, mincol, maxcol);

	int scale = ScaleYCoCg(mincol.yz, maxcol.yz);
	uint4 output;
	output.z = EmitEndPointsYCoCgDXT5(mincol.yz, maxcol.yz, scale);
	output.w = EmitIndicesYCoCgDXT5(block, mincol.yz, maxcol.yz);

	InsetYBBox(mincol.x, maxcol.x);

	output.x = EmitAlphaEndPointsYCoCgDXT5(mincol.x, maxcol.x);

	uint2 indices = EmitAlphaIndicesYCoCgDXT5(block, mincol.x, maxcol.x);
	output.x |= indices.x;
	output.y = indices.y;

	out_texture[out_texel].rg = output;

	/*
	// Color reconstruction
	{
		float Y = rgba.a;
		float scale = 1.0 / ((255.0 / 8.0) * rgba.b + 1);
		float Co = (rgba.r - offset) * scale;
		float Cg = (rgba.g - offset) * scale;

		float R = Y + Co - Cg;
		float G = Y + Cg;
		float B = Y - Co - Cg;

		rgba = float4(R, G, B, 1);
	}
	*/
}
#else // DXT1
void main_cs(uint3 globalIdx : SV_DispatchThreadID, uint3 localIdx : SV_GroupThreadID, uint3 groupIdx : SV_GroupID)
{
	uint3 in_texel = int3(globalIdx.xy * 4, 0);
	uint2 out_texel = globalIdx.xy;
	
	float3 block[16];
	ExtractColorBlockRGB(block, in_texture, in_texel);

	float3 mincol, maxcol;
	FindMinMaxColorsBox(block, mincol, maxcol);

	SelectDiagonal(block, mincol, maxcol);
	InsetBBox(mincol, maxcol);

	uint2 output;
	output.x = EmitEndPointsDXT1(mincol, maxcol);
	output.y = EmitIndicesDXT1(block, mincol, maxcol);

	out_texture[out_texel].rg = output;
}

#endif
