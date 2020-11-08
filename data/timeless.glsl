precision highp float;

#define RAYMARCH_MAX_STEPS 100
#define RAYMARCH_MAX_DIST 100.
#define RAYMARCH_SURFACE_DIST .001
#define SPEED 1.0
#define ROTSPEED 0.25
#define CAMDIST 4.0
#define color vec3(1.0, 0.2, 0.2)
#define iTime mod(time, 60.0)
#define PI 3.14159265359
#define HALF_PI 1.57079632679
#define QUARTER_PI 0.78539816339

#define SDG sdGyroid

uniform float time;
uniform vec2 resolution;
uniform bool depth;

vec3 randomVector(vec3 p) {
	vec3 a = fract(p.xyz*vec3(123.34, 234.34, 345.65));
    a += dot(a, a+34.45);
    vec3 v = fract(vec3(a.x*a.y, a.y*a.z, a.z*a.x));
    return v;
}

vec3 lpos1 = vec3(0.0, 0.0, 2.9457);
vec3 lpos2 = vec3(0.0, 0.0, 4.8569);
vec3 lpos3 = vec3(0.0, 0.0, 6.7142);
float light1 = 0.0;
float light2 = 0.0;
float light3 = 0.0;

vec3 lposGlobal = vec3(0.0, 0.0, 30.0);
float lightGlobal = 0.0;

float cameraMovement = 0.0;

float beamsShine = 0.0;
float tmpo = 0.0;

mat2 rotate(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

// This creates repetitions of something along the way
vec3 repeat(vec3 p, vec3 s) {
	return (fract(p/s - 0.5) - 0.5) * s;
}

vec2 repeat(vec2 p, vec2 s) {
	return (fract(p/s - 0.5) - 0.5) * s;
}

float repeat(float p, float s) {
	return (fract(p/s - 0.5) - 0.5) * s;
}

float sdCylinder(vec2 p, float r) {
    return length(p) - r;
}

vec3 tunnel(vec3 p) {
		vec3 off = vec3(0.0);
  	float dd = (p.z * 0.01) ;
		dd = floor(dd*1.0) + smoothstep(0.0, 1.0, smoothstep(0.0, 1.0, fract(dd*1.0)));
    dd *= 20.1;
    dd += iTime*0.1;
  	off.x += sin(dd) * 6.0;
  	off.y = sin(dd * 0.7) * 6.0;
  	return off;
}

vec3 navigate(vec3 p) {
  p += tunnel(p);
  p.xy *= rotate((p.z * ROTSPEED) + (iTime*ROTSPEED));
  p.y -= 0.3;
  return p;
}
float Hash21(vec2 p) {
    p = fract(p*vec2(123.34,233.53));
    p += dot(p, p+23.234);
    return fract(p.x*p.y);
}

float sdBox(vec3 p, vec3 s) {
    p = abs(p)-s;
	return length(max(p, 0.))+min(max(p.x, max(p.y, p.z)), 0.);
}

float sdGyroid(vec3 p, float scale, float thickness, float bias, float lx, float ly) {
  vec3 p2 = p;
  p2 *= scale;
  float ls = max(lx, ly)*1.6;
  float gyroid = abs(dot(sin(p2*lx), cos(p2.zxy*ly))-bias) / (scale*ls) - thickness;
  return gyroid;
}

float smin(float a, float b, float h) {
	float k = clamp((a-b) / h * 0.5 + 0.5, 0.0, 1.0);
	return mix(a, b, k) - k * (1.0 - k) * h;
}

float getDist(vec3 p) {
  vec3 p2 = p;
  p2 = navigate(p2);

  float box = sdBox(p2, vec3(0.0));

  float lz = fract((p.z/100.0) * 0.02);
  float t = iTime*0.5;
  float lx = 1.25 + ((sin((lz+t) * 0.2576) * 0.5) + 0.5) * 0.25;
  float ly = 1.25 + ((cos((lz+t) * 0.1987) * 0.5) + 0.5) * 0.25;
  float g1 = sdGyroid(p2, 0.543, 0.1, 1.4, lx, ly);

  float g2 = sdGyroid(p2, 10.756, 0.03, 0.3, 1.0, 2.0);
  float g3 = sdGyroid(p2, 20.765, 0.03, 0.3, 1.0, 1.0);
  float g4 = sdGyroid(p2, 40.765, 0.03, 0.3, 1.0, 1.0);
  float g5 = sdGyroid(p2, 60.765, 0.03, 0.3, 1.0, 1.0);
  float g6 = sdGyroid(p2, 120.765, 0.03, 0.3, 1.0, 1.0);

  g1 -= g2*0.4;
  g1 -= g3*0.3;
  g1 -= g4*0.2;
  g1 -= g5*0.2;
  g1 += g6*0.1;

  float d = g1*0.6;

  float dl1 = length(lpos1 - p) - 0.1;
	light1 += 0.02/(0.01+dl1);
	d = smin(d, dl1, 0.5*2.0);
  float dl2 = length(lpos2 - p) - 0.1;
	light2 += 0.02/(0.01+dl2);
	d = smin(d, dl2, 0.5*2.0);
  float dl3 = length(lpos3 - p) - 0.1;
	light3 += 0.02/(0.01+dl3);
	d = smin(d, dl3, 0.5*2.0);

	// Beams
	vec3 p4 = p2;
	p4.xy *= rotate(p4.z * 0.05);
	p4.z = repeat(p4.z, 10.0);
	p4.x += sin(p4.y*0.3 + p2.z * 0.08 + iTime * 0.5) * 2.0;
	float beams = sdCylinder(p4.xz, 0.5);
	beams -= g2*0.4;
  beams -= g3*0.3;
  beams -= g4*0.2;
  beams -= g5*0.2;
  beams += g6*0.1;
	beams *= 0.8;
	d = smin(d, beams, 1.0);

  return d;
}

float rayMarch(vec3 ro, vec3 rd) {
	float dO = RAYMARCH_SURFACE_DIST;

    for (int i = 0; i < RAYMARCH_MAX_STEPS; i++) {
			vec3 p = ro + rd * dO;
      float dS = getDist(p);
      dO += dS;
      if (dO > RAYMARCH_MAX_DIST || dS < RAYMARCH_SURFACE_DIST) break;
    }

    return dO;
}

vec3 getNormal(vec3 p) {
	float d = getDist(p);
    vec2 e = vec2(0.01, 0.0);

    vec3 n = d - vec3(
        getDist(p - e.xyy),
        getDist(p - e.yxy),
        getDist(p - e.yyx));

    return normalize(n);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}

vec3 farColor(vec3 rd) {
  vec3 col = vec3(0.0);
  float y = rd.y * 0.5 + 0.5;
  return color * 0.1;
}

float getLight(vec3 p, vec3 lpos) {
    vec3 l = normalize(lpos - p);
    vec3 n = getNormal(p);

    float dif = dot(n, l);

    return dif;
}

vec3 calcLight(vec3 lp) {
  vec3 lp2 = randomVector(lp);
  float lpr = lpos2.z;
  float lpRotation = lp2.z + iTime * 0.5;
  lp2.x = sin(lpRotation);
  lp2.y = cos(lpRotation);
  lp2.z = -CAMDIST+2.0 + (sin((lpr + iTime)*0.25) * 0.5 + 0.5) * 4.0;
  lp2.z += cameraMovement;
  lp2 -= tunnel(lp2);
  return lp2;
}

void main() {

  vec2 uv = (gl_FragCoord.xy-.5 * resolution.xy) / resolution.y;

  vec3 col = vec3(0.0);

  float t = iTime * SPEED;
  cameraMovement = t;

  vec3 ro = vec3(0.0, 0.0, -CAMDIST);
  ro.z += cameraMovement;
  ro -= tunnel(ro);
  vec3 ta = vec3(0.0);
  ta.z += cameraMovement;
  ta -= tunnel(ta);

  vec3 ww = normalize(ta - ro);
  vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
  vec3 vv = normalize(cross(uu, ww));

  float fov = 1.0;
  vec3 rd = normalize(uv.x * uu + uv.y * vv + ww * fov);

  float lr = iTime * 0.5;
  lpos1.x = sin(lr);
  lpos1.y = cos(lr);
  lpos1.z = -CAMDIST+2.0 + (sin(iTime*0.25) * 0.5 + 0.5) * 8.0;
  lpos1.z += cameraMovement;
  lpos1 -= tunnel(lpos1);

  lpos2 = calcLight(lpos2);
  lpos3 = calcLight(lpos3);

  float d = rayMarch(ro, rd);

  if(d<RAYMARCH_MAX_DIST) {
  	vec3 p = ro + rd * d;
  	vec3 n = getNormal(p);

		if (!depth) {
			float dif1 = clamp(getLight(p, lpos1), 0.0, 1.0);
	  	col = vec3(dif1)*normalize(pow(color, vec3(0.585)));
			float dif2 = clamp(getLight(p, lpos2), 0.0, 1.0);
	  	col = vec3(dif2)*normalize(pow(color, vec3(0.585)));
			float dif3 = clamp(getLight(p, lpos3), 0.0, 1.0);
	  	col = vec3(dif3)*normalize(pow(color, vec3(0.585)));
		}

    p = navigate(p);

    if (!depth) {
			float g2 = SDG(p, 10.756, 0.03, 0.3, 1.0, 1.0);
	    col *= smoothstep(-0.1, 0.06, g2);

	    float cw = -0.04 + smoothstep(0.0, -0.5, n.y) * 0.08;
	    float sh = smoothstep(cw, -0.03, g2);

	    float pz = pow(p.z, 10.0/p.z);
	    float g3 = SDG(p+(iTime * 0.0000), 5.756, 0.03, 0.0, 1.0, 1.0);
	    float g4 = SDG(p-(iTime * 0.0000), 4.756, 0.03, 0.0, 1.0, 1.0);

	    sh *= g3 * g4 * 4.0 + 0.2 * smoothstep(0.2, 0.0, n.y);

	    col += sh * normalize(pow(color, vec3(0.5)))*20.0;
		}

  }

  float mindist = 3.0;
  float maxdist = 8.0;
  col = mix(col, farColor(rd), smoothstep(mindist, maxdist, d));

  if (!depth) {
		vec3 la1 = light1 * color;
	  vec3 la2 = light2 * color;
	  vec3 la3 = light3 * color;
		col += la1 + la2 + la3;

	  col = 1.0 - exp(-col * 3.0);
	  col = pow(col, vec3(1.6));

	} else {
		col = vec3(smoothstep(mindist+2.0, maxdist+2.0, d));
	}

  gl_FragColor = vec4(col, d);
}
