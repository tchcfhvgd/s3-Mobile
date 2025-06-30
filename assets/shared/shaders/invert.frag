#pragma header

uniform float u_mix;

void main()
{

    vec4 tex = flixel_texture2D(bitmap,openfl_TextureCoordv);

    vec3 invertedTex = vec3(1.0) - flixel_texture2D(bitmap,openfl_TextureCoordv).rgb;

    tex.rgb = mix(tex.rgb, invertedTex, u_mix);

    gl_FragColor = tex;
}