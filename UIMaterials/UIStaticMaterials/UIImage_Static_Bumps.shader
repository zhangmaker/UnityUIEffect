/*
	Bump is an breath effect

	Parments:
	_CenterX: breath center X
	_CenterY: breath center Y
	_BumpRadius: breath radius
	_PulseAmplitude: breath Amplitude
*/

Shader "UIKit/UIImage/UIImage_Static_Bumps" {
	Properties {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_CenterX("Heart Center X", Range(-1, 2)) = 0.5
		_CenterY("Heart Center Y", Range(-1, 2)) = 0.5
		_BumpRadius("Heart Outer Radius", Range(0.001, 2)) = 0.3
		_PulseAmplitude("Pulse Amplitude", Range(-0.7, 4)) = 1

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
			Name "UIImage_Static_Bumps"
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
			uniform float _CenterX;
			uniform float _CenterY;
			uniform float _BumpRadius;
			uniform float _PulseAmplitude;

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
				float offsetX = IN.texcoord.x - _CenterX;
				float offsetY = IN.texcoord.y - _CenterY;
				float dis = sqrt(offsetX * offsetX + offsetY * offsetY);

				fixed4 color;
				if (dis <= _BumpRadius) {
					float radiusDis = dis / _BumpRadius;
					float2 coordOffset = pow(radiusDis, _PulseAmplitude) * float2(offsetX/dis, offsetY/dis) * dis;

					color = tex2D(_MainTex, float2(_CenterX, _CenterY) + coordOffset);
				}
				else {
					color = tex2D(_MainTex, IN.texcoord);
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
