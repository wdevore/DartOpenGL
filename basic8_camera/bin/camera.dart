// https://github.com/JoeyDeVries/LearnOpenGL/blob/master/includes/learnopengl/camera.h
import 'dart:math';
import 'package:vector_math/vector_math.dart';

// Defines several possible options for camera movement. Used as abstraction to
// stay away from window-system specific input methods
enum CameraMovement {
  forward,
  backward,
  left,
  right,
  up,
  down,
}

class Camera {
  // Default camera values
  static const camYaw = -90.0;
  static const camPitch = 0.0;
  static const camSpeed = 2.5;
  // Adjust this value to your liking
  static const camSensitivity = 0.1;
  static const camZoom = 45.0;

  Vector3 position = Vector3(0.0, 0.0, 0.0);
  Vector3 dir = Vector3(0.0, 0.0, -1.0);
  Vector3 side = Vector3(1.0, 0, 0);
  Vector3 worldUp = Vector3(0.0, 1.0, 0.0);

  Vector3? up;
  Vector3? right;
  Vector3? slide;

  late double yaw;
  late double pitch;
  var movementSpeed = camSpeed;
  var mouseSensitivity = camSensitivity;
  var zoom = camZoom;

  Camera({
    position,
    worldUp,
    this.yaw = camYaw,
    this.pitch = camPitch,
  }) {
    if (position != null) {
      this.position = position;
    }
    if (worldUp != null) {
      this.worldUp = worldUp;
    }

    updateCameraVectors();
  }

  // returns the view matrix calculated using Euler Angles and the LookAt Matrix
  Matrix4 getViewMatrix() {
    return makeViewMatrix(position, position + dir, up!);
  }

  // processes input received from any keyboard-like input system.
  // Accepts input parameter in the form of camera defined ENUM
  // (to abstract it from windowing systems)
  void processKeyboard(CameraMovement direction, double deltaTime) {
    double velocity = movementSpeed * deltaTime;

    switch (direction) {
      case CameraMovement.forward:
        position += dir.scaled(velocity);
        break;
      case CameraMovement.backward:
        position -= dir.scaled(velocity);
        break;
      case CameraMovement.left:
        position -= right!.scaled(velocity);
        break;
      case CameraMovement.right:
        position += right!.scaled(velocity);
        break;
      case CameraMovement.up:
        position -= slide!.scaled(velocity);
        break;
      case CameraMovement.down:
        position += slide!.scaled(velocity);
        break;
    }
  }

  void processMouseMovement(double xoffset, double yoffset,
      {constrainPitch = true}) {
    xoffset *= mouseSensitivity;
    yoffset *= mouseSensitivity;

    yaw += xoffset;
    pitch += yoffset;

    // make sure that when pitch is out of bounds, screen doesn't get flipped
    if (constrainPitch) {
      if (pitch > 89.0) {
        pitch = 89.0;
      }
      if (pitch < -89.0) {
        pitch = 89.0;
      }
    }

    // update Front, Right and Up Vectors using the updated Euler angles
    updateCameraVectors();
  }

  void processMouseScroll(double yoffset) {
    zoom -= yoffset;
    if (zoom < 1.0) {
      zoom = 1.0;
    }
    if (zoom > 45.0) {
      zoom = 45.0;
    }
  }

  // calculate the new Front vector
  void updateCameraVectors() {
    dir.x = cos(radians(yaw)) * cos(radians(pitch));
    dir.y = sin(radians(pitch));
    dir.z = sin(radians(yaw)) * cos(radians(pitch));
    dir.normalize();

    // Normalize the vectors, because their length gets closer to 0 the more
    // you look up or down which results in slower movement.
    right = dir.cross(worldUp).normalized();
    up = right!.cross(dir).normalized();

    slide = dir.cross(side).normalized();
  }
}
