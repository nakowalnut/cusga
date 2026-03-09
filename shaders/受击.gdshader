shader_type canvas_item;

uniform float a : hint_range(0.0, 1.0) = 0.0; 
uniform vec4 c:source_color=vec4(1.0, 0.38, 0.031,1.0);
void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    COLOR = tex_color*(1.0-a)+c*a;
	COLOR.a=tex_color.a;
}