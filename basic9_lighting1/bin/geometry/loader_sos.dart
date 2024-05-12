import 'package:path/path.dart' as p;
import 'dart:io' as io;
import 'base_loaders.dart';

class SoSLoader extends BaseLoader {
  bool loadingDataFormat1 = false;
  bool loadingIndices = false;

  final RegExp expVertColGroups = RegExp(
      r'(([\-0-9. ]+),([\-0-9. ]+),([\-0-9. ]+))[ ,]+(([\-0-9. ]+),([\-0-9. ]+),([\-0-9. ]+))');
  final RegExp expIndicesGroups = RegExp(r'(([0-9 ]+),([0-9 ]+),([0-9 ]+))');
  final RegExp expCommentLine = RegExp(r'^\/\/');

  late AddVertexF addVertexF;
  late AddColorF? addColorF;
  late AddIndicesF? addIndicesF;

  @override
  int load(
    String dataPath,
    AddVertexF addVertex,
    AddColorF? addColor,
    AddIndicesF? addIndices,
  ) {
    addVertexF = addVertex;
    addColorF = addColor;
    addIndicesF = addIndices;

    var path =
        p.join(io.Directory.current.path, 'resources/objects/', dataPath);

    // Load vertices, colors and indices
    List<String> content = io.File(path).readAsLinesSync();

    // Comment lines
    for (var line in content) {
      if (line.isEmpty) continue;

      RegExpMatch? match = expCommentLine.firstMatch(line);
      if (match != null) {
        continue;
      }

      if (line == 'x,y,z,r,g,b') {
        loadingDataFormat1 = true;
        continue;
      }

      if (loadingDataFormat1) {
        _loadDataFormat1(line);
      }

      if (line == 'Indices') {
        loadingIndices = true;
        continue;
      }

      if (loadingIndices) {
        _loadIndices(line);
      }
    }

    return 0;
  }

  void _loadIndices(String line) {
    RegExpMatch? match = expIndicesGroups.firstMatch(line);

    if (match != null) {
      // The match has 4 groups based on the expression
      addIndicesF!(
          int.parse(match[2]!), int.parse(match[3]!), int.parse(match[4]!));
    }
  }

  void _loadDataFormat1(String line) {
    RegExpMatch? match = expVertColGroups.firstMatch(line);

    if (match != null) {
      // The match has 8 groups based on the expression
      // Group 1 has vertices
      List<String> v = match[1]!.split(',');
      addVertexF(double.parse(v[0]), double.parse(v[1]), double.parse(v[2]));
      // Group 5 has colors
      List<String> c = match[5]!.split(',');
      addColorF!(double.parse(c[0]), double.parse(c[1]), double.parse(c[2]));
    }
  }
}
