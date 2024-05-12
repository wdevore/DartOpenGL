import 'dart:ffi';

import 'package:glew/glew.dart';
import 'package:path/path.dart' as p;
import 'package:vector_math/vector_math.dart';
import 'dart:io' as io;

import '../shader.dart';
import 'base_loaders.dart';
import 'base_object.dart';
import 'loader_sos.dart';

class CubeBasic1Object extends BaseObject {
  @override
  int configure(
      String dataPath, String? vertexShaderSrc, String? fragShaderSrc) {
    this.vertexShaderSrc = vertexShaderSrc;
    this.fragShaderSrc = fragShaderSrc;

    BaseLoader loader = SoSLoader();

    int status = loader.load(dataPath, _addVertex, _addColor, _addFace);

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

  void _addFace(int a, int b, int c) {
    indices.addAll([a, b, c]);
  }

  // The vertices and colors packed as "x,y,z,r,g,b"
  void _addVertex(double x, double y, double z) {
    vertices.addAll([x, y, z]);
  }

  void _addColor(double r, double g, double b) {
    vertices.addAll([r, g, b]);
  }

  int _loadShader() {
    String vs = vertexShaderSrc ?? '9.0.pos_color.vs';
    vertexShaderSrc =
        p.join(io.Directory.current.path, 'resources/shaders/', vs);

    String fs = fragShaderSrc ?? '9.0.pos_color.fs';
    fragShaderSrc = p.join(io.Directory.current.path, 'resources/shaders/', fs);

    shader = Shader(
      vertexFilePath: vertexShaderSrc,
      fragmentFilePath: fragShaderSrc,
    );

    return shader.id;
  }

  void _buildBufferArrays() {
    vaoId = gldtGenVertexArrays(1)[0];
    vboId = gldtGenBuffers(1)[0];
    eboId = gldtGenBuffers(1)[0];

    // bind the Vertex Array Object first, then bind and set vertex buffer(s),
    // and then configure vertex attributes(s).
    glBindVertexArray(vaoId);
    // 0. copy our vertices array in a buffer for OpenGL to use
    glBindBuffer(GL_ARRAY_BUFFER, vboId);
    gldtBufferFloat(GL_ARRAY_BUFFER, vertices, GL_STATIC_DRAW); // glBufferData

    // Attach EBO to VAO
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eboId);
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
    model = Matrix4.identity();
    model.rotate(Vector3(0.0, 1.0, 0.0), radians(15.0) * currentFrame);
    // model.translate(0.0, 1.0, 0.0);
    setModelTransform();
  }

  @override
  void draw() {
    gldtDrawElements(
        GL_TRIANGLES, indices.length, GL_UNSIGNED_INT, 0 * sizeOf<Uint32>());
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
