import 'dart:ffi';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:glew/glew.dart';
import 'package:glfw3/glfw3.dart';

import 'shaders.dart';

// settings
const gScrWidth = 800;
const gScrHeight = 600;

late Pointer<NativeFunction<Void Function()>> _glGetIntegerv;

int glGetIntegerv(int id) {
  Pointer<Int32> attribs = calloc<Int32>();
  final glGetIntegerv = _glGetIntegerv
      .cast<NativeFunction<Void Function(Uint32 id, Pointer<Int32> attribs)>>()
      .asFunction<void Function(int id, Pointer<Int32> attribs)>();
  glGetIntegerv(id, attribs);
  int attribsI = attribs.value;
  calloc.free(attribs);
  return attribsI;
}

int main(List<String> arguments) {
  // glfw: initialize and configure
  // ------------------------------
  if (glfwInit() != GLFW_TRUE) {
    return -1;
  }

  glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
  glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
  glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

  // --------------------
  // glfw window creation
  // --------------------
  var window = glfwCreateWindow(
      gScrWidth, gScrHeight, 'basic3_uniform', nullptr, nullptr);
  if (window == nullptr) {
    print('Failed to create GLFW window');
    glfwTerminate();
    return -1;
  }
  glfwMakeContextCurrent(window);
  glfwSetFramebufferSizeCallback(
      window, Pointer.fromFunction(framebufferSizeCallback));

  // --------------------
  // glad: load all OpenGL function pointers
  // ---------------------------------------
  gladLoadGLLoader(glfwGetProcAddress);

  _glGetIntegerv = glfwGetProcAddress('glGetIntegerv');

  int attribs = glGetIntegerv(GL_MAX_VERTEX_ATTRIBS);
  print('Max attributes allowed: $attribs');

  // ------------------------------------
  // build and compile our shader program
  // ------------------------------------
  // vertex shader
  var vertexShader = glCreateShader(GL_VERTEX_SHADER);
  gldtShaderSource(vertexShader, gVertexShaderSource);
  glCompileShader(vertexShader);
  if (gldtGetShaderiv(vertexShader, GL_COMPILE_STATUS) != GLFW_TRUE) {
    print('ERROR::SHADER::VERTEX::COMPILATIN_FALED');
    var bufSize = gldtGetShaderiv(vertexShader, GL_INFO_LOG_LENGTH);
    if (bufSize > 1) {
      print(gldtGetShaderInfoLog(vertexShader, bufSize));
    }
  }

  // fragment shader
  var fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
  gldtShaderSource(fragmentShader, gFragmentShaderSource);
  glCompileShader(fragmentShader);
  if (gldtGetShaderiv(fragmentShader, GL_COMPILE_STATUS) != GLFW_TRUE) {
    print('ERROR::SHADER::FRAGMENT::COMPILATION_FAILED');
    var bufSize = gldtGetShaderiv(fragmentShader, GL_INFO_LOG_LENGTH);
    if (bufSize > 1) {
      print(gldtGetShaderInfoLog(fragmentShader, bufSize));
    }
  }

  // link shaders
  var shaderProgram = glCreateProgram();
  glAttachShader(shaderProgram, vertexShader);
  glAttachShader(shaderProgram, fragmentShader);
  glLinkProgram(shaderProgram);
  // check for linking errors
  if (gldtGetProgramiv(shaderProgram, GL_LINK_STATUS) != GL_TRUE) {
    print('ERROR::SHADER::PROGRAM::LINKING_FAILED');
    var bufSize = gldtGetProgramiv(shaderProgram, GL_INFO_LOG_LENGTH);
    if (bufSize > 1) {
      print(gldtGetProgramInfoLog(shaderProgram, bufSize));
    }
  }

  glDeleteShader(vertexShader);
  glDeleteShader(fragmentShader);

  // ------------------------------------------------------------------
  // set up vertex data (and buffer(s)) and configure vertex attributes
  // ------------------------------------------------------------------
  // For simplicity these coords are defined in NDCs rather than using matrices.
  // -1 to 1 is the visible space.
  var vertices = [
    -0.5, -0.5, 0.0, // left
    0.5, -0.5, 0.0, // right
    0.0, 0.5, 0.0, // top
  ];

  var vao = gldtGenVertexArrays(1)[0];
  var vbo = gldtGenBuffers(1)[0];

  // bind the Vertex Array Object first, then bind and set vertex buffer(s),
  // and then configure vertex attributes(s).
  glBindVertexArray(vao);
  // 0. copy our vertices array in a buffer for OpenGL to use
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  gldtBufferFloat(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW); // glBufferData

  // ~~~~ VAO ~~~~
  // 1. then set the vertex attributes pointers
  // Parameters:
  // 1: Because we specified "layout (location = 0)" in the vertex shader
  //    we use "0" to match location 0
  // 2: The next argument specifies the size of the vertex attribute. The
  //    vertex attribute is a vec3 so it is composed of 3 values.
  // 3: The third argument specifies the type of the data which is GL_FLOAT
  // 4: The next argument specifies if we want the data to be normalized. If
  //    we're inputting integer data types (int, byte) and we've set this to
  //    GL_TRUE, the integer data is normalized to 0 (or -1 for signed data)
  //    and 1 when converted to float. This is not relevant for us so we'll
  //    leave this at GL_FALSE.
  // 5: The fifth argument is known as the stride and tells us the space between
  //    consecutive vertex attributes. Since the next set of position data is
  //    located exactly 3 times the size of a float away we specify that value
  //    as the stride.
  // 6: The last parameter is of type void* and thus requires that weird cast.
  //    This is the offset of where the position data begins in the buffer.
  //    Since the position data is at the start of the data array this value
  //    is just 0.
  gldtVertexAttribPointer(
      0, 3, GL_FLOAT, GL_FALSE, 3 * sizeOf<Float>(), 0 * sizeOf<Float>());

  // Parameters:
  // 1: Because we specified "layout (location = 0)" in the vertex shader
  //    we use "0" to match location 0
  glEnableVertexAttribArray(0);

  // ~~~~ VBO ~~~~
  // note that this is allowed, the call to glVertexAttribPointer registered
  // VBO as the vertex attribute's bound vertex buffer object so afterwards we
  // can safely unbind
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  // You can unbind the VAO afterwards so other VAO calls won't accidentally
  // modify this VAO, but this rarely happens. Modifying other VAOs requires a
  // call to glBindVertexArray anyways so we generally don't unbind VAOs
  // (nor VBOs) when it's not directly necessary.
  glBindVertexArray(0);

  // uncomment this call to draw polygons in wireframe.
  //glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

  glClearColor(0.2, 0.3, 0.3, 1);

  // ******* ---------------------------- *******
  // render loop
  // ******* ---------------------------- *******
  while (glfwWindowShouldClose(window) == GLFW_FALSE) {
    // -----
    // input
    // -----
    processInput(window);

    // ------
    // render
    // ------
    glClear(GL_COLOR_BUFFER_BIT);

    // 2. use our shader program when we want to render an object
    glUseProgram(shaderProgram); // Activate program

    // update shader uniform
    var timeValue = glfwGetTime();
    var greenValue = sin(timeValue) / 2 + 0.5;
    var vertexColorLocation = glGetUniformLocation(shaderProgram, 'ourColor');
    glUniform4f(vertexColorLocation, 0, greenValue, 0, 1);

    // seeing as we only have a single VAO there's no need to bind it every
    // time, but we'll do so to keep things a bit more organized
    glBindVertexArray(vao);
    glDrawArrays(GL_TRIANGLES, 0, 3);

    // no need to unbind it every time
    //glBindVertexArray(0);

    // -----------------------------------------------------------------------
    // glfw: swap buffers and poll IO events (keys pressed/released,
    // mouse moved etc.)
    // -----------------------------------------------------------------------
    glfwSwapBuffers(window);
    try {
      glfwPollEvents();
    } catch (e) {
      print(e);
    }
  }

  // ------------------------------------------------------------------------
  // optional: de-allocate all resources once they've outlived their purpose:
  // ------------------------------------------------------------------------
  gldtDeleteVertexArrays([vao]);
  gldtDeleteBuffers([vbo]);
  glDeleteProgram(shaderProgram);

  // ------------------------------------------------------------------
  // glfw: terminate, clearing all previously allocated GLFW resources.
  // ------------------------------------------------------------------
  glfwTerminate();

  return 0;
}

// --------------------------------------------------------------------------
// process all input: query GLFW whether relevant keys are pressed/released
// this frame and react accordingly
// --------------------------------------------------------------------------
void processInput(Pointer<GLFWwindow> window) {
  if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS) {
    glfwSetWindowShouldClose(window, GLFW_TRUE);
  }
}

// ---------------------------------------------------------------------------------------------
// glfw: whenever the window size changed (by OS or user resize) this callback function executes
// ---------------------------------------------------------------------------------------------
void framebufferSizeCallback(
    Pointer<GLFWwindow> window, int width, int height) {
  // make sure the viewport matches the new window dimensions; note that width and
  // height will be significantly larger than specified on retina displays.
  glViewport(0, 0, width, height);
}
