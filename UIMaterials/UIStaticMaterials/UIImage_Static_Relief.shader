/*
	A relief effect
*/

Shader "UIKit/UIImage/UIImage_Static_Relief" {
	Properties {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		[Toggle(ConfigKernel)] _GrayRelief("Gray Relief", Int) = 1
		_ReliefAngle("Relief Angle", Range(0, 360)) = 0
		_ReliefHeight("Relief Height", Range(0, 0.1)) = 0.01
		_ReliefCount("Relief Count", Range(1, 500)) = 0.5
		_ReliefAlpha("Relief Alpha", Range(0, 1)) = 1

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

		Pass
		{
			Name "UIImage_Static_Relief"
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

			uniform sampler2D _MainTex;
			uniform fixed4 _TextureSampleAdd;
			uniform float4 _ClipRect;
			uniform int _GrayRelief;
			uniform float _ReliefAngle;
			uniform float _ReliefHeight;
			uniform float _ReliefCount;
			uniform float _ReliefAlpha;

			v2f vert(appdata_t IN) {
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;

				OUT.color = IN.color;
				return OUT;
			}

			fixed4 frag(v2f IN) : SV_Target {
				float offsetX = cos(_ReliefAngle / 180.0f * 3.1415926f) * _ReliefHeight;
				float offsetY = sin(_ReliefAngle / 180.0f * 3.1415926f) * _ReliefHeight;

				float4 colMainTex = tex2D(_MainTex, IN.texcoord);
				float4 colDeleteTex = tex2D(_MainTex, IN.texcoord + float2(offsetX, offsetY));

				fixed4 color;
				float4 canColor = ((colDeleteTex - colMainTex) + float4(1, 1, 1, 1)) * 0.5f;

				if (_GrayRelief != 0) {
					float validGray = canColor.r * 0.299f + canColor.g * 0.875f + canColor.b * 0.114f;
					float grayScale = floor(validGray * _ReliefCount) / _ReliefCount;
					color = float4(float4(grayScale, grayScale, grayScale, _ReliefAlpha) * IN.color);
				}
				else {
					color = float4(float4(canColor.rgb, _ReliefAlpha)*IN.color);
				}

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
