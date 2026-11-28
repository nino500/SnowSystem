Shader "SnowSystem/WriteTopDownHeight"
{
    Properties
    {
        
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
            Name "WriteTopDownHeight"
            Tags
            {
                "LightMode" = "UniversalForward"
            }
            
            ZWrite On
            ZTest LEqual
            Cull Back
            
            
            
            
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/SnowSystem/Shaders/Includes/SnowCommon.hlsl"

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float worldY :TEXCOORD0; 
            };

            Varyings vert(Attributes input)
            {
                Varyings output;

                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.worldY = posWS.y;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                //将世界高度归一化
                float normalY = saturate((input.worldY - _TopDownHeightRange.x)/_TopDownHeightRange.y);
                return normalY;
            }

            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}