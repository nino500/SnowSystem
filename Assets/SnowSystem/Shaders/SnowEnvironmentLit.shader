Shader "SnowSystem/SnowEnvironmentLit"
{
    Properties
    {
         [Toggle(_ENABLE_VERTEX_SNOW)] _EnableVertexSnow("Enable Vertex Snow (仅地面勾上)", Float) = 1

        [Header(Base Surface)]
        _BaseMap ("Base Albedo", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        [NoScaleOffset] _BaseNormalMap ("Base Normal (GL)", 2D) = "bump" {}
        [NoScaleOffset] _BaseRoughnessMap ("Base Roughness (Linear)", 2D) = "white" {}
        [NoScaleOffset] _BaseHeightMap ("Base Height (Linear)", 2D) = "gray" {}
        _BaseTiling ("Base Tiling", Float) = 1.0

        [Header(Snow Surface)]
        _SnowMap ("Snow Albedo", 2D) = "white" {}
        _SnowColor ("Snow Tint (严禁纯白)", Color) = (0.82, 0.85, 0.90, 1)
        [NoScaleOffset] _SnowNormalMap ("Snow Normal (GL)", 2D) = "bump" {}
        [NoScaleOffset] _SnowRoughnessMap ("Snow Roughness (Linear)", 2D) = "white" {}
        _SnowTiling ("Snow Tiling", Float) = 1.0

        [Header(Snow Masking)]
        _SlopeThreshold ("坡度阈值", Range(0, 1)) = 0.55
        _SlopeSmoothness ("坡度过渡柔和度", Range(0.01, 0.5)) = 0.2
        _HeightContrast ("砖缝填充锐度", Range(0.01, 1)) = 0.15
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        HLSLINCLUDE
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        CBUFFER_START(UnityPerMaterial)
        
        
        float _BaseTiling;
        float _SnowTiling;
        
        float3 _BaseColor;
        float3 _SnowColor;
        
        
        float _HeightContrast;
        float _SlopeThreshold;
        float _SlopeSmoothness;
        
        CBUFFER_END
        
        
        //提供雪地顶点偏移函数
        #include "Assets/SnowSystem/Shaders/Includes/SnowCommon.hlsl"
        
        
        
        
        
        
        
        
        
        
        ENDHLSL
        


        Pass
        {
            Name "ForwardLit"
            Tags {"LightMode" = "UniversalForward"}
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/SnowSystem/Shaders/Includes/SnowShading.hlsl"
            
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFrag
            #pragma shader_feature_local _ENABLE_VERTEX_SNOW
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            
            
            TEXTURE2D(_BaseMap);          SAMPLER(sampler_BaseMap);
            TEXTURE2D(_BaseNormalMap);    SAMPLER(sampler_BaseNormalMap);
            TEXTURE2D(_BaseRoughnessMap); SAMPLER(sampler_BaseRoughnessMap);
            TEXTURE2D(_BaseHeightMap);    SAMPLER(sampler_BaseHeightMap);

            TEXTURE2D(_SnowMap);          SAMPLER(sampler_SnowMap);
            TEXTURE2D(_SnowNormalMap);    SAMPLER(sampler_SnowNormalMap);
            TEXTURE2D(_SnowRoughnessMap); SAMPLER(sampler_SnowRoughnessMap);

            struct Attributes
            {
                float2 baseUV:TEXCOORD0;
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
                float4 tangentOS:TANGENT;
            };
            
            struct Varyings
            {
                float2 baseUV:TEXCOORD0;
                float4 positionCS:SV_POSITION;
                float3 basePosWS:TEXCOORD1;
                float3 finalPosWS:TEXCOORD2;
                float3 normalWS:TEXCOORD3;
                float4 tangentWS:TEXCOORD4;
                float  fogFactor   : TEXCOORD5;
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                    float4 shadowCoord : TEXCOORD6;
                #endif
                
                
            };
            
            Varyings LitPassVertex(Attributes input)
            {
                Varyings output;
                
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS,input.tangentOS);
                float3 normalWS = normalInputs.normalWS;
                float4 tangentWS = float4(normalInputs.tangentWS,1.0);
               
                
                float3 basePosWS = TransformObjectToWorld(input.positionOS.xyz);
                
                float3 finalPosWS = basePosWS;
                    finalPosWS.y += GetSnowVertexOffset(basePosWS,normalWS,_SlopeThreshold,_SlopeSmoothness);
                
                float4 positionCS = TransformWorldToHClip(finalPosWS);
                
                
               float2 baseUV = input.baseUV;
                
                output.basePosWS = basePosWS;
                output.finalPosWS = finalPosWS;
                output.positionCS = positionCS;
                output.baseUV = baseUV;
                output.normalWS = normalWS;
                output.tangentWS = tangentWS;
                output.fogFactor = ComputeFogFactor(positionCS.z);
                
                #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                output.shadowCoord = TransformWorldToShadowCoord(finalPosWS);
                #endif
                
                
                return output;
            }
            
            half4 LitPassFrag(Varyings input):SV_Target
        {
            
            
            
           
            float2 baseUV = input.baseUV * _BaseTiling;
            float2 snowUV = input.baseUV * _SnowTiling;
            
                half3 baseAlbedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV).rgb * _BaseColor.rgb;
                half3 baseNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BaseNormalMap, sampler_BaseNormalMap, baseUV));
                half  baseRough = SAMPLE_TEXTURE2D(_BaseRoughnessMap, sampler_BaseRoughnessMap, baseUV).r;
                half  baseHeight = SAMPLE_TEXTURE2D(_BaseHeightMap, sampler_BaseHeightMap, baseUV).r;

                half3 snowAlbedo = SAMPLE_TEXTURE2D(_SnowMap, sampler_SnowMap, snowUV).rgb * _SnowColor.rgb;
                half3 snowNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_SnowNormalMap, sampler_SnowNormalMap, snowUV));
                half  snowRough = SAMPLE_TEXTURE2D(_SnowRoughnessMap, sampler_SnowRoughnessMap, snowUV).r;            
            
            
            
            float4 shadowCoord = float4(0.0,0.0,0.0,0.0); 
                  #if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
                shadowCoord = input.shadowCoord;
            #elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
                shadowCoord = TransformWorldToShadowCoord(input.finalPosWS);
            #endif
            
                 float3 normalWS = normalize(input.normalWS);
            float4 tangentWS = normalize(input.tangentWS);
            float3 bitangentWS = cross(normalWS,tangentWS.xyz)*tangentWS.w*GetOddNegativeScale();
            float3x3 TBN = float3x3(tangentWS.xyz,bitangentWS,normalWS);
            
            
            Light mainLight = GetMainLight(shadowCoord);
            float3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.finalPosWS);
            
            

                SnowSurfaceOutput snowSurface = GetSnowSurfaceOutput(baseAlbedo,baseNormalTS,1.0-baseRough,
                    snowAlbedo,snowNormalTS,1.0-snowRough,baseHeight,_HeightContrast,
                    input.basePosWS,input.normalWS,_SlopeThreshold,_SlopeSmoothness,
                    mainLight,viewDirWS);
            
            
            SurfaceData surfaceData = (SurfaceData)0;
            surfaceData.albedo = snowSurface.albedo;
            surfaceData.smoothness = snowSurface.smoothness;
            surfaceData.occlusion = 1.0;
            surfaceData.alpha = 1.0;
            surfaceData.normalTS = snowSurface.normalTS;
            
            surfaceData.emission = snowSurface.emission; //snow sss
            
              
       
            
            InputData inputData  = (InputData)0;
            inputData.positionWS = input.finalPosWS;
            inputData.positionCS = input.positionCS;
            inputData.normalWS = NormalizeNormalPerPixel(TransformTangentToWorld(surfaceData.normalTS,TBN,true));
            inputData.viewDirectionWS = GetWorldSpaceNormalizeViewDir(input.finalPosWS);
            inputData.bakedGI = SampleSH(inputData.normalWS);
            inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);
            inputData.shadowMask = half4(1.0,1.0,1.0,1.0);
            inputData.shadowCoord = shadowCoord;
            inputData.fogCoord = input.fogFactor;
            
      
            
            half4 color = UniversalFragmentPBR(inputData,surfaceData);
            color.rgb = MixFog(color.rgb,inputData.fogCoord);
            return color;
        }
        
            ENDHLSL
            
            
        }

        Pass
        {
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}
            
            
            
            ZWrite On
            ColorMask 0
            ZTest LEqual
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            #pragma vertex ShadowCasterVertex
            #pragma fragment ShadowCasterFragment
            #pragma shader_feature_local _ENABLE_VERTEX_SNOW
            
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            
            float3 _LightDirection;
            float3 _LightPosition;
        
            struct Attributes
            {
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
            };


            struct Varyings
            {
                float4 positionCS:SV_POSITION;
            };
            
            
            
            Varyings ShadowCasterVertex(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS,true);
                
                //雪地顶点向上偏移
                positionWS.y += GetSnowVertexOffset(positionWS,normalWS,_SlopeThreshold,_SlopeSmoothness);
                
                //阴影兼容多光源
                #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
                    float3 lightDirection = normalize(_LightPosition - positionWS);
                
                #else
                    float3 lightDirection = _LightDirection;
                
                #endif
                
                //沿法线偏移和深度钳制，分别解决阴影痤疮和近平面裁剪问题
                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS,normalWS,lightDirection));
                
                #if defined(UNITY_REVERSED_Z)
                
                    positionCS.z = min(positionCS.z,UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z,UNITY_NEAR_CLIP_VALUE);
                
                #endif
                
                
                output.positionCS = positionCS;
                return output;
            }
          
            half4 ShadowCasterFragment(Varyings input):SV_Target
            {
                return 0;
            }
            
            ENDHLSL
        }


        Pass
        {
            Name "DepthOnly"
            Tags {"LightMode" = "DepthOnly"}
            
            ColorMask r
            ZWrite On
            
            HLSLPROGRAM
                
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #pragma vertex DepthVertex
            #pragma fragment DepthFragment
            #pragma shader_feature_local _ENABLE_VERTEX_SNOW


            struct Attributes
            {
                float4 positionOS:POSITION;
                float3 normalOS:NORMAL;
            };


            struct Varyings
            {
                float4 positionCS:SV_POSITION;
            };
            
            
            Varyings DepthVertex(Attributes input)
            {
                Varyings output;
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                positionWS.y += GetSnowVertexOffset(positionWS,normalWS,_SlopeThreshold,_SlopeSmoothness);
                
                float4 positionCS = TransformWorldToHClip(positionWS);
                
                output.positionCS = positionCS;
                return output;
                
            }
            
            half4 DepthFragment(Varyings input):SV_Target
            {
                return 0;
            }
            
        
            ENDHLSL
            
        }
    }

   


}
