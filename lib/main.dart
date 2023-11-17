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
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
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

  void moveTo(Animation<double> parent, int x, int y) {
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
  }
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
      gridHeight, (y) => List.generate(gridWidth, (x) => Tile(x, y, 0)));
  Iterable<Tile> get flattendGrid => grid.expand((row) => row);
  Iterable<List<Tile>> get columns => List.generate(
      gridWidth, (x) => List.generate(gridHeight, (y) => grid[y][x]));
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
        flattendGrid.forEach((element) {
          element.resetAnimation();
        });
      }
    });

    flattendGrid.forEach((element) => element.resetAnimation());
  }

  void moveTile(int columnPos) {
    Tile emptyTilesInColumn =
        columns.toList()[columnPos].firstWhere((element) => element.val == 0);
    toAdd.first.moveTo(controller, emptyTilesInColumn.x, emptyTilesInColumn.y);
  }

  void addTile(int columnPos) {
    Tile emptyTilesInColumn =
        columns.toList()[columnPos].firstWhere((element) => element.val == 0);
    toAdd.add(Tile(emptyTilesInColumn.x, emptyTilesInColumn.y, 2)
      ..appear(controller));
  }

  double left = 0;
  double ghostLeft = 0;
  double ghostTop = 0;

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

    Widget ghost = Positioned(
      top: ghostTop,
      left: ghostLeft,
      child: Container(
        width: tileSize,
        height: tileSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: tileBackgroundColor,
        ),
        child: TextTile("2", tileSize - gap, numTileColor[4]!),
      ),
    );

    List<Widget> stackItems = initiateBoard(flattendGrid, tileSize, gap);
    stackItems.addAll(
      [flattendGrid, toAdd].expand((e) => e).map(
            (e) => AnimatedBuilder(
              animation: controller,
              builder: (context, child) => e.animatedValue.value == 0
                  ? const SizedBox()
                  : Positioned(
                      left: e.animatedX.value * tileSize,
                      top: e.animatedY.value * tileSize,
                      width: gridWidthSize,
                      height: gridHeightSize,
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
    stackItems.add(ghost);

    return Scaffold(
      backgroundColor: tan,
      body: GestureDetector(
        onPanStart: (details) {
          left = max(0, left + details.localPosition.dx);
          addTile(calculateColumn(left));
          doSwipe();
        },
        onPanUpdate: (details) {
          left = max(0, left + details.delta.dx);
          int columnPos = calculateColumn(left);
          Tile emptyTilesInColumn = columns
              .toList()[columnPos]
              .firstWhere((element) => element.val == 0);

          ghostLeft = (emptyTilesInColumn.x * tileSize).toDouble();
          ghostTop = (emptyTilesInColumn.y * tileSize).toDouble();

          moveTile(calculateColumn(left));
          doSwipe();
        },
        onPanEnd: (details) {
          left = 0;
          toAdd.clear();
          doSwipe();
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

  void doSwipe() {
    setState(() {
      controller.forward(from: 0.0);
    });
  }

  bool canSwipeLeft() => grid.any(canSwipe);
  bool canSwipeRight() => grid.map((e) => e.reversed.toList()).any(canSwipe);
  bool canSwipeUp() => columns.any(canSwipe);
  bool canSwipeDown() => columns.map((e) => e.reversed.toList()).any(canSwipe);

  bool canSwipe(List<Tile> tiles) {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i].val == 0) {
        if (tiles.skip(i + 1).any((element) => element.val != 0)) {
          return true;
        }
      } else if (tiles[i].val != 0 && tiles[i].val == tiles[i + 1].val) {
        Tile? nextNonZero =
            tiles.skip(i + 1).firstWhereOrNull((element) => element.val != 0);
        if (nextNonZero != null && nextNonZero.val == tiles[i].val) {
          return true;
        }
      }
    }
    return false;
  }

  void swipeLeft() => grid.forEach(mergeTiles);
  void swipeRight() => grid.map((e) => e.reversed.toList()).forEach(mergeTiles);
  void swipeUp() => columns.forEach(mergeTiles);
  void swipeDown() =>
      columns.map((e) => e.reversed.toList()).forEach(mergeTiles);

  void mergeTiles(List<Tile> tiles) {
    for (int i = 0; i < tiles.length - 1; i++) {
      Iterable<Tile> toCheck =
          tiles.skip(i).skipWhile((value) => value.val == 0);
      if (toCheck.isNotEmpty) {
        Tile t = toCheck.first;
        Tile? merge =
            toCheck.skip(1).firstWhereOrNull((element) => element.val != 0);
        if (merge != null && merge.val != t.val) {
          merge = null;
        }
        if (tiles[i] != t || merge != null) {
          int resultValue = t.val;
          t.moveTo(controller, tiles[i].x, tiles[i].y);
          if (merge != null) {
            resultValue += merge.val;
            merge.moveTo(controller, tiles[i].x, tiles[i].y);
            merge.bounce(controller);
            merge.changeNumber(controller, resultValue);
            merge.val = 0;
            t.changeNumber(controller, 0);
          }
          t.val = 0;
          tiles[i].val = resultValue;
        }
      }
    }
  }
}
