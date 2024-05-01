import 'dart:ffi';
import 'package:glew/glew.dart';
import 'package:glfw3/glfw3.dart';
import 'package:path/path.dart' as p;
import 'package:vector_math/vector_math.dart';
import 'dart:io' as io;

import 'shader_m.dart';

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
  var window =
      glfwCreateWindow(gScrWidth, gScrHeight, 'basic6_3d', nullptr, nullptr);
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
  var vertexShader = p.join(io.Directory.current.path, 'resources/shaders/',
      '6.1.coordinate_systems.vs');
  var fragmentShader = p.join(io.Directory.current.path, 'resources/shaders/',
      '6.1.coordinate_systems.fs');

  var ourShader = Shader(
    vertexFilePath: vertexShader,
    fragmentFilePath: fragmentShader,
  );

  // ------------------------------------------------------------------
  // set up vertex data (and buffer(s)) and configure vertex attributes
  // ------------------------------------------------------------------
  // For simplicity these coords are defined in NDCs rather than using matrices.
  // -1 to 1 is the visible space.
  var vertices = [
    0.5, 0.5, 0.0, // top right
    0.5, -0.5, 0.0, // bottom right
    -0.5, -0.5, 0.0, // bottom left
    -0.5, 0.5, 0.0, // top left
  ];

  var indices = [
    0, 1, 3, // first triangle
    1, 2, 3, // second triangle
  ];

  var vao = gldtGenVertexArrays(1)[0];
  var vbo = gldtGenBuffers(1)[0];
  var ebo = gldtGenBuffers(1)[0];

  // bind the Vertex Array Object first, then bind and set vertex buffer(s),
  // and then configure vertex attributes(s).
  glBindVertexArray(vao);
  // 0. copy our vertices array in a buffer for OpenGL to use
  glBindBuffer(GL_ARRAY_BUFFER, vbo);
  gldtBufferFloat(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW); // glBufferData

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
  gldtBufferUint32(GL_ELEMENT_ARRAY_BUFFER, indices, GL_STATIC_DRAW);

  // position atribute
  gldtVertexAttribPointer(
      0, 3, GL_FLOAT, GL_FALSE, 3 * sizeOf<Float>(), 0 * sizeOf<Float>());
  // Parameters:
  // 1: Because we specified "layout (location = 0)" in the vertex shader
  //    we use "0" to match location 0
  glEnableVertexAttribArray(0);

  // remember: do NOT unbind the EBO while a VAO is active as the bound element buffer object IS stored in the VAO; keep the EBO bound.
  //glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

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

  ourShader.use();
  // --- Color of object
  var vertexColorLoc = glGetUniformLocation(ourShader.id, 'ourColor');
  glUniform3f(vertexColorLoc, 1, 0.5, 0);

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

    ourShader.use();

    // --- create transformations
    var model = Matrix4.identity();
    model.rotate(Vector3(1.0, 0.0, 0.0), radians(-55.0));

    var view = Matrix4.identity();
    view.translate(0.0, 0.0, -3.0);

    var projection = makePerspectiveMatrix(
        radians(45.0), gScrWidth / gScrHeight, 0.1, 100.0);

    // --- use shader_m methods
    ourShader.setMatrix4('model', model);
    ourShader.setMatrix4('view', view);
    ourShader.setMatrix4('projection', projection);

    // seeing as we only have a single VAO there's no need to bind it every
    // time, but we'll do so to keep things a bit more organized
    glBindVertexArray(vao);

    gldtDrawElements(
        GL_TRIANGLES, indices.length, GL_UNSIGNED_INT, 0 * sizeOf<Uint32>());

    // --- no need to unbind it every time
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
  ourShader.delete();

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
