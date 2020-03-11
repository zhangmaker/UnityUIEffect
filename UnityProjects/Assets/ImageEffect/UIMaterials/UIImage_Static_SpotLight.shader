/*
	An spot light effect
*/

Shader "UIKit/UIImage/UIImage_Static_SpotLight" {
	Properties {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_LightColor("Light Color", Color) = (1,1,1,1)
		_MinIllumination("Min Illumination", Range(0, 1)) = 0.2
		_MaxIllumination("Max Illumination", Range(0, 1)) = 0.8
		_CenterX("Center X", Range(-1, 2)) = 0.5
		_CenterY("Center Y", Range(-1, 2)) = 0.5
		_Umbra("Umbra", Range(0, 1.5)) = 0.2
		_Penumbra("Penumbra", Range(0, 1.5)) = 0.3

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
			Name "UIImage_Static_SpotLight"
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

			uniform float4 _LightColor;
			uniform float _MinIllumination;
			uniform float _MaxIllumination;
			uniform float _CenterX;
			uniform float _CenterY;
			uniform float _Umbra;
			uniform float _Penumbra;
			uniform float _TightnessBaseEff;
			uniform float _TightnessExponentEff;

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
				float4 colMain = tex2D(_MainTex, IN.texcoord) * IN.color;

				float offsetX = IN.texcoord.x - _CenterX;
				float offsetY = IN.texcoord.y - _CenterY;
				float dis = sqrt(abs(offsetX * offsetX + offsetY * offsetY));

				fixed4 color = colMain;
				if (_Umbra < _Penumbra) {
					if (dis < _Umbra) {
						color = colMain * _MaxIllumination;
					}
					else if (dis > _Penumbra) {
						color = colMain * _MinIllumination;
					}
					else {
						float validDiv = smoothstep(0, 1.0f, (dis - _Umbra) / (_Penumbra - _Umbra));

						float4 minColor = colMain * _MinIllumination;
						float4 maxColor = colMain * _MaxIllumination;

						color = lerp(maxColor, minColor, validDiv);
					}
				}
				color.a = colMain.a;

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
