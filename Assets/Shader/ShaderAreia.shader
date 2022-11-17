Shader "Unlit/ShaderAreia"
{
	Properties{
		//Properties
	}
	SubShader
	{
	Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
	Pass
	{
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha
	CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"
	struct VertexInput
	{
	fixed4 vertex : POSITION;
	fixed2 uv : TEXCOORD0;
	fixed4 tangent : TANGENT;
	fixed3 normal : NORMAL;
	//VertexInput
	};
	struct VertexOutput
	{
	fixed4 pos : SV_POSITION;
	fixed2 uv : TEXCOORD0;
	//VertexOutput
	};
	//Variables
	////////////////////////////////
	// Terrain generation section //
	////////////////////////////////
	fixed snoise(fixed2 p)
	{
	fixed2 f = frac(p);
	p = floor(p);
	fixed v = p.x + p.y * 1000.0;
	fixed4 r = fixed4(v, v + 1.0, v + 1000.0, v + 1001.0);
	r = frac(100000.0 * sin(r * .001));
	f = f * f * (3.0 - 2.0 * f);
	return 2.0 * (lerp(lerp(r.x, r.y, f.x), lerp(r.z, r.w, f.x), f.y)) - 1.0;
	}
	fixed noise(in fixed2 uv)
	{
	return sin(uv.x) + cos(uv.y);
	}
	fixed terrain(in fixed2 uv,int octaves)
	{
	fixed value = 0.;
	fixed amplitude = 2. / 3.;
	fixed freq = .5;
	fixed n1 = 0.;
	for (int i = 0; i < octaves; i++)
	{
	n1 = (noise((uv)*freq) - n1);
	value = (value + n1 * amplitude);
	freq *= 2. - amplitude;
	amplitude *= 1. / 3.;
	uv = uv.yx - n1 / freq;
	}
	return value;
	}
	fixed2 map(fixed3 p, int octaves)
	{
	fixed dMin = 28.0;
	fixed d;
	fixed mID = -1.0;
	// Mountains
	fixed h = terrain(p.xz, octaves);
	d = p.y - h;
	if (d < dMin)
	{
	dMin = d;
	mID = 0.0;
	}
	return fixed2(dMin, mID);
	}
	////////////////////
	// Render section //
	////////////////////
	fixed2 castRay(fixed3 ro, fixed3 rd, int octaves)
	{
	const fixed p = 0.001;
	fixed t = 0.0;
	fixed h = p * 2.0;
	fixed m = -1.0;
	for (int i = 0; i < 36; i++)
	{
	if (abs(h) <= p || t >= 28.0) break;
	t += h;
	fixed2 res = map(ro + rd * t, octaves);
	h = res.x;
	m = res.y;
	}
	if (t > 28.0) m = -1.0;
	return fixed2(t, m);
	}
	fixed3 calcNormal(fixed3 p, int octaves)
	{
	const fixed3 eps = fixed3(0.002, 0.0, 0.0);
	return normalize(fixed3(map(p + eps.xyy, octaves).x - map(p - eps.xyy, octaves).x,
	 map(p + eps.yxy, octaves).x - map(p - eps.yxy, octaves).x,
	 map(p + eps.yyx, octaves).x - map(p - eps.yyx, octaves).x));
	}
	fixed shadows(fixed3 ro, fixed3 rd, fixed tMax, fixed k, int octaves)
	{
	fixed res = 1.0;
	fixed t = 0.1;
	[unroll(100)]
	for (int i = 0; i < 22; i++)
	{
	if (t >= tMax) break;
	fixed h = map(ro + rd * t, octaves).x;
	res = min(res, k * h / t);
	t += h;
	}
	return clamp(res, 0.2, 1.0);
	}
	fixed3 render(fixed3 ro, fixed3 rd)
	{
	const int geoLOD = 4;
	fixed2 res = castRay(ro, rd, geoLOD);
	fixed3 lPos = normalize(fixed3(1.0, 0.5, 0.0));
	fixed3 lCol = fixed3(1.0, 0.9, 0.8);
	fixed3 pos = ro + rd * res.x;
	fixed3 color = fixed3(0.45,0.5,0.6);
	fixed sun = clamp(dot(rd,lPos),0.0,1.0);
	color += 0.6 * lCol * sun * sun;
	if (res.y < -0.5)
	{
	return color;
	}
	fixed3 skyColor = color;
	int norLOD = int(max(2.0, 12.0 - 11.0 * res.x / 28.0));
	fixed3 nor = calcNormal(pos, norLOD);
	// mat 0 = Rock / mountain
	if (res.y > -0.5 && res.y < 0.5) {
		// Base rock
		color = lerp(fixed3(0.4, 0.1, 0.0), fixed3(0.7, 0.6, 0.3), step(0.9, nor.y));
		// Layer noise
		fixed n = 0.5 * (snoise(pos.xy * fixed2(2.0, 15.0)) + 1.0);
		color = lerp(fixed3(0.6, 0.5, 0.4), color, n * smoothstep(0.0, 0.7, 1.0 - nor.y));
		// Sand on top
		color = lerp(color, fixed3(0.7, 0.6, 0.3), smoothstep(0.0, 0.2, nor.y - 0.8));
		}
	// mat 1 = Sand
	if (res.y > 0.5)
	{
		// Base sand and rock color
		color = lerp(fixed3(0.3, 0.2, 0.0), fixed3(0.7, 0.6, 0.3), nor.y);
		}
	// Lighting and shadows
	fixed lAmb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0);
	fixed lDif = clamp(dot(nor, lPos), 0.0, 2.0);
	if (lDif > 0.05) lDif *= shadows(pos, lPos, 8.0, 12.0, geoLOD);
	color += (0.4 * lAmb) * lCol;
	color *= (1.8 * lDif) * lCol;
	// Fog
	fixed fog = exp(-0.003 * res.x * res.x);
	color = lerp(skyColor, color, fog);
	return color;
	}
	VertexOutput vert(VertexInput v)
	{
	VertexOutput o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	//VertexFactory
	return o;
	}
	fixed4 frag(VertexOutput i) : SV_Target
	{
	fixed2 pos = 2.0 * (i.uv / 1) - 1.0;
	pos.x *= 1 / 1;
	fixed t1 = _Time.y;
	// Camera
	fixed x = 0.0 + (0.5 * t1);
	fixed y = 0.0;
	fixed z = 0.0 + sin(0.1 * t1);
	fixed3 cPos = fixed3(x, y, z);
	cPos.y = terrain(cPos.xz, 1) + 2.5;
	const fixed3 cUp = fixed3(0., 1., 0.);
	fixed3 cLook = fixed3(cPos.x + 1.0, cPos.y * 0.85, 0.0);
	// Camera matrix
	fixed3 ww = normalize(cLook - cPos);
	fixed3 uu = normalize(cross(ww, cUp));
	fixed3 vv = normalize(cross(uu, ww));
	fixed3 rd = normalize(pos.x * uu + pos.y * vv + 2.0 * ww);
	// Render
	fixed3 color = render(cPos, rd);
	return fixed4(color, 1.0);
	}
	ENDCG
	}
	}
}