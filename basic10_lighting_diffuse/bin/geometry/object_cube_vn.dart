import 'dart:ffi';

import 'package:glew/glew.dart';
import 'package:path/path.dart' as p;
import 'dart:io' as io;

import '../shader.dart';
import 'loaders/base_loaders.dart';
import 'base_object.dart';
import 'loaders/loader_verts_norms.dart';

// Only vertices and Normals are loaded. Other properties are set elsewhere.
class CubeVNObject extends BaseObject {
  @override
  int configure(
    String dataPath,
    String? vertexShaderSrc,
    String? fragShaderSrc,
  ) {
    this.vertexShaderSrc = vertexShaderSrc;
    this.fragShaderSrc = fragShaderSrc;

    BaseLoader loader = VertNormLoader();

    int status = loader.load(dataPath, _addVertex, null, null, _addNormal);

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

  void _addNormal(double nx, double ny, double nz) {
    vertices.addAll([nx, ny, nz]);
  }

  int _loadShader() {
    // Default to standard colored cube
    String vs = vertexShaderSrc ?? '2.1.basic_lighting.vs';
    vertexShaderSrc =
        p.join(io.Directory.current.path, 'resources/shaders/', vs);

    String fs = fragShaderSrc ?? '2.1.basic_lighting.fs';
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
    // Size (3 floats) and Stride (6 floats = v(3) + n(3))
    gldtVertexAttribPointer(
        0, 3, GL_FLOAT, GL_FALSE, 6 * sizeOf<Float>(), 0 * sizeOf<Float>());
    // Parameters:
    // 1: Because we specified "layout (location = 0)" in the vertex shader
    //    we use "0" to match location 0
    glEnableVertexAttribArray(0);

    // --- Normal attribute ---
    // Index (1) and Size (3 floats) and Stride (6) and Pos (3 float offset)
    gldtVertexAttribPointer(
        1, 3, GL_FLOAT, GL_FALSE, 6 * sizeOf<Float>(), 3 * sizeOf<Float>());
    glEnableVertexAttribArray(1);

    // ~~~~ VBO ~~~~
    // note that this is allowed, the call to glVertexAttribPointer registered
    // VBO as the vertex attribute's bound vertex buffer object so afterwards we
    // can safely unbind
    glBindBuffer(GL_ARRAY_BUFFER, vboId);

    // You can unbind the VAO afterwards so other VAO calls won't accidentally
    // modify this VAO, but this rarely happens. Modifying other VAOs requires a
    // call to glBindVertexArray anyways so we generally don't unbind VAOs
    // (nor VBOs) when it's not directly necessary.
    glBindVertexArray(vaoId);
  }

  @override
  void use() {
    shader.use();
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
    glBindVertexArray(vaoId);
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
