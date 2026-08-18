#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    float bassEnergy;
    float trebleEnergy;
    float noiseTime;
    float sphereRadius;
    float feather;
    float radiusAudioMultiplier;
    float noiseFrequency;
    float noiseAmplitude;
    vec4 colorNear;
    vec4 colorFar;
};

float hash13(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float valueNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n000 = hash13(i + vec3(0.0, 0.0, 0.0));
    float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
    float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
    float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
    float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
    float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
    float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
    float n111 = hash13(i + vec3(1.0, 1.0, 1.0));

    float nx00 = mix(n000, n100, f.x);
    float nx10 = mix(n010, n110, f.x);
    float nx01 = mix(n001, n101, f.x);
    float nx11 = mix(n011, n111, f.x);

    float nxy0 = mix(nx00, nx10, f.y);
    float nxy1 = mix(nx01, nx11, f.y);

    return mix(nxy0, nxy1, f.z) * 2.0 - 1.0;
}

// 3-octave fractional brownian motion, GLSL counterpart of the CPU Perlin
// noise the v1 particle build used
float fbm3(vec3 p) {
    float sum = 0.0;
    float amp = 0.5;
    float freq = 1.0;
    for (int i = 0; i < 3; i++) {
        sum += amp * valueNoise3D(p * freq);
        amp *= 0.5;
        freq *= 2.0;
    }
    return sum;
}

// Signed distance to the noise-displaced, audio-reactive sphere surface
float sphereSDF(vec3 p) {
    float n = fbm3(normalize(p) * noiseFrequency + vec3(noiseTime));
    float radius = sphereRadius + radiusAudioMultiplier * bassEnergy + noiseAmplitude * trebleEnergy * n;
    return length(p) - radius;
}

vec3 calcNormal(vec3 p) {
    float maxExtent = max(sphereRadius, 1.0);
    vec2 e = vec2(0.001, 0.0) * maxExtent;
    return normalize(vec3(
        sphereSDF(p + e.xyy) - sphereSDF(p - e.xyy),
        sphereSDF(p + e.yxy) - sphereSDF(p - e.yxy),
        sphereSDF(p + e.yyx) - sphereSDF(p - e.yyx)
    ));
}

void main() {
    vec2 centered = qt_TexCoord0 * resolution - 0.5 * resolution;
    float maxExtent = sphereRadius + radiusAudioMultiplier + noiseAmplitude;
    float camDist = maxExtent * 3.0 + 10.0;

    vec3 ro = vec3(centered, -camDist);
    vec3 rd = vec3(0.0, 0.0, 1.0);

    float t = 0.0;
    bool hit = false;
    vec3 hitPos = vec3(0.0);

    for (int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        float d = sphereSDF(p);
        if (d < 0.5) {
            hit = true;
            hitPos = p;
            break;
        }
        t += max(d * 0.5, 0.5);
        if (t > camDist * 2.0)
            break;
    }

    if (!hit) {
        fragColor = vec4(0.0);
        return;
    }

    vec3 n = calcNormal(hitPos);
    vec3 lightDir = normalize(vec3(0.4, 0.6, -1.0));
    float diffuse = clamp(dot(n, lightDir), 0.0, 1.0);
    float rim = 1.0 - clamp(dot(n, -rd), 0.0, 1.0);

    float depthT = clamp((hitPos.z / max(maxExtent, 1.0) + 1.0) * 0.5, 0.0, 1.0);
    vec4 baseColor = mix(colorNear, colorFar, depthT);

    float edgeFade = 1.0 - smoothstep(1.0 - clamp(feather, 0.01, 1.0), 1.0, rim);
    float brightness = 0.35 + 0.65 * diffuse + 0.3 * rim;

    fragColor = vec4(baseColor.rgb * brightness, baseColor.a * edgeFade) * qt_Opacity;
}
