/*
	Sharp one image with a 3x3 sharp kernel
*/

Shader "UIKit/UIImage/UIImage_Static_Sharp" {
	Properties {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)
		_LineWidth("line Width", Range(0, 0.25)) = 0.001
		[Toggle(ConfigKernel)] _ConfigKernel("Config Kernel", Int) = 0

		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255

		[HideInInspector] _ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
	}

	SubShader {
		Tags {
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
			"PreviewType" = "Plane"
			"CanUseSpriteAtlas" = "True"
		}

		Stencil {
			Ref[_Stencil]
			Comp[_StencilComp]
			Pass[_StencilOp]
			ReadMask[_StencilReadMask]
			WriteMask[_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest[unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask[_ColorMask]

		Pass {
			Name "UIImage_Static_Sharp"

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP

			struct appdata_t {
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			static float LaplacianKernel[9] = {
				-1.0f, -1.0f, -1.0f,
				-1.0f, 8.0f, -1.0f,
				-1.0f, -1.0f, -1.0f
			};

			uniform sampler2D _MainTex;
			uniform fixed4 _Color;
			uniform fixed4 _TextureSampleAdd;
			uniform float4 _ClipRect;	
			uniform float _LineWidth;
			uniform int _ConfigKernel;

			v2f vert(appdata_t IN) {
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;

				OUT.color = IN.color * _Color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target {
				float4 col11 = tex2D(_MainTex, float2(IN.texcoord.x - _LineWidth, IN.texcoord.y + _LineWidth));
				float4 col12 = tex2D(_MainTex, float2(IN.texcoord.x, IN.texcoord.y + _LineWidth));
				float4 col13 = tex2D(_MainTex, float2(IN.texcoord.x + _LineWidth, IN.texcoord.y + _LineWidth));
				float4 col21 = tex2D(_MainTex, float2(IN.texcoord.x - _LineWidth, IN.texcoord.y));
				float4 col22 = tex2D(_MainTex, IN.texcoord);
				float4 col23 = tex2D(_MainTex, float2(IN.texcoord.x + _LineWidth, IN.texcoord.y));
				float4 col31 = tex2D(_MainTex, float2(IN.texcoord.x - _LineWidth, IN.texcoord.y - _LineWidth));
				float4 col32 = tex2D(_MainTex, float2(IN.texcoord.x, IN.texcoord.y - _LineWidth));
				float4 col33 = tex2D(_MainTex, float2(IN.texcoord.x + _LineWidth, IN.texcoord.y - _LineWidth));

				fixed4 color = (col22
						+ (LaplacianKernel[0] * col11 + LaplacianKernel[1] * col12 + LaplacianKernel[2] * col13 +
							LaplacianKernel[3] * col21 + LaplacianKernel[4] * col22 + LaplacianKernel[5] * col23 +
							LaplacianKernel[6] * col31 + LaplacianKernel[7] * col32 + LaplacianKernel[8] * col33)
						+ _TextureSampleAdd) * IN.color;

				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);

		#ifdef UNITY_UI_ALPHACLIP
				clip(color.a - 0.001);
		#endif

				return color;
			}
			ENDCG
		}
	}
}
