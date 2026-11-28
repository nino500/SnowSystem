#ifndef SNOW_COMMON_INCLUDED 
#define SNOW_COMMON_INCLUDED

//本库主要给雪地系统提供全局参数和对应方法



//TD 正交相机渲染高度图
TEXTURE2D(_TopDownHeightRT);
SAMPLER(sampler_TopDownHeightRT);

float4 _SnowWorldArea; //xy为场景中心位置， z为区域边长，w为1/边长
float4 _TopDownHeightRange;//相机深度范围x为底面高度，y为总范围
float _GlobalSnowThickness;//全局雪厚度
float _GlobalSnowCoverage;  // [v0.2 新增] 全局铺开率 (0~1)


//v0.1计算当前位置是否露天
float GetSkyOcclusion(float3 basePosWS)
{
    //1.
    //世界坐标映射到uv范围
    //雪地的位置由transform中心决定，所以这里的算的相对位置也是相对中心的
    //uv范围也要补偿成中心，所以加0.5
    float2 uv = (basePosWS.xz - _SnowWorldArea.xy)*_SnowWorldArea.w+0.5;
    if (uv.x < 0.0||uv.x> 1.0||uv.y < 0.0||uv.y> 1.0) return 1.0;
    
    //2.
    //在高度图中取出归一化高度，还原成真实世界高度Y
    float normalHeight = SAMPLE_TEXTURE2D_LOD(_TopDownHeightRT,sampler_TopDownHeightRT,uv,0).r;
    float topY = normalHeight*_TopDownHeightRange.y + _TopDownHeightRange.x;
    
    //3.
    //类shadodwmap方式，判断是否遮挡
    //给了一个容忍范围，在-0.45以下判断为被遮挡
    return smoothstep(topY-0.45,topY-0.15,basePosWS.y);
    
    

    
}

//v0.2 斜坡阈值遮罩，Shading和Vertex Offset都要用
float GetSnowSlopeMask(float3 normalWS,float threshold,float smoothness)
{
    return smoothstep(threshold-smoothness,threshold+smoothness,normalWS.y);
    
}


//v0.2 最终覆雪遮罩，综合遮蔽和坡度阈值
float GetSnowMask(float3 basePosWS,float3 normalWS,float slopeThreshold,float slopeSmoothness)
{
        float sky = GetSkyOcclusion(basePosWS);
        float slope = GetSnowSlopeMask(basePosWS,slopeThreshold,slopeSmoothness);
    return sky*slope;
}

//v0.2 顶点偏移接口：在覆雪遮罩下，根据全局雪厚度偏移顶点。
//条件编译。
//主相机和阴影相机都要使用
float GetSnowVertexOffset(float3 basePosWS,float3 normalWS,float slopeThreshold,float slopeSmoothness)
{
    
    #if defined(_ENABLE_VERTEX_SNOW)
        float snowMask = GetSnowMask(basePosWS,normalWS,slopeThreshold,slopeSmoothness);
        return _GlobalSnowThickness*snowMask;
    #else
        return 0.0;
    
    
    #endif
    
}







#endif
