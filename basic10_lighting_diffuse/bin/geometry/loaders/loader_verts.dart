import 'package:path/path.dart' as p;
import 'dart:io' as io;
import 'base_loaders.dart';

class VertLoader extends BaseLoader {
  bool loadingDataFormat1 = false;
  bool loadingIndices = false;

  final RegExp expVertGroups =
      RegExp(r'\[([\-0-9. ]+),([\-0-9. ]+),([\-0-9. ]+)\]');
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
    AddNormalF? addNormalF,
  ) {
    addVertexF = addVertex;

    var path =
        p.join(io.Directory.current.path, 'resources/objects/', dataPath);

    // Load vertices
    List<String> content = io.File(path).readAsLinesSync();

    // Comment lines
    for (var line in content) {
      if (line.isEmpty) continue;

      RegExpMatch? match = expCommentLine.firstMatch(line);
      if (match != null) {
        continue;
      }

      _loadDataFormat1(line);
    }

    return 0;
  }

  void _loadDataFormat1(String line) {
    RegExpMatch? match = expVertGroups.firstMatch(line);

    if (match != null) {
      // The match has 4 groups based on the expression
      addVertexF(double.parse(match[1]!), double.parse(match[2]!),
          double.parse(match[3]!));
    }
  }
}
