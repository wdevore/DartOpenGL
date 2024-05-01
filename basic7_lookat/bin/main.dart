import 'dart:ffi';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:glew/glew.dart';
import 'package:glfw3/glfw3.dart';
import 'package:path/path.dart' as p;
import 'package:sdl2/sdl2/ex/dart/native_type.dart';
import 'package:vector_math/vector_math.dart';
import 'dart:io' as io;

import 'shader_m.dart';

// -- View port
const gScrWidth = 800;
const gScrHeight = 600;

// --- timing
var gDeltaTime = 0.0;
var gLastFrame = 0.0;

// --- Camera
Vector3 gCameraPos = Vector3(0.0, 0.0, 3.0);
Vector3 gCameraDir = Vector3(0.0, 0.0, -1.0);
Vector3 gCameraUp = Vector3(0.0, 1.0, 0.0);
Vector3 gCameraSide = Vector3(1.0, 0, 0);

// --- Mouse
var gLastX = gScrWidth / 2.0;
var gLastY = gScrHeight / 2.0;

var gMouseTracking = false;
var gFirstMouse = true;
var gYaw = -90.0;
var gPitch = 0.0;
var gFov = 45.0;

enum RenderMode {
  wireFrame,
  filled,
}

RenderMode renderMode = RenderMode.filled;

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
      gScrWidth, gScrHeight, 'basic7_lookat', nullptr, nullptr);
  if (window == nullptr) {
    print('Failed to create GLFW window');
    glfwTerminate();
    return -1;
  }
  glfwMakeContextCurrent(window);
  glfwSetFramebufferSizeCallback(
      window, Pointer.fromFunction(framebufferSizeCallback));

  // --------------------
  // Mouse callbacks
  // --------------------
  glfwSetCursorPosCallback(window, Pointer.fromFunction(cursorPosCallback));
  glfwSetScrollCallback(window, Pointer.fromFunction(scrollCallback));
  glfwSetMouseButtonCallback(window, Pointer.fromFunction(mouseButtonCallback));

  // // Tell GLFW to capture our mouse
  // glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

  // --------------------
  // glad: load all OpenGL function pointers
  // --------------------
  gladLoadGLLoader(glfwGetProcAddress);

  // ------------------------------------
  // build and compile our shader program
  // ------------------------------------
  var vertexShader = p.join(
      io.Directory.current.path, 'resources/shaders/', '9.0.pos_color.vs');
  var fragmentShader = p.join(
      io.Directory.current.path, 'resources/shaders/', '9.0.pos_color.fs');

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
    // back red
    -0.5, -0.5, -0.5, 1.0, 0.0, 0.0, // 0
    0.5, -0.5, -0.5, 1.0, 0.0, 0.0, // 1
    0.5, 0.5, -0.5, 1.0, 0.0, 0.0, // 2
    -0.5, 0.5, -0.5, 1.0, 0.0, 0.0, // 3

    // top blue
    -0.5, 0.5, -0.5, 0.0, 0.0, 1.0, // 4
    0.5, 0.5, -0.5, 0.0, 0.0, 1.0, // 5
    0.5, 0.5, 0.5, 0.0, 0.0, 1.0, // 6
    -0.5, 0.5, 0.5, 0.0, 0.0, 1.0, // 7

    // left green
    -0.5, -0.5, -0.5, 0.0, 1.0, 0.0, // 8
    -0.5, 0.5, -0.5, 0.0, 1.0, 0.0, // 9
    -0.5, 0.5, 0.5, 0.0, 1.0, 0.0, // 10
    -0.5, -0.5, 0.5, 0.0, 1.0, 0.0, // 11

    // right orange
    0.5, -0.5, -0.5, 1.0, 0.5, 0.0, // 12
    0.5, 0.5, -0.5, 1.0, 0.5, 0.0, // 13
    0.5, 0.5, 0.5, 1.0, 0.5, 0.0, // 14
    0.5, -0.5, 0.5, 1.0, 0.5, 0.0, // 15

    // front yellow
    -0.5, -0.5, 0.5, 1.0, 1.0, 0.0, // 16
    0.5, -0.5, 0.5, 1.0, 1.0, 0.0, // 17
    0.5, 0.5, 0.5, 1.0, 1.0, 0.0, // 18
    -0.5, 0.5, 0.5, 1.0, 1.0, 0.0, // 19

    // bottom magenta
    -0.5, -0.5, 0.5, 1.0, 0.0, 1.0, // 20
    0.5, -0.5, 0.5, 1.0, 0.0, 1.0, // 21
    0.5, -0.5, -0.5, 1.0, 0.0, 1.0, // 22
    -0.5, -0.5, -0.5, 1.0, 0.0, 1.0 // 23
  ];

  var indices = [
    // front
    0, 1, 2, // first triangle
    2, 3, 0, // second triangle

    // top
    4, 5, 6, // first triangle
    6, 7, 4, // second triangle

    // left
    8, 9, 10, // first triangle
    10, 11, 8, // second triangle

    // right
    14, 13, 12, // 12, 13, 14, // first triangle
    12, 15, 14, // 14, 15, 12, // second triangle

    // back
    18, 17, 16, // 16, 17, 18, // first triangle
    16, 19, 18, // 18, 19, 16, // second triangle

    // bottom
    20, 21, 22, // first triangle
    22, 23, 20 // second triangle
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

  // Attach EBO to VAO
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
  gldtBufferUint32(GL_ELEMENT_ARRAY_BUFFER, indices, GL_STATIC_DRAW);

  // --- position atribute ---
  gldtVertexAttribPointer(
      0, 3, GL_FLOAT, GL_FALSE, 6 * sizeOf<Float>(), 0 * sizeOf<Float>());
  // Parameters:
  // 1: Because we specified "layout (location = 0)" in the vertex shader
  //    we use "0" to match location 0
  glEnableVertexAttribArray(0);

  // --- color attribute ---
  gldtVertexAttribPointer(
      1, 3, GL_FLOAT, GL_FALSE, 6 * sizeOf<Float>(), 3 * sizeOf<Float>());
  glEnableVertexAttribArray(1);

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

  // ***** --------------------------------------------- *****
  // Uncomment this call to draw polygons in wireframe.
  // glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
  // ***** --------------------------------------------- *****

  glClearColor(0.2, 0.3, 0.3, 1);

  ourShader.use();
  // --- Color of object
  var vertexColorLoc = glGetUniformLocation(ourShader.id, 'ourColor');
  glUniform3f(vertexColorLoc, 1, 0.5, 0);

  glEnable(GL_DEPTH_TEST);

  // ******* ---------------------------- *******
  // render loop
  // ******* ---------------------------- *******
  while (glfwWindowShouldClose(window) == GLFW_FALSE) {
    // -----
    // per-frame time logic (FPS)
    // --------------------
    var currentFrame = glfwGetTime();
    gDeltaTime = currentFrame - gLastFrame;
    gLastFrame = currentFrame;

    // -----
    // input
    // -----
    processInput(window);

    switch (renderMode) {
      case RenderMode.wireFrame:
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        break;
      case RenderMode.filled:
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        break;
      default:
        glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
        break;
    }
    // ------
    // render
    // ------
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    ourShader.use();

    // --- create transformations
    var model = Matrix4.identity();
    model.rotate(Vector3(0.0, 1.0, 0.0), radians(15.0) * currentFrame);
    // model.translate(0.0, 1.0, 0.0);

    // --- View
    var view = makeViewMatrix(gCameraPos, gCameraPos + gCameraDir, gCameraUp);

    // --- Projection
    var projection = makePerspectiveMatrix(
        radians(gFov), gScrWidth / gScrHeight, 0.1, 100.0);

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
  } else if (glfwGetKey(window, GLFW_KEY_R) == GLFW_PRESS) {
    renderMode = RenderMode.wireFrame;
  } else if (glfwGetKey(window, GLFW_KEY_F) == GLFW_PRESS) {
    renderMode = RenderMode.filled;
  }

  var cameraSpeed = 2.5 * gDeltaTime;

  if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS) {
    gCameraPos += gCameraDir.scaled(cameraSpeed);
  }
  if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS) {
    gCameraPos -= gCameraDir.scaled(cameraSpeed);
  }
  if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS) {
    gCameraPos -= gCameraDir.cross(gCameraUp).scaled(cameraSpeed);
  }
  if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS) {
    gCameraPos += gCameraDir.cross(gCameraUp).scaled(cameraSpeed);
  }

  if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS) {
    gCameraPos -= gCameraDir.cross(gCameraSide).scaled(cameraSpeed);
  }
  if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS) {
    gCameraPos += gCameraDir.cross(gCameraSide).scaled(cameraSpeed);
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

// glfw: whenever the mouse moves, this callback is called
// -------------------------------------------------------
void cursorPosCallback(Pointer<GLFWwindow> window, double xpos, double ypos) {
  if (!gMouseTracking) return;

  if (gFirstMouse) {
    gLastX = xpos;
    gLastY = ypos;
    gFirstMouse = false;
  }
  var xoffset = xpos - gLastX;

  // reversed since y-coordinates go from bottom to top
  var yoffset = gLastY - ypos;
  gLastX = xpos;
  gLastY = ypos;

  // change this value to your liking
  var sensitivity = 0.1;
  xoffset *= sensitivity;
  yoffset *= sensitivity;
  gYaw += xoffset;
  gPitch += yoffset;

  // make sure that when pitch is out of bounds, screen doesn't get flipped
  if (gPitch > 89.0) {
    gPitch = 89.0;
  }
  if (gPitch < -89.0) {
    gPitch = -89.0;
  }
  var front = Vector3(
    cos(radians(gYaw)) * cos(radians(gPitch)),
    sin(radians(gPitch)),
    sin(radians(gYaw)) * cos(radians(gPitch)),
  );
  gCameraDir = front.normalized();
}

// glfw: whenever the mouse scroll wheel scrolls, this callback is called
// ----------------------------------------------------------------------
void scrollCallback(
    Pointer<GLFWwindow> window, double xoffset, double yoffset) {
  gFov -= yoffset;
  if (gFov < 1.0) {
    gFov = 1.0;
  }
  if (gFov > 45.0) {
    gFov = 45.0;
  }
}

void mouseButtonCallback(
    Pointer<GLFWwindow> window, int button, int action, int mods) {
  if (button == GLFW_MOUSE_BUTTON_1 && action == GLFW_PRESS) {
    Pointer<Double> xpos = calloc<Double>();
    Pointer<Double> ypos = calloc<Double>();
    // , Pointer<Double> ypos
    glfwGetCursorPos(window, xpos, ypos);
    gLastX = xpos.value;
    gLastY = ypos.value;

    // Start tracking
    gLastX = xpos.value;
    gLastY = ypos.value;

    xpos.callocFree();
    ypos.callocFree();

    gMouseTracking = true;
  } else if (button == GLFW_MOUSE_BUTTON_1 && action == GLFW_RELEASE) {
    gMouseTracking = false;
  }
}

/// Configure view matrix using LookAt concept. +Y is Up.
///
/// Ex:
///   ```Dart
///   Vector3 target = Vector3(0.0, 0.0, 0.0); // Camera target
///   Vector3 position = Vector3(3.0, 1.0, 3.0);// Camera position
///   Matrix4 view = calcLookAt(position, target);
///   ```
///
/// [cpo] is camera position, [ctar] is look at target
Matrix4 calcLookAt(Vector3 cpo, Vector3 ctar) {
  var view = Matrix4.identity();
  var viewOrien = Matrix4.identity();
  var viewPos = Matrix4.identity();

  // Camera position
  // | 1 0 0 -Px |
  // | 0 1 0 -Py |
  // | 0 0 1 -Pz |
  // | 0 0 0  1  |
  viewPos.setColumn(3, Vector4(-cpo.x, -cpo.y, -cpo.z, 1));

  // Camera Direction
  Vector3 dir = (cpo - ctar).normalized();

  // Camera up. Hard coded to +Y is up
  Vector3 up = Vector3(0.0, 1.0, 0.0);
  // Camera right
  Vector3 cr = up.cross(dir).normalized();

  // Camera Up
  Vector3 cup = dir.cross(cr).normalized();

  // Camera Orientation
  // | Rx Ry Rz 0 |
  // | Ux Uy Uz 0 |
  // | Dx Dy Dz 0 |
  // | 0  0  0  1 |
  viewOrien.setRow(0, Vector4(cr.x, cr.y, cr.z, 0));
  viewOrien.setRow(1, Vector4(cup.x, cup.y, cup.z, 0));
  viewOrien.setRow(2, Vector4(dir.x, dir.y, dir.z, 0));
  viewOrien.setRow(3, Vector4(0, 0, 0, 1));

  view = viewOrien * viewPos;
  return view;
}
