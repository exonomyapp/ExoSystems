#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_time;
uniform vec4 u_color;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / u_size;
    vec2 center = vec2(0.5, 0.5);
    
    // Calculate distance from center for a circle
    float dist = distance(uv, center);
    
    // 2-second breathing cycle (0.5 Hz)
    float pulse = (sin(u_time * 3.14159) + 1.0) / 2.0; 
    
    // Anti-aliased circle with soft edge for glow
    float circle = smoothstep(0.5, 0.2, dist);
    
    // Opacity interpolates between 0.4 and 1.0 based on pulse
    float alpha = circle * (0.4 + (pulse * 0.6));
    
    // Premultiplied alpha for correct blending
    fragColor = vec4(u_color.rgb * alpha, u_color.a * alpha);
}
