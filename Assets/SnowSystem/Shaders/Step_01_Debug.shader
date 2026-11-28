Shader "Custom/Debug"
{
    Properties
    {
        [Toggle(_ENABLE_VERTEX_SNOW)] _EnableVertexSnow("Enable Vertex Snow ",Float) = 1
        _SlopeThreshold("坡度阈值",Range(0,1)) = 0.55
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "EnvironmentBase_Debug"
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature_local _ENABLE_VERTEX_SNOW
            
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/SnowSystem/Shaders/Includes/SnowCommon.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
                
       
            CBUFFER_START(UnityPerMaterial)
                
                float _SlopeThreshold;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
                float3 normalOS :NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 basePosWS :TEXCOORD0;
                float3 normalWS :TEXCOORD1;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 basePosWS = TransformObjectToWorld(input.positionOS.xyz);
               
                float3 finalPosWS = basePosWS;
                
                finalPosWS.y += GetSnowVertexOffset(basePosWS,normalWS,_SlopeThreshold,0.1);
                
                output.normalWS = normalWS;
                output.basePosWS = basePosWS; //basePosWS留给片元着色计算sky occlusion
                output.positionCS = TransformWorldToHClip(finalPosWS);
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 N = normalize(input.normalWS);
                
                
               float snowMask = GetSnowMask(input.basePosWS,N,_SlopeThreshold,0.1);
                
                
                return half4(lerp(half3(0.2,0.2,0.2),half3(0.95,0.95,1.0),snowMask),1.0);
                
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
