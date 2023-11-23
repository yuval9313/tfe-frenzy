import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

const int gridHeight = 8;
const int gridWidth = 5;

const double gap = 3.0;
const double borderMargin = 16.0;
const double borderPadding = 4.0;

const Color tan = Color.fromARGB(255, 243, 238, 227);
const Color boardColor = Color.fromARGB(255, 173, 167, 160);
const Color tileBackgroundColor = Color.fromARGB(255, 198, 208, 212);

const Map<int, Color> numTileColor = {
  2: Color.fromARGB(255, 242, 177, 121),
  3: Colors.pink,
  4: Color.fromARGB(255, 242, 177, 121),
  8: Color.fromARGB(255, 242, 177, 121),
  16: Color.fromARGB(255, 242, 177, 121),
  32: Color.fromARGB(255, 242, 177, 121),
  64: Color.fromARGB(255, 242, 177, 121),
  128: Color.fromARGB(255, 242, 177, 121),
  256: Color.fromARGB(255, 242, 177, 121),
  1024: Color.fromARGB(255, 242, 177, 121),
  2048: Color.fromARGB(255, 242, 177, 121),
  4096: Color.fromARGB(255, 242, 177, 121),
  8092: Color.fromARGB(255, 242, 177, 121),
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TwentyFourEightFrenzyApp());
}

class Tile {
  final int x;
  final int y;
  int val;

  late Animation<double> animatedX;
  late Animation<double> animatedY;
  late Animation<int> animatedValue;
  late Animation<double> scale;

  Tile(this.x, this.y, this.val) {
    resetAnimation();
  }

  void resetAnimation() {
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
    animatedValue = AlwaysStoppedAnimation(val);
    scale = const AlwaysStoppedAnimation(1.0);
  }

  void moveToAnimated(Animation<double> parent, int x, int y) {
    animatedX = Tween<double>(
      begin: x.toDouble(),
      end: x.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    animatedY = Tween<double>(
      begin: y.toDouble(),
      end: y.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void bounce(Animation<double> parent) {
    scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1.0),
    ]).animate(CurvedAnimation(parent: parent, curve: const Interval(0, .5)));
  }

  void appear(Animation<double> parent) {
    scale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: parent,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  void changeNumber(Animation<double> parent, int newValue) {
    animatedValue = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(val), weight: 0.01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: 0.99),
    ]).animate(CurvedAnimation(parent: parent, curve: const Interval(0, 0.5)));
    val = newValue;
  }
}

class Cluster {
  final Tile leader;
  final List<Tile> tiles;

  Cluster(this.leader, this.tiles);
}

class TwentyFourEightFrenzyApp extends StatelessWidget {
  const TwentyFourEightFrenzyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '2048 Frenzy',
      home: TwentyFourEightFrenzy(),
    );
  }
}

class TwentyFourEightFrenzy extends StatefulWidget {
  const TwentyFourEightFrenzy({super.key});

  @override
  TwentyFourEightFrenzyState createState() => TwentyFourEightFrenzyState();
}

List<Widget> initiateBoard(Iterable<Tile> flattendGrid, double tileSize, gap) {
  List<Tile> tiles = flattendGrid.toList();
  return List.generate(
    tiles.length,
    (index) => Positioned(
      left: tiles[index].x * tileSize,
      top: tiles[index].y * tileSize,
      width: tileSize,
      height: tileSize,
      child: Center(
        child: Container(
          width: tileSize - gap,
          height: tileSize - gap,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            color: tileBackgroundColor,
          ),
        ),
      ),
    ),
  );
}

class TextTile extends StatelessWidget {
  final String value;
  final double tileSize;
  final Color tileBackgroundColor;

  const TextTile(this.value, this.tileSize, this.tileBackgroundColor,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tileSize,
      height: tileSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        color: tileBackgroundColor,
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class TwentyFourEightFrenzyState extends State<TwentyFourEightFrenzy>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  List<List<Tile>> grid = List.generate(
      gridWidth, (x) => List.generate(gridHeight, (y) => Tile(x, y, 0)));

  Iterable<Tile> get flattendGrid => grid.expand((col) => col);

  List<Tile> toAdd = [];

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        for (var element in flattendGrid) {
          element.resetAnimation();
        }
      }
    });

    grid[0][0].val = 16;
    grid[0][1].val = 4;
    grid[0][2].val = 16;
    grid[1][0].val = 4;
    grid[2][0].val = 8;

    for (var element in flattendGrid) {
      element.resetAnimation();
    }
  }

  void addTile(int columnPos) {
    toAdd.clear();
    Tile emptyTilesInColumn =
        grid[columnPos].firstWhere((element) => element.val == 0);
    toAdd.add(Tile(emptyTilesInColumn.x, emptyTilesInColumn.y, 4));
    toAdd.first
        .moveToAnimated(controller, emptyTilesInColumn.x, emptyTilesInColumn.y);
  }

  void moveColumn(int columnPos) {
    Tile? emptyTilesInColumn =
        grid[columnPos].firstWhereOrNull((element) => element.val == 0);
    if (emptyTilesInColumn == null || emptyTilesInColumn.y == gridHeight - 1) {
      return;
    }
    Iterable<Tile> tilesInColumn = grid[columnPos]
        .skip(emptyTilesInColumn.y + 1)
        .takeWhile((element) => element.val != 0);
    for (var element in tilesInColumn) {
      element.moveToAnimated(controller, element.x, element.y - 1);
      grid[element.x][max(0, element.y - 1)]
          .changeNumber(controller, element.val);
      element.changeNumber(controller, 0);
    }
  }

  double left = 0;

  @override
  Widget build(BuildContext context) {
    double tileSize =
        (MediaQuery.of(context).size.width - borderMargin - gap) / gridWidth;
    double gridWidthSize = (tileSize * gridWidth) + gridWidth;
    double gridHeightSize = (tileSize * gridHeight) + borderPadding + gap;

    int calculateColumn(double left) {
      int columnPos = (left / tileSize).floor();
      if (columnPos >= gridWidth) {
        columnPos = gridWidth - 1;
      }
      return columnPos;
    }

    List<Widget> stackItems = initiateBoard(flattendGrid, tileSize, gap)
      ..addAll(
        [flattendGrid, toAdd].expand((e) => e).map(
              (e) => AnimatedBuilder(
                animation: controller,
                builder: (context, child) => e.animatedValue.value == 0
                    ? const SizedBox()
                    : Positioned(
                        left: e.animatedX.value * tileSize,
                        top: e.animatedY.value * tileSize,
                        width: tileSize,
                        height: tileSize,
                        child: Center(
                          child: TextTile(
                            "${e.animatedValue.value}",
                            (tileSize - gap) * e.scale.value,
                            numTileColor[e.animatedValue.value]!,
                          ),
                        ),
                      ),
              ),
            ),
      );

    return Scaffold(
      backgroundColor: tan,
      body: GestureDetector(
        onPanStart: (details) {
          if (toAdd.isEmpty) {
            left = max(0, left + details.localPosition.dx);
            addTile(calculateColumn(left));
            setState(() {
              controller.forward(from: 0.0);
            });
          }
        },
        onPanUpdate: (details) {
          left = max(0, left + details.delta.dx);
          addTile(calculateColumn(left));
          setState(() {
            controller.forward(from: 0.0);
          });
        },
        onPanEnd: (details) {
          if (toAdd.isNotEmpty) {
            left = 0;
            doSwipe(toAdd.first);
            toAdd.clear();
          }
        },
        child: Container(
          padding: const EdgeInsets.only(top: borderPadding + gap),
          child: Column(children: [
            Center(
              child: Container(
                width: gridWidthSize,
                height: gridHeightSize,
                padding: const EdgeInsets.all(borderPadding),
                decoration: BoxDecoration(
                  color: boardColor,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(children: stackItems),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: gap + borderPadding),
              child: Center(
                child: TextTile("2", tileSize - gap, numTileColor[4]!),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  List<Tile> calculateToCheck(Tile original) {
    int beforeCol = max(0, original.x - 1);
    int beforeRow = max(0, original.y - 1);
    int afterCol = min(gridWidth - 1, original.x + 1);

    List<Tile> toCheck = [
      grid[beforeCol][original.y],
      grid[original.x][beforeRow],
      grid[afterCol][original.y],
    ];
    return toCheck;
  }

  void doSwipe(Tile original) {
    List<Tile> toCheck = calculateToCheck(original);
    setState(() {
      mergeTiles(original, toCheck);
      controller.forward(from: 0.0);
      for (int i = 0; i < gridWidth; i++) {
        moveColumn(i);
      }
      List<Cluster> clusters = findClusters();
      if (clusters.isNotEmpty) {
        mergeClusters(clusters);
      }
      controller.forward(from: 0.0);
    });
  }

  void mergeTiles(Tile original, List<Tile> toCheck) {
    Iterable<Tile> mergable = toCheck
        .where((element) => element.val != 0 && element.val == original.val);

    int resultValue = original.val;
    for (var element in mergable) {
      if (element != original) {
        resultValue *= 2;
        element.moveToAnimated(controller, original.x, original.y);
        element.changeNumber(controller, 0);
      }
    }
    if (resultValue != original.val) {
      original.bounce(controller);
    }
    grid[original.x][original.y].changeNumber(controller, resultValue);
  }

  List<Cluster> findClusters() {
    List<Cluster> clusters = [];
    Set<Tile> visited = {};

    for (var column in grid) {
      for (var element in column) {
        if (visited.contains(element)) {
          continue;
        }

        List<Tile> adjecentTiles = [];
        List<Map<String, int>> checksPoints = [
          {"y": element.y, "x": max(0, element.x - 1)},
          {"y": element.y, "x": min(gridWidth - 1, element.x + 1)},
          {"x": element.x, "y": max(0, element.y - 1)},
          {"x": element.x, "y": min(gridHeight - 1, element.y + 1)},
        ];

        for (var check in checksPoints) {
          Tile tile = grid[check['x']!][check['y']!];
          if (tile.val != 0 && tile.val == element.val && tile != element) {
            adjecentTiles.add(tile);
          }
        }

        if (adjecentTiles.length > 1) {
          adjecentTiles.add(element);
          adjecentTiles.sort((tile1, tile2) =>
              countAdjacentTiles(tile2).compareTo(countAdjacentTiles(tile1)));
          Tile leader = adjecentTiles.first;
          clusters.add(Cluster(leader, adjecentTiles));
          visited.add(leader);
          visited.addAll(adjecentTiles);
        }
      }
    }

    return clusters;
  }

  int countAdjacentTiles(Tile tile) {
    int count = 0;
    if (tile.x > 0 && grid[tile.x - 1][tile.y].val == tile.val) count++;
    if (tile.x < gridWidth - 1 && grid[tile.x + 1][tile.y].val == tile.val)
      count++;
    if (tile.y > 0 && grid[tile.x][tile.y - 1].val == tile.val) count++;
    if (tile.y < gridHeight - 1 && grid[tile.x][tile.y + 1].val == tile.val)
      count++;
    return count;
  }

  void mergeClusters(List<Cluster> clusters) {
    for (Cluster cluster in clusters) {
      int resultValue = cluster.leader.val * (2 ^ cluster.tiles.length);
      for (Tile tile in cluster.tiles) {
        grid[tile.x][tile.y]
            .moveToAnimated(controller, cluster.leader.x, cluster.leader.y);
        grid[tile.x][tile.y].changeNumber(controller, 0);
      }
      grid[cluster.leader.x][cluster.leader.y]
          .changeNumber(controller, resultValue);
    }
  }
}
