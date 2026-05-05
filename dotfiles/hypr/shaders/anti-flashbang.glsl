precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    // Reduce luminance of very bright areas to ease eye strain
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    if (luma > 0.85) {
        color.rgb *= 0.85 / luma;
    }
    gl_FragColor = color;
}
