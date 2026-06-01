import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_eulerian_and_hamiltonian_paths/algorithms/algorithms.dart';
import 'package:graphview/graphview.dart' as gv;

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() {
  runApp(const ThemeApp()
  );
}

class ThemeApp extends StatefulWidget {
  const ThemeApp({super.key});

  @override
  State<ThemeApp> createState() => _ThemeAppState();
}

class _ThemeAppState extends State<ThemeApp> {
  bool _isDarkTheme = false;
  bool _isEilerian = true;
  int _animationSpeedMs = 500;
  CanvasMode _currentMode = CanvasMode.createNodes;
  HamiltonianResult? _lastHamiltonianResult;
  EilerianResult? _lastEilerianResult;


  List<Vertex> _vertices = [];
  
  // Наша матрица смежности (наш бэкенд-тип Graph). 
  // Индекс списка — это ID вершины, а внутри — список ID её соседей.
  List<List<int>> _myGraph = [];

  // Состояние анимации (они у тебя уже есть, оставляем)
  int? _activeVertex;
  int? _selectedVertexId;
  final Set<int> _pastVertices = {};
  final Set<String> _visitedEdges = {};

  void _showRoutesBottomSheet(BuildContext innerContext) {
    showModalBottomSheet(
      context: innerContext,
      isScrollControlled: true,
      backgroundColor: _isDarkTheme ? const Color(0xFF252525) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        // Выясняем, какой алгоритм сейчас активен и откуда брать списки
        final String algoName = _isEilerian ? 'Эйлеровых' : 'Гамильтоновых';
        final List<List<int>> cycles = _isEilerian 
            ? (_lastEilerianResult?.allCycles ?? []) 
            : (_lastHamiltonianResult?.allCycles ?? []);
        final List<List<int>> paths = _isEilerian 
            ? (_lastEilerianResult?.allPaths ?? []) 
            : (_lastHamiltonianResult?.allPaths ?? []);

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Анализ $algoName маршрутов',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                Row(
                  children: [
                    Chip(label: Text('Циклов: ${cycles.length}'), backgroundColor: Colors.green),
                    const SizedBox(width: 10),
                    Chip(label: Text('Путей: ${paths.length}'), backgroundColor: Colors.blue),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    children: [
                      if (cycles.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Найденные циклы:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                        for (var cycle in cycles)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.autorenew, color: Colors.green),
                              title: Text(cycle.join(' → ')),
                            ),
                          ),
                      ],
                      if (paths.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Найденные пути (без замыкания):',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                        for (var pathRoute in paths)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.trending_flat, color: Colors.blue),
                              title: Text(pathRoute.join(' → ')),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  void _addVertex(Offset localPosition) {
    bool isTooClose = _vertices.any(
    (v) => (v.position - localPosition).distance < 50
  );
  // ...мы просто тихо игнорируем этот тап и не плодим наслоения!
  if (isTooClose) return; 

  setState(() {
    int newId = _vertices.length;
    _vertices.add(Vertex(id: newId, position: localPosition));
    _myGraph.add([]);
  });
  }


void _deleteVertex(int id) {
  setState(() {
    // 1. Удаляем саму вершину из списка отрисовки на холсте
    _vertices.removeWhere((v) => v.id == id);
    
    // 2. Стираем все рёбра, которые вели ИЗ этой вершины
    _myGraph[id].clear();
    
    // 3. Стираем эту вершину из списков соседей у ВСЕХ остальных вершин
    for (int i = 0; i < _myGraph.length; i++) {
      _myGraph[i].remove(id);
    }
    
    // На всякий случай сбрасываем фиолетовое выделение
    if (_selectedVertexId == id) {
      _selectedVertexId = null;
    }
  });
}




// Добавляем BuildContext в параметры функции
void _startAlgorithmAnimation(BuildContext innerContext) async {
  if (_vertices.length < 2) {
    // Используем переданный внутренний контекст для плашек
    ScaffoldMessenger.of(innerContext).showSnackBar(
      const SnackBar(content: Text('Добавьте и соедините хотя бы 2 вершины!'), backgroundColor: Colors.orange),
    );
    return;
  }

  List<int> path = [];
  try {
    if (_isEilerian) {
      final result = findEilerianPath(_myGraph);
      _lastEilerianResult = result;    // Сохраняем отчёт Эйлера!
      _lastHamiltonianResult = null;   // Обнуляем Гамильтона
      path = result.animationPath;     // Маршрут для оранжевых огоньков
    } else {
      final result = findHamiltonianPath(_myGraph);
      _lastHamiltonianResult = result; // Сохраняем отчёт Гамильтона!
      _lastEilerianResult = null;      // Обнуляем Эйлера
      path = result.animationPath;
    }
  } catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(innerContext).showSnackBar(
      SnackBar(
        content: Text('Ошибка алгоритма: ${error.toString().replaceAll('ArgumentError: ', '')}'),
        backgroundColor: Colors.red,
      ),
    );
    return; 
  }

  if (path.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(innerContext).showSnackBar(
      const SnackBar(content: Text('Маршрут для данного графа не существует!'), backgroundColor: Colors.orange),
    );
    return;
  }

  // ... Твой стандартный цикл анимации (оставляем без изменений) ...
  setState(() {
    _visitedEdges.clear();
    _pastVertices.clear();
  });
  for (int i = 0; i < path.length; i++) {
    setState(() {
      if (_activeVertex != null) _pastVertices.add(_activeVertex!);
      _activeVertex = path[i];
      if (i > 0) {
        int u = path[i - 1];
        int v = path[i];
        String edgeKey = u < v ? '$u-$v' : '$v-$u';
        _visitedEdges.add(edgeKey);
      }
    });
    await Future.delayed(Duration(milliseconds: _animationSpeedMs));
  }
  setState(() {
    if (_activeVertex != null) _pastVertices.add(_activeVertex!);
    _activeVertex = null;
  });

  // В ФИНАЛЕ: Передаем этот же innerContext в шторку!
    // В самом конце функции анимации:
  if (_lastEilerianResult != null || _lastHamiltonianResult != null) {
    _showRoutesBottomSheet(innerContext);
  }

}


  // Метод отрисовки одного кружочка вершины
    Widget _buildNodeWidget(int vertexId) {
    bool isActive = _activeVertex == vertexId;
    bool isPast = _pastVertices.contains(vertexId); // Проверяем, были ли мы тут

    // Определяем тихий цвет по умолчанию в зависимости от темы
    Color defaultColor = _isDarkTheme ? Colors.grey : Colors.white;
    Color defaultBorderColor = Colors.blue;

    // Выбираем цвет фона кружка
    Color backgroundColor = isActive 
        ? Colors.orange 
        : (isPast ? Colors.red : defaultColor);

    // Выбираем цвет границы
    Color borderColor = isActive 
        ? Colors.orangeAccent 
        : (isPast ? Colors.redAccent : defaultBorderColor);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: isActive ? 4 : 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Text(
        '$vertexId',
        style: TextStyle(
          // Если вершина горит оранжевым или красным — текст белый, иначе подстраивается под тему
          color: (isActive || isPast) ? Colors.white : (_isDarkTheme ? Colors.white : Colors.black),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  @override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
    
    // Твоя светлая тема (оставляем твою глобальную настройку)
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 11, 122, 212),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 11, 122, 212),
        foregroundColor: Colors.white,
      ),
      // ... все твои настройки textTheme и inputDecorationTheme тут ...
    ),
    
    // Твоя темная тема
    darkTheme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 46, 46, 46),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 56, 56, 56),
        foregroundColor: Colors.white,
      ),
      // ... все твои настройки textTheme и inputDecorationTheme тут ...
    ),
    
    // ========================================================
    // ВОТ ОНА — НАША ИСПРАВЛЕННАЯ МАТРЁШКА BUILDER:
    // ========================================================
    home: Builder(
      builder: (BuildContext innerContext) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              Row(
                children: [
                  SizedBox(
                    width: 250,
                    height: 50,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (value) => setState(() => _animationSpeedMs = int.tryParse(value) ?? 0),
                      decoration: const InputDecoration(
                        labelText: 'Cкорость анимации, мс',
                      ),
                    ),
                  ),
                  const Icon(Icons.lightbulb),
                  Switch(
                    value: _isDarkTheme,
                    onChanged: (value) => setState(() => _isDarkTheme = value),
                  ),
                  const Text('Гамильтонов/Эйлеров путь'),
                  Switch(
                    value: _isEilerian,
                    onChanged: (value) => setState(() => _isEilerian = value),
                  ),
                  const SizedBox(width: 16),
                ],
              )
            ],
          ),
          body: Column(
            children: [
              // Твоя панель выбора режимов (Создание / Связывание / Удаление)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                child: SegmentedButton<CanvasMode>(
                  segments: const [
                    ButtonSegment<CanvasMode>(
                      value: CanvasMode.createNodes,
                      icon: Icon(Icons.add_circle_outline),
                      label: Text('Создание'),
                    ),
                    ButtonSegment<CanvasMode>(
                      value: CanvasMode.editGraph,
                      icon: Icon(Icons.gesture),
                      label: Text('Связывание'),
                    ),
                    ButtonSegment<CanvasMode>(
                      value: CanvasMode.deleteElements,
                      icon: Icon(Icons.delete_sweep_outlined),
                      label: Text('Удаление'),
                    ),
                  ],
                  selected: {_currentMode},
                  onSelectionChanged: (Set<CanvasMode> newSelection) {
                    setState(() {
                      _currentMode = newSelection.first;
                      _selectedVertexId = null;
                    });
                  },
                ),
              ),
              
              // Твоя кнопка «Старт» — теперь она безопасно шлёт innerContext наружу!
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _startAlgorithmAnimation(innerContext), // <-- Передали чистый контекст
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Запустить визуализацию'),
                ),
              ),
              
              // Твой кастомный интерактивный холст
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    if (_currentMode == CanvasMode.createNodes) {
                      _addVertex(details.localPosition);
                    } else {
                      setState(() => _selectedVertexId = null);
                    }
                  },
                  child: Container(
                    color: _isDarkTheme ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                    child: Stack(
                      children: [
                        if (_vertices.isEmpty)
                          const Center(
                            child: Text(
                              'Ткните в любое место, чтобы создать вершину',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        if (_vertices.isNotEmpty)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: EdgePainter(
                                vertices: _vertices,
                                graph: _myGraph,
                                visitedEdges: _visitedEdges,
                                isDark: _isDarkTheme,
                              ),
                            ),
                          ),
                        for (var vertex in _vertices)
                          Positioned(
                            left: vertex.position.dx - 25,
                            top: vertex.position.dy - 25,
                            child: GestureDetector(
                              onTap: () {
                                if (_currentMode == CanvasMode.editGraph) {
                                  if (_selectedVertexId == null) {
                                    setState(() => _selectedVertexId = vertex.id);
                                  } else if (_selectedVertexId == vertex.id) {
                                    setState(() => _selectedVertexId = null);
                                  } else {
                                    setState(() {
                                      if (!_myGraph[_selectedVertexId!].contains(vertex.id)) {
                                        _myGraph[_selectedVertexId!].add(vertex.id);
                                        _myGraph[vertex.id].add(_selectedVertexId!);
                                      }
                                      _selectedVertexId = vertex.id; 
                                    });
                                  }
                                } else if (_currentMode == CanvasMode.deleteElements) {
                                  if (_selectedVertexId == null) {
                                    setState(() => _selectedVertexId = vertex.id);
                                  } else if (_selectedVertexId == vertex.id) {
                                    _deleteVertex(vertex.id);
                                  } else {
                                    setState(() {
                                      _myGraph[_selectedVertexId!].remove(vertex.id);
                                      _myGraph[vertex.id].remove(_selectedVertexId!);
                                      _selectedVertexId = null;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _activeVertex == vertex.id
                                      ? Colors.orange
                                      : (_pastVertices.contains(vertex.id)
                                          ? Colors.red
                                          : (_isDarkTheme ? Colors.grey : Colors.white)),
                                  border: Border.all(
                                    color: _selectedVertexId == vertex.id
                                        ? Colors.purple
                                        : (_activeVertex == vertex.id
                                            ? Colors.orangeAccent
                                            : (_pastVertices.contains(vertex.id) ? Colors.redAccent : Colors.blue)),
                                    width: _selectedVertexId == vertex.id || _activeVertex == vertex.id ? 4 : 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${vertex.id}',
                                    style: (_activeVertex == vertex.id || _pastVertices.contains(vertex.id))
                                        ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                        : Theme.of(innerContext).textTheme.titleMedium, // И тут поменяли на innerContext для безопасности темы
                                  ),
                                ),

  ),),),],),),),),],),);}, // <-- Закрывается стрелка функции builder), // <-- Закрывается круглый скобка виджета Builder);}
    ));
    
  }
}

class Vertex {
  final int id;
  Offset position; // Координаты X и Y на холсте
  
  Vertex({required this.id, required this.position});
}

class EdgePainter extends CustomPainter {
  final List<Vertex> vertices;
  final List<List<int>> graph;
  final Set<String> visitedEdges;
  final bool isDark;

  EdgePainter({
    required this.vertices,
    required this.graph,
    required this.visitedEdges,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Настраиваем кисть для обычных рёбер (тихий серый цвет)
    final defaultPaint = Paint()
      ..color = isDark ? Colors.white30 : Colors.black26 // На белом фоне линии станут мягко-тёмными
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Настраиваем кисть для пройденных рёбер (сочный красный цвет)
    final visitedPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    // Пробегаем по нашей матрице смежности и рисуем линии
    for (int from = 0; from < graph.length; from++) {
      for (int to in graph[from]) {
        // Чтобы не рисовать одну линию дважды (ведь у нас граф неориентированный)
        if (from < to) {
          // Защита: если вдруг индексы выходят за границы списка вершин
          if (from >= vertices.length || to >= vertices.length) continue;

          // Берем экранные координаты начала и конца линии
          Offset start = vertices[from].position;
          Offset end = vertices[to].position;

          // Формируем ключ ребра (строго от меньшего ID к большему)
          String edgeKey = '$from-$to';
          bool isVisited = visitedEdges.contains(edgeKey);

          // Рисуем идеальную прямую линию БЕЗ стрелочек
          canvas.drawLine(start, end, isVisited ? visitedPaint : defaultPaint);
        }
      }
    }
  }

  // Говорим Flutter всегда перерисовывать линии, когда меняетсяvisitedEdges или координаты
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

enum CanvasMode {
  createNodes,
  editGraph,
  deleteElements,
}