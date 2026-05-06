#version 300 es
precision mediump float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);
    // Reduce luminance of very bright areas to ease eye strain
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    if (luma > 0.85) {
        color.rgb *= 0.85 / luma;
    }
    fragColor = color;
}
