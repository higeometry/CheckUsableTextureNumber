﻿Shader "Custom/TestTexture"
{
    Properties
    {
  
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Tex01("Albedo01 (RGB)", 2D) = "white" {}
        _Tex02("Albedo02 (RGB)", 2D) = "white" {}
        _Tex03("Albedo03 (RGB)", 2D) = "white" {}
        _Tex04("Albedo04 (RGB)", 2D) = "white" {}
        _Tex05("Albedo05 (RGB)", 2D) = "white" {}
        _Tex06("Albedo06 (RGB)", 2D) = "white" {}
        _Tex07("Albedo07 (RGB)", 2D) = "white" {}

        _Tex08("Albedo08 (RGB)", 2D) = "white" {}
        _Tex09("Albedo09 (RGB)", 2D) = "white" {}
        _Tex10("Albedo10(RGB)", 2D) = "white" {}
        _Tex11("Albedo11 (RGB)", 2D) = "white" {}
        _Tex12("Albedo12 (RGB)", 2D) = "white" {}
        _Tex13("Albedo13 (RGB)", 2D) = "white" {}
        _Tex14("Albedo14 (RGB)", 2D) = "white" {}
        _Tex15("Albedo15 (RGB)", 2D) = "white" {}
        

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="LightweightForward"
            }
            HLSLPROGRAM

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            sampler2D _MainTex;
            sampler2D _Tex01;
            sampler2D _Tex02;
            sampler2D _Tex03;
            sampler2D _Tex04;
            sampler2D _Tex05;
            sampler2D _Tex06;
            sampler2D _Tex07;

            sampler2D _Tex08;
            sampler2D _Tex09;
            sampler2D _Tex10;
            sampler2D _Tex11;
            sampler2D _Tex12;
            sampler2D _Tex13;
            sampler2D _Tex14;
            sampler2D _Tex15;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                //v.2.0.7
                float mirrorFlag : TEXCOORD5;
    
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 6);
                half4 fogFactorAndVertexLight   : TEXCOORD7; // x: fogFactor, yzw: vertex light
				float4 shadowCoord              : TEXCOORD8;
                float4 positionCS               : TEXCORRD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
    
            };
            
            #define _WorldSpaceLightPos0 _MainLightPosition
            #define _LightColor0 _MainLightColor
            inline float4 UnityObjectToClipPosInstanced(in float3 pos)
            {
            //    return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorldArray[unity_InstanceID], float4(pos, 1.0)));
                  // todo. right?
                  return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(pos, 1.0)));
            }
            inline float4 UnityObjectToClipPosInstanced(float4 pos)
            {
                return UnityObjectToClipPosInstanced(pos.xyz);
            }
            #define UnityObjectToClipPos UnityObjectToClipPosInstanced
            
            inline float3 UnityObjectToWorldNormal( in float3 norm )
            {
            #ifdef UNITY_ASSUME_UNIFORM_SCALING
                return UnityObjectToWorldDir(norm);
            #else
                // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
                return normalize(mul(norm, (float3x3)unity_WorldToObject));
            #endif
            }
            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0;
    
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                float3 crossFwd = cross(UNITY_MATRIX_V[0], UNITY_MATRIX_V[1]);
                o.mirrorFlag = dot(crossFwd, UNITY_MATRIX_V[2]) < 0 ? 1 : -1;
                    //
    
                float3 positionWS = TransformObjectToWorld(v.vertex);
                float4 positionCS = TransformWorldToHClip(positionWS);
                half3 vertexLight = VertexLighting(o.posWorld, o.normalDir);
                half fogFactor = ComputeFogFactor(positionCS.z);
    
                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalDir.xyz, o.vertexSH);
    
                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                o.positionCS = positionCS;
                o.shadowCoord = TransformWorldToShadowCoord(o.posWorld);
    
    
                return o;
            }
                
            float4 frag(VertexOutput i, half facing : VFACE) : SV_TARGET
            {
                half2 uv = half2(1.0-i.uv0.x, 1.0 - i.uv0.y);
                half4 col00 = tex2D(_MainTex, uv);
                half4 col01 = tex2D(_Tex01, uv);
                half4 col02 = tex2D(_Tex02, uv);
                half4 col03 = tex2D(_Tex03, uv);

                half4 col04 = tex2D(_Tex04, uv);
                half4 col05 = tex2D(_Tex05, uv);
                half4 col06 = tex2D(_Tex06, uv);
                half4 col07 = tex2D(_Tex07, uv);

                half4 col08 = tex2D(_Tex08, uv);
                half4 col09 = tex2D(_Tex09, uv);
                half4 col10 = tex2D(_Tex10, uv);
                half4 col11 = tex2D(_Tex11, uv);

                half4 col12 = tex2D(_Tex12, uv);
                half4 col13 = tex2D(_Tex13, uv);
                half4 col14 = tex2D(_Tex14, uv);
                half4 col15 = tex2D(_Tex15, uv);
                half pi = 3.141692;
                half dd = 16.0;
                half time = _Time.x * 10;
                half tt = fmod(time,dd) ;
                half min = 0.002f;
                half offset = 0.5f; // 0.5 is more funny.  1.0f;
                half fade00 = tt <= 1 ? (offset + sin((-0.5 + tt*2) * pi)) * 0.5 : min;
                half fade01 = tt <= 2 && tt > 1.0 ? (offset + sin((-0.5 + tt * 2 - 2.0) * pi)) * 0.5 : min;
                half fade02 = tt <= 3 && tt > 2.0 ? (offset + sin((-0.5 + tt * 2 - 4.0) * pi)) * 0.5 : min;
                half fade03 = tt <= 4 && tt > 3.0 ? (offset + sin((-0.5 + tt * 2 - 6.0) * pi)) * 0.5 : min;
                half fade04 = tt <= 5 && tt > 4.0 ? (offset + sin((-0.5 + tt * 2 - 8.0) * pi)) * 0.5 : min;
                half fade05 = tt <= 6 && tt > 5.0 ? (offset + sin((-0.5 + tt * 2 - 10.0) * pi)) * 0.5 : min;
                half fade06 = tt <= 7 && tt > 6.0 ? (offset + sin((-0.5 + tt * 2 - 12.0) * pi)) * 0.5 : min;
                half fade07 = tt <= 8 && tt > 7.0 ? (offset + sin((-0.5 + tt * 2 - 14.0) * pi)) * 0.5 : min;
                half fade08 = tt <= 9 && tt > 8.0 ? (offset + sin((-0.5 + tt * 2 - 16.0) * pi)) * 0.5 : min;
                half fade09 = tt <= 10 && tt > 9.0 ? (offset + sin((-0.5 + tt * 2 - 18.0) * pi)) * 0.5 : min;
                half fade10 = tt <= 11 && tt > 10.0 ? (offset + sin((-0.5 + tt * 2 - 20.0) * pi)) * 0.5 : min;
                half fade11 = tt <= 12 && tt > 11.0 ? (offset + sin((-0.5 + tt * 2 - 22.0) * pi)) * 0.5 : min;
                half fade12 = tt <= 13 && tt > 12.0 ? (offset + sin((-0.5 + tt * 2 - 24.0) * pi)) * 0.5 : min;
                half fade13 = tt <= 14 && tt > 13.0 ? (offset + sin((-0.5 + tt * 2 - 26.0) * pi)) * 0.5 : min;
                half fade14 = tt <= 15 && tt > 14.0 ? (offset + sin((-0.5 + tt * 2 - 28.0) * pi)) * 0.5 : min;
                half fade15 = tt <= 16 && tt > 15.0 ? (offset + sin((-0.5 + tt * 2 - 30.0) * pi)) * 0.5 : min;



                half4 col = col00 * fade00;

                col += col01 * fade01;
                col += col02 * fade02;
                col += col03 * fade03;
                col += col04 * fade04;
                col += col05 * fade05;
                col += col06 * fade06;
                col += col07 * fade07;
                col += col08 * fade08;
                col += col09 * fade09;
                col += col10 * fade10;
                col += col11 * fade11;
                col += col12 * fade12;
                col += col13 * fade13;
                col += col14 * fade14;
                col += col15 * fade15;

                return col;
            }    
            ENDHLSL
        }
    }
}
