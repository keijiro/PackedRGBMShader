Shader "Unlit/Test"
{
    CGINCLUDE

    #include "UnityCG.cginc"

    half3 Hue2RGB(half h)
    {
        h = frac(saturate(h)) * 6 - 2;
        half3 rgb = saturate(half3(abs(h - 1) - 1, 2 - abs(h), 2 - abs(h - 2)));
    #ifndef UNITY_COLORSPACE_GAMMA
        rgb = GammaToLinearSpace(rgb);
    #endif
        return rgb;
    }

    #define MAX_BRIGHTNESS 12

    uint EncodeColor(half3 rgb)
    {
        half y = max(max(rgb.r, rgb.g), rgb.b);
        y = clamp(ceil(y * 255 / MAX_BRIGHTNESS), 1, 255);
        rgb *= 255 * 255 / (y * MAX_BRIGHTNESS);
        uint4 i = half4(rgb, y);
        return i.x | (i.y << 8) | (i.z << 16) | (i.w << 24);
    }

    half3 DecodeColor(uint data)
    {
        half r = (data      ) & 0xff;
        half g = (data >>  8) & 0xff;
        half b = (data >> 16) & 0xff;
        half a = (data >> 24) & 0xff;
        return half3(r, g, b) * a * MAX_BRIGHTNESS / (255 * 255);
    }

    ENDCG

	SubShader
	{
		Tags { "RenderType"="Opaque" }
		Pass
		{
			CGPROGRAM

			#pragma vertex Vertex
			#pragma fragment Fragment
            #pragma multi_compile _ UNITY_COLORSPACE_GAMMA

            struct Attributes
            {
                float4 position : POSITION;
                float2 texcoord : TEXCOORD;
            };

            struct Varyings
            {
                float4 position : SV_POSITION;
                float2 texcoord : TEXCOORD;
            };
			
			Varyings Vertex(Attributes input)
			{
				Varyings o;
				o.position = UnityObjectToClipPos(input.position);
                o.texcoord = input.texcoord;
				return o;
			}
			
			half4 Fragment(Varyings input) : SV_TARGET
			{
                float x = input.texcoord.x * 3;
                float y = input.texcoord.y * 3.99 + 0.01;

                half3 c1 = Hue2RGB(frac(x) / 0.98 - 0.01) * y;
                half3 c2 = DecodeColor(EncodeColor(c1));

                if (frac(x + 0.01) < 0.02)
                    return 0; // borders
                else if (x < 1)
                    return half4(c1, 1); // source
                else if (x < 2)
                    return half4(c2, 1); // coded
                else
                    return length(c2 - c1) / length(c1) * 100; // rel error
			}

			ENDCG
		}
	}
}
