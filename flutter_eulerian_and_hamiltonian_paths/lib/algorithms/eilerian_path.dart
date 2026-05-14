typedef Graph = List<List<int>>;

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


void main(){
   final Graph butterflyGraph = [
    [1, 2],       // 0
    [0, 2],       // 1
    [0, 1, 3, 4], // 2 (центральный перекресток)
    [2, 4],       // 3
    [2, 3],       // 4
  ];

  print('--- Тестирование алгоритма Хирхольцера ---');
  
  // Проверяем наличие нечетных вершин (должно быть 0)
  final odd = _getOddVertices(butterflyGraph);
  print('Вершины с нечетной степенью: $odd (ожидается {})');

  // Запускаем поиск пути
  final path = findEilerianPath(butterflyGraph);
  
  print('Найденный Эйлеров путь: $path');
  
  // Проверка правильности: путь должен содержать 6 вершин (так как ребер 6)
  if (path.length == 7) {
    print('🚀 Успех! Алгоритм идеально склеил циклы и нашел полный маршрут.');
  } else if (path.isEmpty) {
    print('❌ Ошибка: Путь не найден, хотя граф эйлеров.');
  } else {
    print('⚠️ Путь найден, но кажется, какое-то ребро потерялось: $path');
  }
}