import 'dart:math' as math;

import 'package:flutter/material.dart';

class SudokuMiniGame extends StatefulWidget {
  const SudokuMiniGame({
    super.key,
    required this.foreground,
    required this.onSolved,
  });

  final Color foreground;
  final VoidCallback onSolved;

  @override
  State<SudokuMiniGame> createState() => _SudokuMiniGameState();
}

class _SudokuMiniGameState extends State<SudokuMiniGame> {
  final _random = math.Random();
  late List<int> _solution;
  late List<int?> _board;
  late Set<int> _editable;
  int? _selected;
  bool _mistake = false;

  @override
  void initState() {
    super.initState();
    _createBoard();
  }

  void _createBoard() {
    final symbols = [1, 2, 3, 4]..shuffle(_random);
    final rowOrder = _permutedGroups();
    final columnOrder = _permutedGroups();
    _solution = [
      for (final row in rowOrder)
        for (final column in columnOrder)
          symbols[(row * 2 + row ~/ 2 + column) % 4],
    ];
    final hidden = List.generate(16, (index) => index)..shuffle(_random);
    _editable = hidden.take(7).toSet();
    _board = List<int?>.generate(
      16,
      (index) => _editable.contains(index) ? null : _solution[index],
    );
    _selected = _editable.first;
  }

  List<int> _permutedGroups() {
    final groups = [0, 1]..shuffle(_random);
    return [
      for (final group in groups)
        ...([0, 1]..shuffle(_random)).map((offset) => group * 2 + offset),
    ];
  }

  void _enter(int value) {
    final selected = _selected;
    if (selected == null) return;
    if (_solution[selected] != value) {
      setState(() => _mistake = true);
      return;
    }
    setState(() {
      _board[selected] = value;
      _mistake = false;
      _selected = _editable.firstWhere(
        (index) => _board[index] == null,
        orElse: () => -1,
      );
      if (_selected == -1) _selected = null;
    });
    if (_board.every((value) => value != null)) {
      Future<void>.delayed(const Duration(milliseconds: 220), widget.onSolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.foreground.withValues(alpha: .25);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Completa las casillas vacías sin repetir números.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.foreground.withValues(alpha: .68),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox.square(
          dimension: 216,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: 16,
            itemBuilder: (context, index) {
              final selected = _selected == index;
              final editable = _editable.contains(index);
              return InkWell(
                onTap: editable && _board[index] == null
                    ? () => setState(() {
                        _selected = index;
                        _mistake = false;
                      })
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? widget.foreground.withValues(alpha: .18)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: line,
                        width: index % 4 == 0 ? 2 : .7,
                      ),
                      top: BorderSide(
                        color: line,
                        width: index ~/ 4 == 0 ? 2 : .7,
                      ),
                      right: BorderSide(
                        color: line,
                        width: index % 4 == 3 || index % 4 == 1 ? 2 : .7,
                      ),
                      bottom: BorderSide(
                        color: line,
                        width: index ~/ 4 == 3 || index ~/ 4 == 1 ? 2 : .7,
                      ),
                    ),
                  ),
                  child: Text(
                    _board[index]?.toString() ?? '',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: widget.foreground.withValues(
                        alpha: editable ? 1 : .55,
                      ),
                      fontWeight: editable ? FontWeight.w900 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final value = index + 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: OutlinedButton(
                onPressed: () => _enter(value),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.foreground,
                  side: BorderSide(color: line),
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text('$value'),
              ),
            );
          }),
        ),
        SizedBox(
          height: 28,
          child: _mistake
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Ese número no corresponde.',
                    style: TextStyle(
                      color: widget.foreground.withValues(alpha: .62),
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class WordSearchMiniGame extends StatefulWidget {
  const WordSearchMiniGame({
    super.key,
    required this.foreground,
    required this.onSolved,
  });

  final Color foreground;
  final VoidCallback onSolved;

  @override
  State<WordSearchMiniGame> createState() => _WordSearchMiniGameState();
}

class _WordSearchMiniGameState extends State<WordSearchMiniGame> {
  static const _size = 6;
  static const _words = ['FOCO', 'ORDEN', 'CLASE', 'META', 'CALMA'];
  final _random = math.Random();
  late String _word;
  late List<String> _letters;
  late List<int> _path;
  int _progress = 0;
  bool _mistake = false;

  @override
  void initState() {
    super.initState();
    _createGrid();
  }

  void _createGrid() {
    _word = _words[_random.nextInt(_words.length)];
    const directions = [(1, 0), (0, 1), (1, 1), (-1, 1)];
    late (int, int) direction;
    late int startRow;
    late int startColumn;
    while (true) {
      direction = directions[_random.nextInt(directions.length)];
      startRow = _random.nextInt(_size);
      startColumn = _random.nextInt(_size);
      final endRow = startRow + direction.$2 * (_word.length - 1);
      final endColumn = startColumn + direction.$1 * (_word.length - 1);
      if (endRow >= 0 &&
          endRow < _size &&
          endColumn >= 0 &&
          endColumn < _size) {
        break;
      }
    }
    const alphabet = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';
    _letters = List.generate(
      _size * _size,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    );
    _path = [];
    for (var index = 0; index < _word.length; index++) {
      final row = startRow + direction.$2 * index;
      final column = startColumn + direction.$1 * index;
      final cell = row * _size + column;
      _path.add(cell);
      _letters[cell] = _word[index];
    }
  }

  void _select(int index) {
    if (_progress >= _path.length) return;
    if (index != _path[_progress]) {
      setState(() {
        _progress = 0;
        _mistake = true;
      });
      return;
    }
    final solved = _progress == _path.length - 1;
    setState(() {
      _progress++;
      _mistake = false;
    });
    if (solved) {
      Future<void>.delayed(const Duration(milliseconds: 220), widget.onSolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Encuentra $_word y toca sus letras en orden.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.foreground.withValues(alpha: .7),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox.square(
          dimension: 282,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _size,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: _letters.length,
            itemBuilder: (context, index) {
              final selected = _path.take(_progress).contains(index);
              return InkWell(
                onTap: () => _select(index),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? widget.foreground
                        : widget.foreground.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.foreground.withValues(alpha: .22),
                    ),
                  ),
                  child: Text(
                    _letters[index],
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF121716)
                          : widget.foreground,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 30,
          child: _mistake
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'La secuencia se reinició.',
                    style: TextStyle(
                      color: widget.foreground.withValues(alpha: .62),
                      fontSize: 12,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class ConnectDotsMiniGame extends StatefulWidget {
  const ConnectDotsMiniGame({
    super.key,
    required this.foreground,
    required this.onSolved,
  });

  final Color foreground;
  final VoidCallback onSolved;

  @override
  State<ConnectDotsMiniGame> createState() => _ConnectDotsMiniGameState();
}

class _ConnectDotsMiniGameState extends State<ConnectDotsMiniGame> {
  final _random = math.Random();
  late List<Offset> _points;
  int _progress = 0;
  bool _mistake = false;

  @override
  void initState() {
    super.initState();
    final rotation = _random.nextDouble() * math.pi * 2;
    const normalized = [
      Offset(.18, .22),
      Offset(.72, .13),
      Offset(.86, .47),
      Offset(.62, .82),
      Offset(.20, .76),
      Offset(.38, .47),
      Offset(.54, .33),
    ];
    _points = normalized.map((point) {
      final centered = point - const Offset(.5, .5);
      final rotated = Offset(
        centered.dx * math.cos(rotation) - centered.dy * math.sin(rotation),
        centered.dx * math.sin(rotation) + centered.dy * math.cos(rotation),
      );
      return rotated + const Offset(.5, .5);
    }).toList();
  }

  void _tap(Offset localPosition, Size size) {
    if (_progress >= _points.length) return;
    var nearest = -1;
    var nearestDistance = double.infinity;
    for (var index = 0; index < _points.length; index++) {
      final point = Offset(
        _points[index].dx * size.width,
        _points[index].dy * size.height,
      );
      final distance = (point - localPosition).distance;
      if (distance < nearestDistance) {
        nearest = index;
        nearestDistance = distance;
      }
    }
    if (nearestDistance > 30 || nearest != _progress) {
      setState(() {
        _progress = 0;
        _mistake = true;
      });
      return;
    }
    final solved = _progress == _points.length - 1;
    setState(() {
      _progress++;
      _mistake = false;
    });
    if (solved) {
      Future<void>.delayed(const Duration(milliseconds: 220), widget.onSolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Toca los puntos del 1 al 7. Un error reinicia el trazo.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.foreground.withValues(alpha: .7),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _tap(details.localPosition, size),
                child: CustomPaint(
                  size: size,
                  painter: _ConnectDotsPainter(
                    points: _points,
                    progress: _progress,
                    color: widget.foreground,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 28,
          child: _mistake
              ? Text(
                  'Vuelve a comenzar por el punto 1.',
                  style: TextStyle(
                    color: widget.foreground.withValues(alpha: .62),
                    fontSize: 12,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}

class _ConnectDotsPainter extends CustomPainter {
  const _ConnectDotsPainter({
    required this.points,
    required this.progress,
    required this.color,
  });

  final List<Offset> points;
  final int progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final resolved = points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList();
    final line = Paint()
      ..color = color.withValues(alpha: .75)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var index = 1; index < progress; index++) {
      canvas.drawLine(resolved[index - 1], resolved[index], line);
    }
    for (var index = 0; index < resolved.length; index++) {
      final completed = index < progress;
      canvas.drawCircle(
        resolved[index],
        completed ? 15 : 13,
        Paint()
          ..color = completed ? color : Colors.transparent
          ..style = completed ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      if (!completed) {
        canvas.drawCircle(
          resolved[index],
          13,
          Paint()
            ..color = color.withValues(alpha: .75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${index + 1}',
          style: TextStyle(
            color: completed ? const Color(0xFF121716) : color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        resolved[index] - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectDotsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
