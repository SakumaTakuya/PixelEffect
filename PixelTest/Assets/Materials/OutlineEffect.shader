Shader "Hidden/OutlineEffect"
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
	float _ThresholdDep;//アウトラインを判断する閾値
	float _ThresholdLum;//アウトラインを判断する閾値
	float _MaxDepth;
	float _Alpha;//色の不透明度
	fixed4 _OutlineColor;//アウトラインの基準色
	float _Sharpness;//アウトラインの鋭さ


	fixed4 frag(v2f_img img) : COLOR
	{
		fixed4 c = tex2D(_MainTex, img.uv);
		float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, img.uv));
		

		//float distance = length(float3(UNITY_MATRIX_MV[0][3], UNITY_MATRIX_MV[1][3], UNITY_MATRIX_MV[2][3]));
		//float sharpness = 1 / (1 + exp(depth *0.5 - 100 )) * _Sharpness;
		//if(depth < _MaxDepth) return c;
		//if(depth < _MaxDepth) return c;

		float depX = 0;
		float depY = 0;
		float diff;

		float lumX = 0;
		float lumY = 0;
		fixed4 dCol;

		//Sobelフィルタ
		int x[3] = { 1, 2, 1 };
		int y[3] = { -1, 0, 1 };

//輝度とDepthバッファによるアウトライン
#if 1

				//数値微分（Sobelフィルタによる畳み込み）によって深度差および輝度差を求める
				for (int i = 0; i < 3; i++)
					for (int j = 0; j < 3; j++)
					{

						diff = tex2D(_CameraDepthTexture, img.uv + float2(i - 1, j - 1) / _Sharpness) * 1 / (1 + exp(depth - 50));
						depX += x[i] * y[j] * diff;
						depY += x[j] * y[i] * diff;

						if(depth > _MaxDepth){
							dCol = tex2D(_MainTex, img.uv + float2(i - 1, j - 1) / _Sharpness);
							lumX += x[i] * y[j] * Luminance(dCol.rgb);
							lumY += x[j] * y[i] * Luminance(dCol.rgb);
						}
					}

				//輝度差のノルムが閾値を超えたとき、輪郭として塗る
				if (sqrt(depX * depX + depY * depY) > _ThresholdDep || sqrt(lumX * lumX + lumY * lumY) > _ThresholdLum)
				{
					c = lerp(_OutlineColor, c, _Alpha);
				}
#endif

		return c;
	}

		ENDCG
	}
	}
}
/*
#if 0	
		//数値微分（Sobelフィルタによる畳み込み）によって深度差を求める
		for (int i = 0; i < 3; i++)
			for (int j = 0; j < 3; j++)
			{

				diff = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, img.uv + float2(i - 1, j - 1) / _Sharpness));
				depX += x[i] * y[j] * diff;
				depY += x[j] * y[i] * diff;
		}

		//輝度差のノルムが閾値を超えたとき、輪郭として塗る
		if (sqrt(depX * depX + depY * depY) > _ThresholdDep)
		{
			c = lerp(_OutlineColor, c, _Alpha);
		}
#endif*/