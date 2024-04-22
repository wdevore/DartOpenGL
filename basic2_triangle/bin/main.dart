import 'dart:ffi';
import 'package:glew/glew.dart';
import 'package:glfw3/glfw3.dart';

import 'shaders.dart';

// settings
const gScrWidth = 800;
const gScrHeight = 600;

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
      gScrWidth, gScrHeight, 'basic2_triangle', nullptr, nullptr);
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
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  gldtBufferFloat(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW);
  gldtVertexAttribPointer(
      0, 3, GL_FLOAT, GL_FALSE, 3 * sizeOf<Float>(), 0 * sizeOf<Float>());
  glEnableVertexAttribArray(0);
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

    // draw our first triangle
    glUseProgram(shaderProgram);
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
    glfwPollEvents();
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
