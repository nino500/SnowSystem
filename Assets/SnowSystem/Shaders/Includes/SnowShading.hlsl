#ifndef SNOW_SHADING_INCLUDED
#define SNOW_SHADING_INCLUDED

#include "Assets/SnowSystem/Shaders/Includes/SnowCommon.hlsl"

struct SnowSurfaceOutput
{
    half3 albedo;
    half3 normalTS;
    half smoothness;
    half3 emission; //v0.2 输出sss 和 冰晶闪烁
    
    float snowCoverage;
};

//随机数生成，将世界坐标划分成细碎冰格
float3 Hash33(float3 p)
{
    p = frac(p * float3(0.1031, 0.1030, 0.0973));
    p += dot(p, p.yxz + 33.33);
    return frac((p.xxy + p.yxx) * p.zyx);
}


//v0.2 雪花闪烁和次表面散射sss
half3 ComputeSnowEmission(float3 basePosWS,float3 normalWS,float3 mainLightDir,half3 lightColor,float3 viewDirWS,float shadowAttenuation,float snowCoverage)
{
    
    //雪材质权重过低，直接返回，不进行复杂效果计算
    if (snowCoverage < 0.1)return 0.0;
    
    
    //sss = wrap-lighting + back-scatter
        //wrap-lighting
    float wrapNdotL = saturate((dot(normalWS,mainLightDir)+0.5)/1.5);
    
        //back-scatter Factor
    float backScatterFactor = pow(max(0.0,dot(viewDirWS,-mainLightDir)),3.0)*shadowAttenuation;
    
    //sss color
    half3 sssColor = half3(0.16, 0.28, 0.45);
    
    half3 sss = sssColor*lightColor*(0.18*wrapNdotL + backScatterFactor*0.25);
    
    
    
   
    // 2. 微表面雪花闪烁 (Sparkle)：5毫米晶格随机微法线高光
    float distFade = saturate(1.0 - distance(_WorldSpaceCameraPos, basePosWS) / 18.0); // 18米外淡出防噪点闪烁
    float3 cell = floor(basePosWS * 160.0);
    float3 randNormal = normalize(normalWS + (Hash33(cell) - 0.5) * 1.5);
    float3 halfVec = normalize(mainLightDir + viewDirWS);
    float sparkle = pow(saturate(dot(randNormal, halfVec)), 128.0);
    sparkle = smoothstep(0.55, 0.95, sparkle) * shadowAttenuation * distFade;
    
    
    
    return sss + lightColor*sparkle*1.6;
    
    
    //specular
    
 
}




SnowSurfaceOutput GetSnowSurfaceOutput(half3 baseAlbedo,half3 baseNormalTS,half baseSmoothness,
    half3 snowAlbedo,half3 snowNormalTS,float snowSmoothness,float baseHeight,float heightContrast,
    float3 basePosWS,float3 normalWS,float _SlopeThreshold,float _SlopeSmoothness,
    Light mainLight,float3 viewDirWS)
    
{
    
    SnowSurfaceOutput output;
    
    float skyOcclustion = GetSkyOcclusion(basePosWS);
    float slope = GetSnowSlopeMask(normalWS,_SlopeThreshold,_SlopeSmoothness);
    
    float snowMask = saturate(skyOcclustion*slope);
    float snowCoverage = snowMask*_GlobalSnowCoverage*(((1.0-baseHeight)+heightContrast) / heightContrast);
    
    snowCoverage = saturate(snowCoverage);
    
    
    half3 albedo = lerp(baseAlbedo,snowAlbedo,snowCoverage);
    half3 normalTS = lerp(baseNormalTS,snowNormalTS,snowCoverage);
    half smoothness = lerp(baseSmoothness,snowSmoothness,snowCoverage);
    half3 emission = snowCoverage*ComputeSnowEmission(basePosWS,normalWS,mainLight.direction,mainLight.color,viewDirWS,mainLight.shadowAttenuation,snowCoverage);
    
    output.albedo = albedo;
    output.normalTS = normalTS;
    output.smoothness = smoothness;
    output.snowCoverage = snowCoverage;
    output.emission = emission;
    
    
    return output;
} 










#endif
