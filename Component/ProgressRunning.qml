import QtQuick 2.15

Rectangle {
    id: gasolineIndicator
    width: 200
    height: 17
    radius: 9
    layer.enabled: true
    layer.samplerName: "fuelShader"
    layer.effect: ShaderEffect {
        id: fuelShaderMask
        property variant v;
        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            UniformAnimator {
                target: fuelShaderMask
                uniform: "v"
                from: 0
                to: 0.9
                duration: 15000
            }
            UniformAnimator {
                target: fuelShaderMask
                uniform: "v"
                from: 0.9
                to: 0
                duration: 15000
            }
        }
        fragmentShader: "
             uniform lowp sampler2D fuelShader;
             uniform lowp float qt_Opacity;
             varying highp vec2 qt_TexCoord0;
             uniform lowp float v;

             void main() {

                //Background gradient
                const lowp vec3 c1 = vec3(0.902,0.545,0.11);
                const lowp vec3 c2 = vec3(0.247,0.78,0.871);
                lowp vec3 bg = mix(c1,c2, qt_TexCoord0.x);

                //Animated ramp
                lowp float s = smoothstep(0.99 - v, 1.01 - v,  qt_TexCoord0.x);
                lowp vec3 ramp = vec3(s);
                lowp vec4 color = vec4(bg + ramp, 1.0);

                gl_FragColor = color * texture2D(fuelShader, qt_TexCoord0).a * qt_Opacity;
             }
         "
    }
}

