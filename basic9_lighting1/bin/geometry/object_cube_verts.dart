import 'dart:ffi';

import 'package:glew/glew.dart';
import 'package:path/path.dart' as p;
import 'package:vector_math/vector_math.dart';
import 'dart:io' as io;

import '../shader.dart';
import 'base_loaders.dart';
import 'base_object.dart';
import 'loader_verts.dart';

// Only vertices are loaded. Other properties are set elsewhere.
class CubeVertsObject extends BaseObject {
  @override
  int configure(
      String dataPath, String? vertexShaderSrc, String? fragShaderSrc) {
    this.vertexShaderSrc = vertexShaderSrc;
    this.fragShaderSrc = fragShaderSrc;

    BaseLoader loader = VertLoader();

    int status = loader.load(dataPath, _addVertex, null, null);

    if (status != 0) {
      return status;
    }

    // ------------------------------------
    // build and compile our shader program
    // ------------------------------------
    status = _loadShader();
    if (status == 0) {
      return status; // Failed
    }

    // ------------------------------------------------------------------
    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    _buildBufferArrays();

    return 0;
  }

  // The vertices are packed as "x,y,z"
  void _addVertex(double x, double y, double z) {
    vertices.addAll([x, y, z]);
  }

  int _loadShader() {
    // Default to standard colored cube
    String vs = vertexShaderSrc ?? '1.colors.vs';
    vertexShaderSrc =
        p.join(io.Directory.current.path, 'resources/shaders/', vs);

    String fs = fragShaderSrc ?? '1.colors.fs';
    fragShaderSrc = p.join(io.Directory.current.path, 'resources/shaders/', fs);

    var vertexShader =
        p.join(io.Directory.current.path, 'resources/shaders/', vs);
    var fragmentShader =
        p.join(io.Directory.current.path, 'resources/shaders/', fs);

    shader = Shader(
      vertexFilePath: vertexShader,
      fragmentFilePath: fragmentShader,
    );

    return shader.id;
  }

  void _buildBufferArrays() {
    vaoId = gldtGenVertexArrays(1)[0];
    vboId = gldtGenBuffers(1)[0];

    // bind the Vertex Array Object first, then bind and set vertex buffer(s),
    // and then configure vertex attributes(s).
    glBindVertexArray(vaoId);
    // 0. copy our vertices array in a buffer for OpenGL to use
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    gldtBufferFloat(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW); // glBufferData

    // --- position atribute ---
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
  }

  @override
  void use() {
    shader.use();
    // seeing as we only have a single VAO there's no need to bind it every
    // time, but we'll do so to keep things a bit more organized
    glBindVertexArray(vaoId);
  }

  @override
  void update(double currentFrame) {
    // model.setIdentity();
    // model.rotate(Vector3(0.0, 1.0, 0.0), radians(15.0) * currentFrame);
    // model.translate(0.0, 1.0, 0.0);
    setModelTransform();
  }

  @override
  void draw() {
    glDrawArrays(GL_TRIANGLES, 0, 36);
  }

  @override
  void dispose() {
    // ------------------------------------------------------------------------
    // optional: de-allocate all resources once they've outlived their purpose:
    // ------------------------------------------------------------------------
    gldtDeleteVertexArrays([vaoId]);
    gldtDeleteBuffers([vboId]);
    shader.delete();
  }

  @override
  void setModelTransform() {
    shader.setMatrix4('model', model);
  }
}
