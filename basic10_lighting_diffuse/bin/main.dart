import 'dart:ffi';
import 'package:glew/glew.dart';
import 'package:glfw3/glfw3.dart';
import 'package:vector_math/vector_math.dart';

import 'attribute_index_gen_f.dart';
import 'callbacks.dart';
import 'camera.dart';
import 'geometry/object_cube_basic1.dart';
import 'geometry/object_cube_verts.dart';
import 'geometry/object_cube_vn.dart';

// -- View port
const gScrWidth = 800;
const gScrHeight = 600;

// --- timing
var gDeltaTime = 0.0;
var gLastFrame = 0.0;

// --- Camera
var gCamera =
    Camera(position: Vector3(1.25, 1.5, 4.0), yaw: -105.0, pitch: -15.0);

// --- Lighting
var gLightPos = Vector3(1.2, 1.0, 2.0);

enum RenderMode {
  wireFrame,
  filled,
}

RenderMode renderMode = RenderMode.filled;

var indexGenerator = attributeIndexGenerator(10);

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
  var aspectRatio = gScrWidth / gScrHeight;

  var window = glfwCreateWindow(
      gScrWidth, gScrHeight, 'basic10_lighting_diffuse', nullptr, nullptr);
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

  // CubeBasic1Object cube = CubeBasic1Object()
  //   ..configure('cube_colors.sos', null, null);
  // CubeVertsObject cube = CubeVertsObject()..configure('cube.verts', null, null);
  CubeVNObject cube = CubeVNObject()
    ..configure(
      'cube.vn',
      '2.1.basic_lighting.vs',
      '2.1.basic_lighting.fs',
    );
  CubeVertsObject light = CubeVertsObject()
    ..configure(
      'cube.verts',
      '1.light_cube.vs',
      '1.light_cube.fs',
    );

  glClearColor(0.1, 0.1, 0.1, 1);

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

    // --- View
    var view = gCamera.getViewMatrix();

    // --- Projection
    var projection =
        makePerspectiveMatrix(radians(gCamera.zoom), aspectRatio, 0.1, 100.0);

    // @@@ ------- Cube ------------ @@@
    cube.use();
    cube.shader.setVector3('objectColor', Vector3(1.0, 0.5, 0.31));
    cube.shader.setVector3('lightColor', Vector3(1.0, 1.0, 1.0));
    cube.shader.setVector3('lightPos', gLightPos);
    cube.model.setIdentity();
    cube.update(currentFrame);
    cube.shader.setMatrix4('view', view);
    cube.shader.setMatrix4('projection', projection);
    cube.draw();

    // @@@ ------- Light ------------ @@@
    light.use();
    light.model.setIdentity();
    light.model.translate(gLightPos);
    // Light lamp is smaller
    light.model.scale(Vector3.all(0.2));
    light.update(currentFrame);
    light.shader.setMatrix4('view', view);
    light.shader.setMatrix4('projection', projection);
    light.draw();

    // -----------------------------------------------------------------------
    // glfw: swap buffers and poll IO events (keys pressed/released,
    // mouse moved etc.)
    // -----------------------------------------------------------------------
    glfwSwapBuffers(window);
    glfwPollEvents();
  }

  cube.dispose();
  light.dispose();

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

  if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS) {
    gCamera.processKeyboard(CameraMovement.forward, gDeltaTime);
  }
  if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS) {
    gCamera.processKeyboard(CameraMovement.backward, gDeltaTime);
  }
  if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS) {
    gCamera.processKeyboard(CameraMovement.left, gDeltaTime);
  }
  if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS) {
    gCamera.processKeyboard(CameraMovement.right, gDeltaTime);
  }

  if (glfwGetKey(window, GLFW_KEY_UP) == GLFW_PRESS) {
    gCamera.processKeyboard(CameraMovement.up, gDeltaTime);
  }
  if (glfwGetKey(window, GLFW_KEY_DOWN) == GLFW_PRESS) {
    gCamera.processKeyboard(CameraMovement.down, gDeltaTime);
  }
}
