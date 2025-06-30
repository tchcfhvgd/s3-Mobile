#pragma header

uniform float u_mix;

void main()
{
    vec4 tex = flixel_texture2D(bitmap,openfl_TextureCoordv);

    float grayscaleValue = dot(tex.xyz, vec3(0.2126, 0.7152, 0.0722));

    //hardcoded threshold lol
    tex.rgb = grayscaleValue > 0.2 ? vec3(1.0, 0.0, 0.0) : vec3(0.0);

    vec4 ogTex = flixel_texture2D(bitmap,openfl_TextureCoordv);

    ogTex = mix(ogTex,tex,u_mix);


    gl_FragColor = ogTex;
}