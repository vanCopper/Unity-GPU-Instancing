// Upgrade NOTE: replaced 'UNITY_INSTANCE_ID' with 'UNITY_VERTEX_INPUT_INSTANCE_ID'

Shader "Copper/LightingShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			#pragma multi_compile_instancing
			//#pragma instancing_options forcemaxcount:456
			
			#include "UnityCG.cginc"

			//fixed4 _Color;

			struct appdata
			{
				UNITY_VERTEX_INPUT_INSTANCE_ID
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
			
			UNITY_INSTANCING_BUFFER_START(Props)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
				UNITY_DEFINE_INSTANCED_PROP(float4x4, _Te)
				UNITY_DEFINE_INSTANCED_PROP(float4x4, _Te1)
			UNITY_INSTANCING_BUFFER_END(Props)

			v2f vert (appdata v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v)
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4x4 Te = UNITY_ACCESS_INSTANCED_PROP(Props, _Te);
				fixed4x4 Te1 = UNITY_ACCESS_INSTANCED_PROP(Props, _Te1);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);
				//return col*_Color;
				return col * UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
			}
			ENDCG
		}
	}
}
