Shader "Hidden/InkPaintEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
				//ガウシアンフィルタで全体をぼやけさせる
		Pass
		{
			CGPROGRAM

			#include "UnityCG.cginc"
			#pragma vertex vert_img
			#pragma fragment frag_gaus

			sampler2D _MainTex;//現在カメラにレンダリングされたテクスチャ

			int _Pixel;//ガウシアンフィルタの探索ピクセル数
			float _Variance;//ガウシアンフィルタの分散
			float _Sharpness;//ガウシアンフィルタの鋭さ(謎)

			float gaussian(float2 pos, const float var)
			{
				return exp(-(pos.x*pos.x + pos.y*pos.y) / 2 / var/var ) / 2 / 3.141592 / var/var;
			}

			fixed4 frag_gaus(v2f_img img) : COLOR
			{
				fixed4 c = (fixed4)0;
				int halfPix = _Pixel/2;

				for(int i = -halfPix; i <= halfPix; i++){
					for(int j = -halfPix; j <= halfPix; j++){
						float2 pos = float2(i, j);
						float2 pixel = pos / _Sharpness;
						c += tex2D(_MainTex, img.uv + pixel) * gaussian(pos, _Variance) * _Variance;//暗かったため_Varianceをかけてみた
					}
				}

				return c;
			}

			ENDCG
		}

		//アウトラインを付与する
		Pass
		{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert_img
			#pragma fragment frag_outline

			sampler2D _CameraDepthTexture;
			sampler2D _MainTex;//現在カメラにレンダリングされたテクスチャ
			float _ThresholdDep;//アウトラインを判断する閾値
			float _ThresholdLum;//アウトラインを判断する閾値
			float _MaxDepth; //これ以上深度の深いものは詳細なアウトラインを付与しない
			float _Alpha;//色の不透明度
			fixed4 _OutlineColor;//アウトラインの基準色
			float _Sharpness;//アウトラインの鋭さ

			fixed2 random2(fixed2 st)
			{
        		st = fixed2( dot(st,fixed2(127.1,311.7)),
                     		 dot(st,fixed2(269.5,183.3)) );
        		return -1.0 + 2.0*frac(sin(st)*43758.5453123);
   			}	

			float perlinNoise(fixed2 st) 
			{
				fixed2 p = floor(st);
				fixed2 f = frac(st);
				fixed2 u = f*f*(3.0-2.0*f);

				float v00 = random2(p+fixed2(0,0));
				float v10 = random2(p+fixed2(1,0));
				float v01 = random2(p+fixed2(0,1));
				float v11 = random2(p+fixed2(1,1));

				return lerp( lerp( dot( v00, f - fixed2(0,0) ), dot( v10, f - fixed2(1,0) ), u.x ),
							lerp( dot( v01, f - fixed2(0,1) ), dot( v11, f - fixed2(1,1) ), u.x ), 
							u.y)+0.5f;
			}


			fixed4 frag_outline(v2f_img img) : COLOR
			{
				fixed4 c = tex2D(_MainTex, img.uv);
				float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, img.uv));

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
				//数値微分（Sobelフィルタによる畳み込み）によって深度差および輝度差を求める
				for (int i = 0; i < 3; i++)
					for (int j = 0; j < 3; j++)
					{
						float2 pos = float2(i - 1, j - 1);
						float2 pixel = pos / _Sharpness;

						diff = tex2D(_CameraDepthTexture, img.uv + pixel) * 1 / (1 + exp(depth - 50));
						depX += x[i] * y[j] * diff;
						depY += x[j] * y[i] * diff;

						if(depth > _MaxDepth){
							dCol = tex2D(_MainTex, img.uv + pixel);
							lumX += x[i] * y[j] * Luminance(dCol.rgb);
							lumY += x[j] * y[i] * Luminance(dCol.rgb);
						}
					}

				//輝度差のノルムが閾値を超えたとき、輪郭として塗る
				if (sqrt(depX * depX + depY * depY) > _ThresholdDep || sqrt(lumX * lumX + lumY * lumY) > _ThresholdLum)
				{
					c = lerp(_OutlineColor, c, _Alpha * (1-depth)) + (fixed4) perlinNoise(img.uv * 50) * 0.4;//ノイズを付与してそれっぽく
				}

				return c ;
			}

			ENDCG
		}
	}
}
