
Shader "FakeLight/PlanarShadow" 
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

	SubShader
	{
		LOD 100
		pass 
		{  
			Tags { "RenderType" = "Opaque" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
		pass 
		{
			Tags { "LightMode" = "ForwardBase" }

			//讓陰影重疊融合
			Stencil 
			{ 
				Ref 2
				Comp NotEqual 
				Pass Replace 
			}

			//使陰影在平面之上  
			Offset -1,-1

			Blend DstColor SrcColor

			CGPROGRAM
			#pragma vertex vert   
			#pragma fragment frag  
			#include "UnityCG.cginc"  
			float4x4 _World2Ground;
			float4x4 _Ground2World;

			uniform float4 _FakeLightDir;

			float4 vert(float4 vertex: POSITION) : SV_POSITION
			{
				//float3 litDir;
				//litDir = WorldSpaceLightDir(vertex);
				float3 litDir = _FakeLightDir.xyz;//讀取假光源
				litDir = mul(_World2Ground,float4(litDir,0)).xyz;//把光源方向轉到接收平面空間
				litDir = normalize(litDir);

				float4 vt;
				vt = mul(unity_ObjectToWorld, vertex);
				vt = mul(_World2Ground,vt);//將物體頂點座標轉到接收平面空間
				vt.xz = vt.xz - (vt.y / litDir.y)*litDir.xz;//用三角型相似計算言光源方向投射後的xz  
				vt.y = 0.1;//使陰影保持在接收平面上  
				//vt=mul(vt,_World2Ground);//back to world  
				vt = mul(_Ground2World,vt);//用接收面的世界座標空間
				vt = mul(unity_WorldToObject,vt);//最後計算物件座標空間 

				return UnityObjectToClipPos(vt);//用MVP轉換輸出到Clip Space  
			}

			float4 frag(void) : COLOR
			{
				return float4(0.35,0.35,0.35,1);//陰影顏色
			}
			ENDCG
		}
	}
}
