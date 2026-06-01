import 'graph_base.dart';

class HamiltonianResult {
  final List<int> animationPath;
  final List<List<int>> allCycles;
  final List<List<int>> allPaths;

  HamiltonianResult({
    required this.animationPath,
    required this.allCycles,
    required this.allPaths,
  });
}
HamiltonianResult findHamiltonianPath(Graph g) {
  final allCycles = <List<int>>[];
  final allPaths = <List<int>>[];
  final visited = <int>{};

  // Метод поиска из КОНКРЕТНОЙ стартовой вершины
  void findAll(int current, int startVertex) {
    visited.add(current);

    if (visited.length == g.length) {
      // Базовый случай: посетили все вершины графа!
      final currentRoute = List<int>.from(visited);
      
      // ПРОВЕРКА НА ЗАМЫКАНИЕ ЦИКЛА: 
      if (g[current].contains(startVertex)) {
        // Если замыкается — добавляем старт в конец для красивого кольца на холсте
        currentRoute.add(startVertex);
        allCycles.add(currentRoute);
      } else {
        // Если не замыкается — это просто честный Гамильтонов ПУТЬ
        allPaths.add(currentRoute);
      }
    } else {
      // Шагаем вглубь по соседям
      for (int vertex in g[current]) {
        if (!visited.contains(vertex)) {
          findAll(vertex, startVertex);
        }
      }
    }

    // Бэктрекинг: освобождаем вершину для других веток перебора
    visited.remove(current);
  }

  // Запускаем перебор из КАЖДОЙ вершины графа, чтобы найти ВСЕ возможные варианты
  for (int start = 0; start < g.length; start++) {
    // Пропускаем изолированные индексы удаленных вершин, если они есть
    if (g[start].isNotEmpty || g.any((neighbors) => neighbors.contains(start))) {
      findAll(start, start);
    }
  }

  // ВЫБОР ПРИОРИТЕТНОГО МАРШРУТА ДЛЯ АНИМАЦИИ:
  List<int> bestPath = [];
  if (allCycles.isNotEmpty) {
    bestPath = allCycles.first; // 1. Если есть ЦИКЛ — он в приоритете!
  } else if (allPaths.isNotEmpty) {
    bestPath = allPaths.first;  // 2. Если циклов нет — берем первый найденный ПУТЬ
  }

  return HamiltonianResult(
    animationPath: bestPath,
    allCycles: allCycles,
    allPaths: allPaths,
  );
}
