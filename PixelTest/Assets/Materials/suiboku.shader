// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/suiboku"
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
			float _MaxDepth;//アウトラインの詳細を付与する深度
			float _Alpha;//色の不透明度
			fixed4 _OutlineColor;//アウトラインの基準色
			float _OutlineSharpness;//アウトラインの鋭さ
	
			int _GausRadius;//ガウシアンフィルタの探索ピクセル数
			float _Variance;//ガウシアンフィルタの分散 
			float _GausResolution;//ガウシアンフィルタの鋭さ

			float _Intensity;

			float gaussian(float2 pos, const float var)
			{
				return exp(-(pos.x*pos.x + pos.y*pos.y) / 2 / var/var ) / 2 / 3.141592 / var/var;
			}

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


			fixed4 frag(v2f_img img) : COLOR
			{
				float2 outline_size = float2(_OutlineSharpness / _ScreenParams.x, _OutlineSharpness / _ScreenParams.y);
				float2 gaus_size = float2(_GausResolution / _ScreenParams.x, _GausResolution / _ScreenParams.y);


				fixed4 c = tex2D(_MainTex, img.uv);//(fixed4)0;
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

				float2 pixel;

				float2 pos;

				//輝度とDepthバッファによるアウトライン
				//数値微分（Sobelフィルタによる畳み込み）によって深度差および輝度差を求める
				//縦横に分ければ高速化できそうだけど、カーネルが小さいのであまり意味なさそう
				for (int i = 0; i < 3; i++)
				{
					for (int j = 0; j < 3; j++)
					{
						pixel = float2(i - 1, j - 1) * outline_size;

						diff = tex2D(_CameraDepthTexture, img.uv + pixel);
						depX += x[i] * y[j] * diff;
						depY += x[j] * y[i] * diff;



						if(depth > _MaxDepth){
							dCol = tex2D(_MainTex, img.uv + pixel);
							lumX += x[i] * y[j] * Luminance(dCol.rgb);
							lumY += x[j] * y[i] * Luminance(dCol.rgb);
						}
					}
				}

				//TODO:高速化 http://imagingsolution.blog.fc2.com/blog-entry-156.html
				[loop]
				for(int k = -_GausRadius; k <= _GausRadius; k++)
				{
					[loop]
					for(int l = -_GausRadius; l <= _GausRadius; l++)
					{
						pos = float2(k, l);
						pixel = pos * gaus_size;
						
						//同時にガウシアンフィルタを施して画面をぼやけさせる
						c += tex2D(_MainTex, img.uv + pixel) * gaussian(pos, _Variance) * _Variance;		
					}
				}


				c = lerp(c, Luminance(c), _Intensity);

				//輝度差のノルムが閾値を超えたとき、輪郭として塗る
				if (sqrt(depX * depX + depY * depY) > _ThresholdDep || sqrt(lumX * lumX + lumY * lumY) > _ThresholdLum)
				{
					return lerp(_OutlineColor, c, _Alpha * (perlinNoise(img.uv * 50) + 0.5)/2);
				} 
	
				return c;
			}
			ENDCG
		}

        // 1パス目の描画結果をテクスチャとして渡す
        GrabPass{}

		//斜め下方向へのストローク表現 https://github.com/QianMo/Awesome-Unity-Shader/blob/master/Volume%2010%20%E5%B1%8F%E5%B9%95%E6%B2%B9%E7%94%BB%E7%89%B9%E6%95%88Shader/ScreenOilPaintEffect/ScreenOilPaintEffect.shader
		//ざらざら感を減らしたい
		Pass
		{
			CGPROGRAM
			
			#include "UnityCG.cginc"

			#define MAX_PIXEL 10

			#pragma vertex vert
			#pragma fragment frag

			sampler2D _GrabTexture;
			float _EdgePreserveResolution;
			int _EdgePreserveRadius;

			v2f_img vert( appdata_img v )
			{
				v2f_img o;
				o.pos = UnityObjectToClipPos (v.vertex);
				o.uv = ComputeGrabScreenPos(o.pos);//こうしないと画像が反転してしまう
				return o;
			}

			fixed4 frag(v2f_img img) : COLOR
			{
				float2 src_size = float2(_EdgePreserveResolution / _ScreenParams.x, _EdgePreserveResolution / _ScreenParams.y);

				float n = float((_EdgePreserveRadius + 1) * (_EdgePreserveRadius + 1));

				fixed3 m0 = 0;  fixed3 m1 = 0.0;
				fixed3 s0 = 0;  fixed3 s1 = 0.0;
				fixed3 c;

				for (int i = 0; i <= _EdgePreserveRadius; i++)
				{
					for (int j = 0; j <= _EdgePreserveRadius; j++)
					{
						c = tex2D(_GrabTexture, img.uv + float2(i - _EdgePreserveRadius, j) * src_size).rgb; 
						m0 += c; 
						s0 += c * c;

						c = tex2D(_GrabTexture, img.uv + float2(i, j - _EdgePreserveRadius) * src_size).rgb; 
						m1 += c;
						s1 += c * c;
					}
				}

				fixed4 finalCol = 0;
				float min_sigma2 = 1e+2;

				m0 /= n;
				s0 = abs(s0 / n - m0 * m0);

				float sigma2 = s0.r + s0.g + s0.b;
				if (sigma2 < min_sigma2) 
				{
					min_sigma2 = sigma2;
					finalCol = fixed4(m0, 1);
				}

				m1 /= n;
				s1 = abs(s1 / n - m1 * m1);

				sigma2 = s1.r + s1.g + s1.b;
				if (sigma2 < min_sigma2) 
				{
					min_sigma2 = sigma2;
					finalCol = fixed4(m1, 1);
				}

				return finalCol;
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

				diff = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, img.uv + float2(i - 1, j - 1) / _OutlineSharpness));
				depX += x[i] * y[j] * diff;			float _Gausian
				depY += x[j] * y[i] * diff;
		}

		//輝度差のノルムが閾値を超えたとき、輪郭として塗る
		if (sqrt(depX * depX + depY * depY) > _ThresholdDep)
		{
			c = lerp(_OutlineColor, c, _Alpha);
		}
#endif

			fixed4 frag(v2f_img img) : COLOR
			{
				int _GausRadius = (int)(_MedianPixel/2);
				float2 pixel;

				fixed4 medianColsX[MAX_PIXEL];
				fixed medianlumsX[MAX_PIXEL];

				fixed4 col;
				fixed lum;
				fixed4 cols[MAX_PIXEL];
				fixed lums[MAX_PIXEL];

				//横方向の中央値を見つける
				for(int i = 0; i < _MedianPixel; i++)
				{
					for(int j = -_GausRadius; j < _GausRadius; i++)
					{
						pixel = float2(j, 0) / _MedianSharpness;
						cols[j] = tex2D(_MainTex, img.uv + pixel);
						lums[j] = Luminance(cols[j]);
						col = cols[j];
						lum = lums[j];

						//ソートしながら挿入する
						for(int k = 0; k < j; k++)
						{
							if(lum < lums[k])
							{
								for(int l = j; l > k; l--)
								{
									cols[l] = cols[l-1];
									lums[l] = lums[l-1];
								}
								cols[k] = col; 
								lums[k] = lum;
								
								break;
							}
						}
					}

					medianColsX[i] = cols[_GausRadius];
					medianlumsX[i] = lums[_GausRadius];
					col = cols[_GausRadius];
					lum = lums[_GausRadius];

					//ソートしながら挿入する
					for(int m = 0; m < i; m++)
					{
						if(lum < medianlumsX[m])
						{
							for(int n = i; n > m; n--)
							{
								medianColsX[n] = medianColsX[n-1];
								medianlumsX[n] = medianlumsX[n-1];
							}
							medianColsX[m] = col; 
							medianlumsX[m] = lum;
								
							break;
						}
					}
				}
				


				return medianColsX[_GausRadius];
			}	

*/