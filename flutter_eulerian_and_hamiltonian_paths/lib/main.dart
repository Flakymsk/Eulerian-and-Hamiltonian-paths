import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_eulerian_and_hamiltonian_paths/algorithms/algorithms.dart';
import 'package:graphview/graphview.dart' as gv;

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


  List<Vertex> _vertices = [];
  
  // Наша матрица смежности (наш бэкенд-тип Graph). 
  // Индекс списка — это ID вершины, а внутри — список ID её соседей.
  List<List<int>> _myGraph = [];

  // Состояние анимации (они у тебя уже есть, оставляем)
  int? _activeVertex;
  int? _selectedVertexId;
  final Set<int> _pastVertices = {};
  final Set<String> _visitedEdges = {};

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







     void _startAlgorithmAnimation() async {
        List<int> path = [];

        try {
      path = _isEilerian 
          ? findEilerianPath(_myGraph) 
          : findHamiltonianPath(_myGraph);
    } catch (error) {
      // Если поймали throw из бэкенда — красиво выводим текст ошибки на экран
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${error.toString().replaceAll('ArgumentError: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Маршрут для данного графа не существует!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Очищаем ВСЮ историю перед новым запуском
    setState(() {
      _visitedEdges.clear();
      _pastVertices.clear(); // <-- Сбрасываем прошлые вершины
    });

        for (int i = 0; i < path.length; i++) {
      setState(() {
        if (_activeVertex != null) {
          _pastVertices.add(_activeVertex!);
        }

        _activeVertex = path[i];
        
        if (i > 0) {
          int from = path[i - 1];
          int to = path[i];
          String edgeKey = from < to ? '$from-$to' : '$to-$from';
          _visitedEdges.add(edgeKey);
        }

        // ВОТ ОНО: Перестраиваем цвета рёбер на основе обновленного множества _visitedEdges
      });

      await Future.delayed(Duration(milliseconds: _animationSpeedMs));
    }


    setState(() {
      // По окончании пути отправляем последнюю вершину тоже в прошлые
      if (_activeVertex != null) {
        _pastVertices.add(_activeVertex!);
      }
      _activeVertex = null; // Выключаем оранжевый маркер
    });
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 11, 122, 212),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 11, 122, 212),
          foregroundColor: Colors.white, // Все иконки и тексты в шапке станут белыми!
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),     // Тихий цвет подсказки
          floatingLabelStyle: TextStyle(color: Colors.white), // Яркий цвет при вводе
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),

      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 46, 46, 46),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 56, 56, 56),
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          floatingLabelStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
      
      home:Scaffold(

        appBar: AppBar(
          actions: [
            Row(
              children: [
                SizedBox(
                  width: 200,
                  height: 50,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) => setState(() => _animationSpeedMs = int.tryParse(value) ?? 500),
                    decoration: const InputDecoration(
                      labelText: 'Cкорость анимации, мс', // Текст-подсказка
                      border: UnderlineInputBorder(), // Тонкая линия снизу
                    ),
                  ),

                ),
                Icon(
                  Icons.lightbulb
                  ),
                Switch(
                  value: _isDarkTheme,
                  onChanged: (value) => setState(() => _isDarkTheme = value),
                ),
                Text(
                  'Гамильтонов/Эйлеров путь',
                ),
                Switch(
                  value: _isEilerian,
                  onChanged: (value) => setState(() => _isEilerian = value),
                  )
              ],)
          ],
        ),
        body: Column(
  children: [
    // 1. ПАНЕЛЬ ВЫБОРА РЕЖИМА ХОЛСТА (Новый элемент)
    Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: SegmentedButton<CanvasMode>(
        segments: const [
          ButtonSegment<CanvasMode>(
            value: CanvasMode.createNodes,
            icon: Icon(Icons.add_circle_outline),
            label: Text('Создание вершин'),
          ),
          ButtonSegment<CanvasMode>(
            value: CanvasMode.editGraph,
            icon: Icon(Icons.gesture),
            label: Text('Связывание / Перетаскивание'),
          ),
        ],
        selected: {_currentMode}, // Смотрим, какой режим сейчас в памяти
        onSelectionChanged: (Set<CanvasMode> newSelection) {
          setState(() {
            _currentMode = newSelection.first; // Меняем режим при клике
            _selectedVertexId = null; // На всякий случай сбрасываем фиолетовый выбор
          });
        },
      ),
    ),

    // 2. КНОПКА ЗАПУСКА АЛГОРИТМА (Твоя старая кнопка, оставляем без изменений)
    Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _startAlgorithmAnimation,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Запустить визуализацию'),
      ),
    ),
          
          Expanded(
            child: GestureDetector(
              // Нажатие по пустому месту создает новую вершину
              onTapDown: (details) {
              // Создаем вершину ТОЛЬКО в режиме создания вершин!
              if (_currentMode == CanvasMode.createNodes) {
              _addVertex(details.localPosition);
              }
               else {
                 setState(() {
                  _selectedVertexId = null;
                });
              };
              },
              child: Container(
                // Цвет фона тихо подстраивается под тему
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

                    // 1. СЛОЙ ЛИНИЙ (Твой CustomPaint без gv.Node)
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

                    // 2. СЛОЙ КРУЖОЧКОВ (Чистый цикл по твоему кастомному классу Vertex)
                    for (var vertex in _vertices)
  Positioned(
    left: vertex.position.dx - 25,
    top: vertex.position.dy - 25,
    child: GestureDetector(
      // 1. Твоя старая логика связывания вершин ребрами (оставляем без изменений)
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
        }
      },

      // 2. НОВАЯ ЛОГИКА: Ловим движение пальца для перетаскивания
      onPanUpdate: (DragUpdateDetails details) {
        // Перетаскивать можно ТОЛЬКО в режиме редактирования!
        if (_currentMode == CanvasMode.editGraph) {
          setState(() {
            // Прибавляем к текущей позиции кружка смещение пальца (delta)
            // И используем globalPosition / localPosition, чтобы плавно двигать ноду
            // Но самый надежный способ — менять позицию через дельту перемещения:
            vertex.position += details.delta;
          });
        }
      },

      // 3. НОВАЯ ЛОГИКА: Сброс фиолетового выделения при окончании движения
      onPanEnd: (details) {
        if (_currentMode == CanvasMode.editGraph) {
          setState(() {
            // Если мы тащили вершину, которая была выделена фиолетовым, 
            // лучше сбросить выбор, чтобы случайно не построить ребро
            _selectedVertexId = null;
          });
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),


        
      )
  
    );
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
  editGraph 
}