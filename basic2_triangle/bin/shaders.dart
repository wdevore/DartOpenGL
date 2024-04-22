final gVertexShaderSource = '#version 400 core'
    '\n'
    'layout (location = 0) in vec3 aPos;'
    '\n'
    'void main()'
    '\n'
    '{'
    '\n'
    '    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);'
    '\n'
    '}';

final gFragmentShaderSource = '#version 400 core'
    '\n'
    'out vec4 fFragColor;'
    '\n'
    'void main()'
    '\n'
    '{'
    '\n'
    '    fFragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);'
    '\n'
    '}';
