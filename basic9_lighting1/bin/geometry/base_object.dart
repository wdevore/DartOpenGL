import 'package:vector_math/vector_math.dart';

import '../shader.dart';

abstract class BaseObject {
  // Example formats are:
  // x,y,z,r,g,b...
  List<double> vertices = [];

  List<int> indices = [];

  late Shader shader;

  int vaoId = -1;
  int vboId = -1;
  int eboId = -1;

  late Matrix4 model = Matrix4.identity();

  String? vertexShaderSrc;
  String? fragShaderSrc;

  int configure(
      String dataPath, String? vertexShaderSrc, String? fragShaderSrc);

  void setModelTransform();

  void use();

  void update(double currentFrame);
  void draw();

  void dispose();
}
