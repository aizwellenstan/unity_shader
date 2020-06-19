Shader "ErbGameArt/Particles/Sand" {
    Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _TintColor ("Color", Color) = (0.5,0.5,0.5,1)
        _Emission ("Emission", Float ) = 2
        _UVspeed ("U & V speed", Vector) = (0,1,0,0)
        _Mask ("Mask", 2D) = "white" {}
        [MaterialToggle] _Customdataonmaterialoff ("Custom data on/material off", Float ) = 0
        _Path ("Path", Float ) = 1
        [MaterialToggle] _Usedepth ("Use depth?", Float ) = 1
        _Depthpower ("Depth power", Float ) = 1
    }
    SubShader {
        Tags {
            "IgnoreProjector"="True"
            "Queue"="Transparent"
            "RenderType"="Transparent"
			"PreviewType"="Plane"
        }
        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="ForwardBase"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            uniform sampler2D _CameraDepthTexture;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float4 _TintColor;
            uniform float4 _UVspeed;
            uniform sampler2D _Mask; uniform float4 _Mask_ST;
            uniform float _Emission;
            uniform fixed _Usedepth;
            uniform float _Depthpower;
            uniform fixed _Customdataonmaterialoff;
            uniform float _Path;
            struct VertexInput {
                float4 vertex : POSITION;
                float4 texcoord0 : TEXCOORD0;
                float4 vertexColor : COLOR;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float4 uv0 : TEXCOORD0;
                float4 vertexColor : COLOR;
                float4 projPos : TEXCOORD1;
                UNITY_FOG_COORDS(2)
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.vertexColor = v.vertexColor;
                o.pos = UnityObjectToClipPos( v.vertex );
                UNITY_TRANSFER_FOG(o,o.pos);
                o.projPos = ComputeScreenPos (o.pos);
                COMPUTE_EYEDEPTH(o.projPos.z);
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                float sceneZ = max(0,LinearEyeDepth (UNITY_SAMPLE_DEPTH(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)))) - _ProjectionParams.g);
                float partZ = max(0,i.projPos.z - _ProjectionParams.g);
                float2 node_82 = ((float2(_UVspeed.r,_UVspeed.g)*_Time.g)+i.uv0);
                float4 _MainTex_var = tex2D(_MainTex,TRANSFORM_TEX(node_82, _MainTex));
                float3 emissive = (_MainTex_var.rgb*i.vertexColor.rgb*_TintColor.rgb*_Emission);
                float2 node_6082 = (i.uv0*float2(1.0,lerp( _Path, i.uv0.b, _Customdataonmaterialoff )));
                float4 _Mask_var = tex2D(_Mask,TRANSFORM_TEX(node_6082, _Mask));
                float node_8181 = 1.0;
                fixed4 finalRGBA = fixed4(emissive,(_MainTex_var.a*i.vertexColor.a*_TintColor.a*_Mask_var.a*(saturate((pow((i.uv0.g*-1.0+1.0),node_8181)*10.0))*lerp( node_8181, saturate((sceneZ-partZ)/_Depthpower), _Usedepth ))));
                UNITY_APPLY_FOG(i.fogCoord, finalRGBA);
                return finalRGBA;
            }
            ENDCG
        }
    }
}