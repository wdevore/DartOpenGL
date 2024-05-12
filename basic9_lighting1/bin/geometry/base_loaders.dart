typedef AddVertexF = Function(double x, double y, double z);
typedef AddColorF = Function(double r, double g, double b);
typedef AddIndicesF = Function(int a, int b, int c);

abstract class BaseLoader {
  int load(
    String dataPath,
    AddVertexF addVertex,
    AddColorF? addColor,
    AddIndicesF? addIndices,
  );
}
