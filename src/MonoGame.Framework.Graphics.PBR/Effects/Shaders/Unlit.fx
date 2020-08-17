﻿//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Shader globals
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// https://github.com/KhronosGroup/glTF-Sample-Viewer/tree/master/src/shaders

#include "MacrosSM4.fxh"

#define SKINNED_EFFECT_MAX_BONES   128

DECLARE_TEXTURE(PrimaryTexture, 0);     // either BaseColor or Diffuse
DECLARE_TEXTURE(EmissiveTexture, 1);
DECLARE_TEXTURE(OcclusionTexture, 2);

BEGIN_CONSTANTS

    float4x4 World;
    float4x4 View;
    float4x4 Projection;
    float4x3 Bones[SKINNED_EFFECT_MAX_BONES]; // 4x3 is enough, and saves constants            

    float4 PrimaryScale;    // either BaseColor or Diffuse
    float OcclusionScale;
    float3 EmissiveScale;    

    float Exposure; // parameter for ToneMapping.toneMap

END_CONSTANTS

#include "ToneMapping.fx"

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// PIXEL SHADERS
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Vertex Shader output, Pixel Shader input
struct VsOutTexNorm
{
    float4 PositionPS : SV_Position;

    float4 Color: COLOR0;
    float2 TextureCoordinate : TEXCOORD0;
    float3 PositionWS : TEXCOORD1;

    // float3x3 TangentBasis : TBASIS; requires Shader Model 4 :(

    float3 TangentBasisX : TEXCOORD2;
    float3 TangentBasisY : TEXCOORD3;
    float3 TangentBasisZ : TEXCOORD4;
};

#include "Sampler.Primary.fx"
#include "Sampler.Emissive.fx"
#include "Sampler.Occlusion.fx"

float4 PsShader(VsOutTexNorm input, bool hasPrimary, bool hasEmissive, bool hasOcclusion)
{
    float4 f_primary = input.Color * PrimaryScale;
    if (hasPrimary) f_primary *= getBaseColor(input.TextureCoordinate, 1);    

    float3 f_emissive = EmissiveScale;
    if (hasEmissive) f_emissive *= getEmissiveColor(input.TextureCoordinate);

    float f_occlusion = 1;
    if (hasOcclusion) f_occlusion = getAmbientOcclusion(input.TextureCoordinate);

    float3 color = f_primary.rgb;

    color += f_emissive;
    color = lerp(color, color * f_occlusion, OcclusionScale);
    color = toneMap(color);

    return float4(color.xyz, 1);    
}