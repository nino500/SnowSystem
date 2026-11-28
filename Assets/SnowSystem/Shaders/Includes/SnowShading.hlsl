#ifndef SNOW_SHADING_INCLUDED
#define SNOW_SHADING_INCLUDED

#include "Assets/SnowSystem/Shaders/Includes/SnowCommon.hlsl"

struct SnowSurfaceOutput
{
    half3 albedo;
    half3 normalTS;
    half smoothness;
    float snowProgress;
};



SnowSurfaceOutput GetSnowSurfaceOutput(half3 baseAlbedo,half3 baseNormalTS,half baseSmoothness,
    half3 snowAlbedo,half3 snowNormalTS,float snowSmoothness,float baseHeight,float heightContrast,
    float3 basePosWS,float3 normalWS,float _SlopeThreshold,float _SlopeSmoothness)
    
{
    
    SnowSurfaceOutput output;
    
    float skyOcclustion = GetSkyOcclusion(basePosWS);
    float slope = GetSnowSlopeMask(normalWS,_SlopeThreshold,_SlopeSmoothness);
    
    float snowMask = saturate(skyOcclustion*slope);
    float snowProgress = snowMask*_GlobalSnowCoverage*(((1.0-baseHeight)+heightContrast) / heightContrast);
    
    snowProgress = saturate(snowProgress);
    
    half3 albedo = lerp(baseAlbedo,snowAlbedo,snowProgress);
    half3 normalTS = lerp(baseNormalTS,snowNormalTS,snowProgress);
    half smoothness = lerp(baseSmoothness,snowSmoothness,snowProgress);
    
    output.albedo = albedo;
    output.normalTS = normalTS;
    output.smoothness = smoothness;
    output.snowProgress = snowProgress;
    
    return output;
} 






#endif
