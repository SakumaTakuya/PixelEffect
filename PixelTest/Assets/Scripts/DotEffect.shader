Shader "Hidden/DotEffect"
{
	Properties
	{
		_MainTex("MainTex", 2D) = ""{}
	}

	SubShader
	{
		Pass
		{
			CGPROGRAM

#include "UnityCG.cginc"

#pragma vertex vert_img
#pragma fragment frag

			sampler2D _CameraDepthTexture;
			sampler2D _MainTex;//現在カメラにレンダリングされたテクスチャ
			float _ThresholdLum;//アウトラインを判断する閾値
			float _ThresholdDep;//アウトラインを判断する閾値
			int _Fineness;//ドットの細かさ（画面の大きさに左右されるので注意）
			float2 _Rate;//画面比（横：縦）　何故か_ScreenParamsだとうまくいかなかった
			fixed4 _OutlineColor;//アウトラインの基準色
			float _Sharpness;//アウトラインの鋭さ

			//格子の中心の色を参照する＝画質が荒くなりドット調になる
			inline float2 getPoint(float2 p, float2 fineness) 
			{
				return (floor(p * fineness) + 0.5) / fineness;
			}

			fixed4 frag(v2f_img img) : COLOR
			{
				float2 fineness = _Fineness * _Rate;
				float2 st = getPoint(img.uv, fineness);

				fixed4 c = tex2D(_MainTex, st);

				float2 dPos = getPoint(img.uv, fineness);
				fixed4 dCol;
				float lumX = 0;
				float lumY = 0;

				//Sobelフィルタ
				int x[3] = { 1, 2, 1 };
				int y[3] = { -1, 0, 1 };

//輝度差によるアウトライン
#if 0


				//数値微分（Sobelフィルタによる畳み込み）によって輝度差を求める
				for(int i = 0; i < 3; i++)
				for (int j = 0; j < 3; j++) 
				{
					dCol = tex2D(_MainTex, dPos + float2(i-1, j-1) / fineness / _Sharpness);
					
					lumX += x[i] * y[j] * Luminance(dCol.rgb);
					lumY += x[j] * y[i] * Luminance(dCol.rgb);
				}

				//輝度差のノルムが閾値を超えたとき、輪郭として塗る
				if (sqrt(lumX * lumX + lumY * lumY) > _ThresholdLum) 
				{
					c = lerp(_OutlineColor, c, 0.5);
				}
#endif

//Depthバッファによるアウトライン
#if 0
				float diff;
				//数値微分（Sobelフィルタによる畳み込み）によって深度差を求める
				for (int i = 0; i < 3; i++)
					for (int j = 0; j < 3; j++)
					{

						diff = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, dPos + float2(i - 1, j - 1) / fineness / _Sharpness));
						
						lumX += x[i] * y[j] * diff;
						lumY += x[j] * y[i] * diff;
					}

				//輝度差のノルムが閾値を超えたとき、輪郭として塗る
				if (sqrt(lumX * lumX + lumY * lumY) > _ThresholdDep)
				{
					c = lerp(_OutlineColor, c, 0.5);
				}
#endif


//輝度とDepthバッファによるアウトライン
#if 1
				float diff;
				float depX = 0;
				float depY = 0;
				//数値微分（Sobelフィルタによる畳み込み）によって深度差および輝度差を求める
				for (int i = 0; i < 3; i++)
					for (int j = 0; j < 3; j++)
					{

						diff = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, dPos + float2(i - 1, j - 1) / fineness / _Sharpness));
						depX += x[i] * y[j] * diff;
						depY += x[j] * y[i] * diff;

						dCol = tex2D(_MainTex, dPos + float2(i - 1, j - 1) / fineness / _Sharpness);
						lumX += x[i] * y[j] * Luminance(dCol.rgb);
						lumY += x[j] * y[i] * Luminance(dCol.rgb);
					}

				//輝度差のノルムが閾値を超えたとき、輪郭として塗る
				if (sqrt(depX * depX + depY * depY) > _ThresholdDep || sqrt(lumX * lumX + lumY * lumY) > _ThresholdLum)
				{
					c = lerp(_OutlineColor, c, 0.5);
				}
#endif

				return c;
			}

			ENDCG
		}
	}
}
