import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:glew/glew.dart';
import 'package:glfw3/glfw3.dart';

import 'main.dart';

// --- Mouse
var gLastX = gScrWidth / 2.0;
var gLastY = gScrHeight / 2.0;
var gMouseTracking = false;
var gFirstMouse = true;

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

  gCamera.processMouseMovement(xoffset, yoffset);
}

// glfw: whenever the mouse scroll wheel scrolls, this callback is called
// ----------------------------------------------------------------------
void scrollCallback(
    Pointer<GLFWwindow> window, double xoffset, double yoffset) {
  gCamera.processMouseScroll(yoffset);
}

void mouseButtonCallback(
    Pointer<GLFWwindow> window, int button, int action, int mods) {
  if (button == GLFW_MOUSE_BUTTON_1 && action == GLFW_PRESS) {
    Pointer<Double> xpos = calloc<Double>();
    Pointer<Double> ypos = calloc<Double>();

    glfwGetCursorPos(window, xpos, ypos);
    gLastX = xpos.value;
    gLastY = ypos.value;

    // Start tracking
    gLastX = xpos.value;
    gLastY = ypos.value;

    calloc.free(xpos);
    calloc.free(ypos);

    gMouseTracking = true;
  } else if (button == GLFW_MOUSE_BUTTON_1 && action == GLFW_RELEASE) {
    gMouseTracking = false;
  }
}
