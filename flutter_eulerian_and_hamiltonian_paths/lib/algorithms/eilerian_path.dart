import 'graph_base.dart';

class EilerianResult {
  final List<int> animationPath; // Приоритетный путь для анимации на холсте
  final List<List<int>> allCycles; // Все уникальные Эйлеровы циклы
  final List<List<int>> allPaths;  // Все уникальные Эйлеровы пути

  EilerianResult({
    required this.animationPath,
    required this.allCycles,
    required this.allPaths,
  });
}

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


EilerianResult findEilerianPath(Graph g) {
  if (g.isEmpty) {
    return EilerianResult(animationPath: [], allCycles: [], allPaths: []);
  }

  // 1. Считаем общее количество рёбер в графе
  int totalEdges = 0;
  for (var neighbors in g) {
    totalEdges += neighbors.length;
  }
  totalEdges = totalEdges ~/ 2; // граф неориентированный

  final allCycles = <List<int>>[];
  final allPaths = <List<int>>[];
  
  // Копия графа для безопасных манипуляций в рекурсии
  final Graph gc = [for (List<int> elem in g) List<int>.from(elem)];
  final List<int> currentPath = [];

  // Рекурсивный DFS по рёбрам
  void findAll(int current, int startVertex) {
    currentPath.add(current);

    // Базовый случай: если количество шагов равно числу рёбер, мы нашли Эйлеров маршрут!
    if (currentPath.length - 1 == totalEdges && totalEdges > 0) {
      final foundRoute = List<int>.from(currentPath);
      if (current == startVertex) {
        allCycles.add(foundRoute);
      } else {
        allPaths.add(foundRoute);
      }
    } else {
      // Идём по доступным рёбрам
      // Делаем копию списка соседей, так как мы будем мутировать gc[current] во время итерации
      final neighbors = List<int>.from(gc[current]);
      for (int next in neighbors) {
        // Стираем ребро в обе стороны (проходим по нему)
        gc[current].remove(next);
        gc[next].remove(current);

        findAll(next, startVertex);

        // БЭКТРЕКИНГ: возвращаем ребро обратно для других веток перебора!
        gc[current].add(next);
        gc[next].add(current);
      }
    }

    currentPath.removeLast(); // убираем себя из хронологии маршрута
  }

  // Запускаем перебор. Так как Эйлеров путь/цикл жёстко привязан к рёбрам конкретного компонента,
  // запустим поиск из каждой вершины, у которой есть хотя бы одно ребро:
  for (int start = 0; start < g.length; start++) {
    if (g[start].isNotEmpty) {
      findAll(start, start);
    }
  }

  // Выбираем лучший маршрут для анимации на холсте
  List<int> bestPath = [];
  if (allCycles.isNotEmpty) {
    bestPath = allCycles.first;
  } else if (allPaths.isNotEmpty) {
    bestPath = allPaths.first;
  }

  // Если на холсте есть рёбра, но наш DFS ничего не нашёл — значит, граф не связный (разбит на острова)
  if (bestPath.isEmpty && totalEdges > 0) {
    throw ArgumentError('Граф разбит на изолированные подграфы. Эйлеров маршрут невозможен.');
  }

  return EilerianResult(
    animationPath: bestPath,
    allCycles: allCycles,
    allPaths: allPaths,
  );
}
