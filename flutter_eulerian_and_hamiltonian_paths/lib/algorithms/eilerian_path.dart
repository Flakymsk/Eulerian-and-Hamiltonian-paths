import 'graph_base.dart';


Set<int> _getOddVertices(Graph g){
  return {
    for (int i = 0; i < g.length; ++i)
      if (g[i].length % 2 != 0) i
  };
}

/// Функция проверяет граф на количество вершин с нечетной степенью.
/// Проверка на связность осуществляется при обходе графа
bool _checkEilerianPath(Graph g, {Set<int>? oddVertices}){
  final oddVerticesCheck = oddVertices?? _getOddVertices(g);

  if (oddVerticesCheck.length > 2) return false;

  return true;
}


List<int> findEilerianPath(Graph g){
  final oddVertices = _getOddVertices(g);
  List<int> currentPath = [];
  List<int> eilerianPath = [];

  final Graph gc = [for (List<int> elem in g) List<int>.from(elem)];


  if (!_checkEilerianPath(g, oddVertices: oddVertices)) return eilerianPath;
  
  oddVertices.isNotEmpty ? currentPath.add(oddVertices.first) : currentPath.add(0);

  while (currentPath.isNotEmpty){
    if (gc[currentPath.last].isNotEmpty){
      final value = gc[currentPath.last].removeAt(0);
      gc[value].remove(currentPath.last);
      currentPath.add(value);
    }
    else{
      eilerianPath.add(currentPath.removeLast());
    }
  }

  return eilerianPath.reversed.toList();
}