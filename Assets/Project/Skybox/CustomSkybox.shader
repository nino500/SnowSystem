
Shader "Custom/URP/Procedural Skybox Sun"
{
    Properties
    {
        [Header(Sky Settings)]
        [HDR] _HorizonColor("Horizon Color", Color) = (0.8, 0.65, 0.45, 1)
                _EdgeSmoothWidth("Edge Smooth Width",Range(0,0.03)) = 0.01
        
        _ShapeRadius("Shape Radius", Float) = 0.04


        [Header(Sun Settings)]
        [HDR] _SunTopColor("Sun Top Color", Color) = (0.1,0.55,1,1)
        [HDR] _SunBottomColor("Sun Bottom Color",Color)  = (1, 0.85, 0.55, 1)
        
        [Header(Moon Settings)]
        [HDR] _MoonTopColor("Sun Top Color", Color) = (0.1,0.55,1,1)
        [HDR] _MoonBottomColor("Sun Bottom Color",Color)  = (1, 0.85, 0.55, 1)
        
        _MoonOffset("Moon Offset",Range(-0.12,0.12)) = 0.04
        
        
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Background"
            "RenderType" = "Background"
            "PreviewType" = "Skybox"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            ZWrite Off
            ZTest LEqual
            Cull Off

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _SunTopColor;
                float4 _SunBottomColor;
            
                float4 _MoonTopColor;
                float4 _MoonBottomColor;
            
                float4 _HorizonColor;
                float _ShapeRadius;
            
                float _MoonOffset;
                float _EdgeSmoothWidth;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 directionWS : TEXCOORD0;
            };

            // Vertex Shader
            Varyings Vert(Attributes input)
            {
                Varyings output;

                // Object Space -> Clip Space
                output.positionCS = TransformObjectToHClip(input.positionOS);

                // 将天空盒放置在远裁剪平面
                output.positionCS.z =
                    UNITY_RAW_FAR_CLIP_VALUE * output.positionCS.w;

                // Object Space -> World Space
                // 获取天空盒顶点对应的世界空间方向
                output.directionWS =
                    TransformObjectToWorldDir(input.positionOS);

                return output;
            }

            // Fragment Shader
            half4 Frag(Varyings input) : SV_Target
            {
                // 1. 当前天空像素的世界空间方向
                float3 fragDirWS = normalize(input.directionWS);

                // 2. 获取 URP 主光源
                Light mainLight = GetMainLight();

                // 3. 获取太阳，月亮方向
                float3 sunDirWS = normalize(mainLight.direction);
                float3 moonDirWS = -sunDirWS;
                
                
                
                
                
                //太阳和月亮形状
                float sunSDF = distance(fragDirWS ,sunDirWS)-_ShapeRadius;
                 sunSDF = 1- smoothstep(0-_EdgeSmoothWidth,0,sunSDF);
                
                float moonSDF = distance(fragDirWS,moonDirWS)-_ShapeRadius;
                 float moon  = 1- smoothstep(0-_EdgeSmoothWidth,0,moonSDF);
                
                float3 crescentFragDirWS = normalize(float3((fragDirWS.x + _MoonOffset),fragDirWS.y,fragDirWS.z));
                float    crescentMoonSDF = distance(crescentFragDirWS,moonDirWS)-_ShapeRadius;
                    float crecentMoon = 1- smoothstep(0-_EdgeSmoothWidth,0,crescentMoonSDF);
                
                float comMoon = saturate(moon - crecentMoon);
                
                float3 shapeMask = saturate(sunSDF + comMoon) ;
                
                
                //背景颜色交替
                float3 dayGradientColor = lerp(_SunBottomColor,_SunTopColor,saturate(fragDirWS.y));
                float3 nightGradientColor = lerp(_MoonBottomColor,_MoonTopColor,saturate(fragDirWS.y));
                
                float3 worldColor = lerp(nightGradientColor,dayGradientColor,saturate(sunDirWS.y));
                
                
                //地平线颜色，只在太阳接近地平线颜色的时候显现
                float horizonMask = saturate(1-(abs(fragDirWS.y)));
                float sunFactor   =  saturate(1-abs(sunDirWS.y));
                float horizonFactor = sunFactor*horizonMask;
                
                float3 horizonColor = _HorizonColor*horizonFactor;

                float3 baseColor = lerp(worldColor,shapeMask,shapeMask);
                
                float3 finalColor = lerp(baseColor,horizonColor,horizonFactor);
                
                return half4(finalColor,1.0);
                
              
            }

            ENDHLSL
        }
    }
}
