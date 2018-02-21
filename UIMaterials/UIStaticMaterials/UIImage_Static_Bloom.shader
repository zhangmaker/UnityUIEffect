/*
	The process of bloom effect is follow:
	1. blur high level mip
	2. add image with blur image

	Paraments:
	_BlurDistance:  sample distance of Gaussian blur
	_BlurSampleLevel: mip level for blur image
	_BlurBlendFactor: bloom intensity

	Note: Bloom image must have mip feature
*/

Shader "UIKit/UIImage/UIImage_Static_Bloom" {
	Properties {
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_BlurDistance("Blur Distance", Range(0.001, 0.2)) = 0.01
		_BlurSampleLevel("Blur Sample Level", Range(0, 8)) = 0
		_BlurBlendFactor("Blur Level", Range(0, 2)) = 0
		_AdaptedLum("Adapted Lum", Range(0, 5)) = 1

		[HideInInspector] _StencilComp("Stencil Comparison", Float) = 8
		[HideInInspector] _Stencil("Stencil ID", Float) = 0
		[HideInInspector] _StencilOp("Stencil Operation", Float) = 0
		[HideInInspector] _StencilWriteMask("Stencil Write Mask", Float) = 255
		[HideInInspector] _StencilReadMask("Stencil Read Mask", Float) = 255

		[HideInInspector] _ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
	}

	SubShader{
		Tags{
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
			Name "UIImage_Static_Bloom_Blur"

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
			uniform float _BlurDistance;
			uniform float _BlurSampleLevel;

			uniform float blurKernel[9];
			static float GaussianKernel[9] = {
				0.0947416f, 0.118318f, 0.0947416f,
				0.118318f, 0.147761, 0.118318f,
				0.0947416f, 0.118318f, 0.0947416f
			};

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

			float4 frag(v2f IN) : SV_Target{
				// sample texture an blur
				float4 col1 = tex2Dlod(_MainTex, float4(IN.texcoord.x - _BlurDistance, IN.texcoord.y + _BlurDistance, 0, _BlurSampleLevel));
				float4 col2 = tex2Dlod(_MainTex, float4(IN.texcoord.x, IN.texcoord.y + _BlurDistance, 0, _BlurSampleLevel));
				float4 col3 = tex2Dlod(_MainTex, float4(IN.texcoord.x + _BlurDistance, IN.texcoord.y + _BlurDistance, 0, _BlurSampleLevel));
				float4 col4 = tex2Dlod(_MainTex, float4(IN.texcoord.x - _BlurDistance, IN.texcoord.y, 0, _BlurSampleLevel));
				float4 col5 = tex2Dlod(_MainTex, float4(IN.texcoord.x, IN.texcoord.y, 0, _BlurSampleLevel));
				float4 col6 = tex2Dlod(_MainTex, float4(IN.texcoord.x + _BlurDistance, IN.texcoord.y, 0, _BlurSampleLevel));
				float4 col7 = tex2Dlod(_MainTex, float4(IN.texcoord.x - _BlurDistance, IN.texcoord.y - _BlurDistance, 0, _BlurSampleLevel));
				float4 col8 = tex2Dlod(_MainTex, float4(IN.texcoord.x, IN.texcoord.y - _BlurDistance, 0, _BlurSampleLevel));
				float4 col9 = tex2Dlod(_MainTex, float4(IN.texcoord.x + _BlurDistance, IN.texcoord.y - _BlurDistance, 0, _BlurSampleLevel));

				float4 finColor;
				if (blurKernel[4] != 0) {
					finColor = (col1* blurKernel[0] + col2 * blurKernel[1] + col3 * blurKernel[2] +
						col4* blurKernel[3] + col5 * blurKernel[4] + col6 * blurKernel[5] +
						col7* blurKernel[6] + col8 * blurKernel[7] + col9* blurKernel[8]) * IN.color;
				}
				else {
					finColor = (col1* GaussianKernel[0] + col2 * GaussianKernel[1] + col3 * GaussianKernel[2] +
						col4* GaussianKernel[3] + col5 * GaussianKernel[4] + col6 * GaussianKernel[5] +
						col7* GaussianKernel[6] + col8 * GaussianKernel[7] + col9* GaussianKernel[8]) * IN.color;
				}

				return finColor;
			}
			ENDCG
		}
		
		GrabPass
		{
			"_BlurTexture"
		}

		Pass {
			Name "UIImage_Static_Bloom_Add"

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
				float4 grabPosition : TEXCOORD2;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _MainTex;
			uniform sampler2D _BlurTexture;
			uniform fixed4 _TextureSampleAdd;
			uniform float4 _ClipRect;
			uniform float _BlurBlendFactor;
			uniform float _AdaptedLum;

			float4 ACESToneMapping(float4 color, float adapted_lum) {
				const float A = 2.51f;
				const float B = 0.03f;
				const float C = 2.43f;
				const float D = 0.59f;
				const float E = 0.14f;

				color *= adapted_lum;
				return (color * (A * color + B)) / (color * (C * color + D) + E);
			}

			v2f vert(appdata_t IN) {
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				// use ComputeGrabScreenPos function from UnityCG.cginc
				// to get the correct texture coordinate
				OUT.grabPosition = ComputeGrabScreenPos(OUT.vertex);

				OUT.texcoord = IN.texcoord;

				OUT.color = IN.color;
				return OUT;
			}

			float4 frag(v2f IN) : SV_Target {
				float4 colMain = tex2D(_MainTex, IN.texcoord);
				float4 colBlend = tex2Dproj(_BlurTexture, IN.grabPosition);
				float4 color = colMain + colBlend * _BlurBlendFactor;

				color = ACESToneMapping(color, _AdaptedLum);

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
