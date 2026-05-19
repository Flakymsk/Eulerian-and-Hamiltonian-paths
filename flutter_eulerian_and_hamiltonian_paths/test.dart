typedef Graph = List<List<int>>;


Set<int> _findPendantVertices(Graph g){
  final pedantVertices = <int>{};
  for (int i = 0; i < g.length; ++i){
    if (g[i].length == 1){ 
      pedantVertices.add(i);
      if (pedantVertices.length > 2){
        throw ArgumentError('Граф содержит более 2 висячих вершин. Гамильтонов путь невозможен.');
      }
    }
    else if (g[i].isEmpty){
      throw ArgumentError('Граф содержит изолированную вершину $i. Гамильтонов путь невозможен.');
    }
  }
  return pedantVertices;
}


List<int> findHamiltonianPath(Graph g) {
  final pendants = _findPendantVertices(g);
  final visited = <int>{};

  final startVertices = pendants.isNotEmpty? List.from(pendants) : List.generate(g.length, (int i) => i);

  bool dfs(int vertex){
    visited.add(vertex);

    if (visited.length == g.length){
      return true;
    }

    for (int v in g[vertex]){
      if (!visited.contains(v)){
        if (dfs(v)){
          return true;
        }
      }
    }

    visited.remove(vertex);
    return false;
  }

  for (int vertex in startVertices){
      visited.clear();

      if (dfs(vertex)){
        return visited.toList();
      }
    }

  return [];
}



void main(){
  final Graph _myGraph = [
    [1, 2],
    [0, 2],
    [0, 1, 3, 4],
    [2, 4],
    [2, 3],
  ];

  print('--- Тестирование алгоритма нахождения пути Гамильтона ---');

  final path = findHamiltonianPath(_myGraph);
  
  print('Найденный Гамильтонов путь: $path');
  
}