import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../core/formatters.dart';
import '../widgets/nope_components.dart';

class FocusLockScreen extends StatefulWidget {
  const FocusLockScreen({super.key, required this.controller});
  final FocusController controller;

  @override
  State<FocusLockScreen> createState() => _FocusLockScreenState();
}

class _FocusLockScreenState extends State<FocusLockScreen> {
  bool solving = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: scheme.onSurface,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: solving
                ? PuzzleGate(
                    key: const ValueKey('puzzles'),
                    controller: widget.controller,
                    onCancel: () => setState(() => solving = false),
                  )
                : _LockView(
                    key: const ValueKey('lock'),
                    controller: widget.controller,
                    onRequestPause: () => setState(() => solving = true),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LockView extends StatelessWidget {
  const _LockView({
    super.key,
    required this.controller,
    required this.onRequestPause,
  });
  final FocusController controller;
  final VoidCallback onRequestPause;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.surface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const NopeWordmark(inverse: true),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: foreground.withValues(alpha: .35)),
                ),
                child: Text(
                  'SESIÓN ACTIVA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            controller.currentLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground.withValues(alpha: .62),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 28),
          _FocusClock(controller: controller),
          const SizedBox(height: 24),
          Text(
            '${formatDuration(controller.remaining)} RESTANTES',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground.withValues(alpha: .65),
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            'DISPONIBLE AHORA',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground.withValues(alpha: .55),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EssentialButton(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                onTap: () => _launch(context, 'phone'),
              ),
              const SizedBox(width: 18),
              _EssentialButton(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'SMS',
                onTap: () => _launch(context, 'sms'),
              ),
              const SizedBox(width: 18),
              _EssentialButton(
                icon: Icons.forum_outlined,
                label: 'WhatsApp',
                onTap: () => _launch(context, 'whatsapp'),
              ),
            ],
          ),
          const SizedBox(height: 34),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRequestPause,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground.withValues(alpha: .34)),
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Text('NECESITO UNA PAUSA'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '5 retos · pausa de 5 minutos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String target) async {
    final launched = await controller.launchEssential(target);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La aplicación no está disponible.')),
      );
    }
  }
}

class _EssentialButton extends StatelessWidget {
  const _EssentialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.surface;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: foreground.withValues(alpha: .34)),
          ),
          child: Icon(icon, color: foreground, size: 23),
        ),
      ),
    );
  }
}

class _FocusClock extends StatelessWidget {
  const _FocusClock({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    return switch (controller.clockStyle) {
      ClockStyle.digital => _DigitalClock(now: controller.now),
      ClockStyle.analog => _AnalogClock(now: controller.now),
      ClockStyle.hourglass => _HourglassClock(controller: controller),
    };
  }
}

class _DigitalClock extends StatelessWidget {
  const _DigitalClock({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final value =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';
    return Text(
      value,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        color: Theme.of(context).colorScheme.surface,
        fontSize: 88,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _AnalogClock extends StatelessWidget {
  const _AnalogClock({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 210,
      child: CustomPaint(
        painter: _AnalogClockPainter(
          now: now,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  const _AnalogClockPainter({required this.now, required this.color});
  final DateTime now;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final outline = Paint()
      ..color = color.withValues(alpha: .42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, radius - 2, outline);
    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final angle = i * math.pi / 30 - math.pi / 2;
      final outer = Offset(
        center.dx + math.cos(angle) * (radius - 12),
        center.dy + math.sin(angle) * (radius - 12),
      );
      final inner = Offset(
        center.dx + math.cos(angle) * (radius - (major ? 25 : 17)),
        center.dy + math.sin(angle) * (radius - (major ? 25 : 17)),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = color.withValues(alpha: major ? .8 : .35)
          ..strokeWidth = major ? 2.2 : 1,
      );
    }
    final minuteAngle =
        (now.minute + now.second / 60) * math.pi / 30 - math.pi / 2;
    final hourAngle =
        (now.hour % 12 + now.minute / 60) * math.pi / 6 - math.pi / 2;
    _hand(canvas, center, hourAngle, radius * .48, 5);
    _hand(canvas, center, minuteAngle, radius * .7, 3);
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  void _hand(
    Canvas canvas,
    Offset center,
    double angle,
    double length,
    double width,
  ) {
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(angle) * length,
        center.dy + math.sin(angle) * length,
      ),
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) =>
      oldDelegate.now.second != now.second || oldDelegate.color != color;
}

class _HourglassClock extends StatelessWidget {
  const _HourglassClock({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final totalSeconds =
        controller.manualStartedAt != null && controller.manualEndsAt != null
        ? controller.manualEndsAt!
              .difference(controller.manualStartedAt!)
              .inSeconds
        : (controller.activeSchedule?.durationMinutes ?? 1) * 60;
    final progress = totalSeconds <= 0
        ? 0.0
        : (controller.remaining.inSeconds / totalSeconds).clamp(0.0, 1.0);
    return SizedBox(
      width: 190,
      height: 220,
      child: CustomPaint(
        painter: _HourglassPainter(
          progress: progress,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final left = size.width * .18;
    final right = size.width * .82;
    final top = 18.0;
    final bottom = size.height - 18;
    final middle = size.height / 2;
    canvas.drawLine(Offset(left, top), Offset(right, top), stroke);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), stroke);
    final glass = Path()
      ..moveTo(left + 8, top + 8)
      ..quadraticBezierTo(left + 15, middle - 28, size.width / 2, middle)
      ..quadraticBezierTo(right - 15, middle + 28, right - 8, bottom - 8)
      ..moveTo(right - 8, top + 8)
      ..quadraticBezierTo(right - 15, middle - 28, size.width / 2, middle)
      ..quadraticBezierTo(left + 15, middle + 28, left + 8, bottom - 8);
    canvas.drawPath(glass, stroke);
    final fill = Paint()..color = color.withValues(alpha: .82);
    final topSandHeight = (middle - top - 28) * progress;
    final topSand = Path()
      ..moveTo(left + 18, middle - 20 - topSandHeight)
      ..lineTo(right - 18, middle - 20 - topSandHeight)
      ..lineTo(size.width / 2, middle - 4)
      ..close();
    if (progress > .02) canvas.drawPath(topSand, fill);
    final bottomProgress = 1 - progress;
    final bottomSand = Path()
      ..moveTo(left + 16, bottom - 10)
      ..lineTo(right - 16, bottom - 10)
      ..lineTo(
        size.width / 2 + (right - left) * .28 * bottomProgress,
        bottom - 10 - (middle - 30) * bottomProgress,
      )
      ..lineTo(
        size.width / 2 - (right - left) * .28 * bottomProgress,
        bottom - 10 - (middle - 30) * bottomProgress,
      )
      ..close();
    canvas.drawPath(bottomSand, fill);
    if (progress > .02 && progress < .98) {
      canvas.drawLine(
        Offset(size.width / 2, middle),
        Offset(size.width / 2, bottom - 25),
        Paint()
          ..color = color.withValues(alpha: .7)
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class PuzzleGate extends StatefulWidget {
  const PuzzleGate({
    super.key,
    required this.controller,
    required this.onCancel,
  });
  final FocusController controller;
  final VoidCallback onCancel;

  @override
  State<PuzzleGate> createState() => _PuzzleGateState();
}

class _PuzzleGateState extends State<PuzzleGate> {
  final factory = PuzzleFactory();
  late List<PuzzleChallenge> challenges;
  int index = 0;
  int mistakes = 0;

  @override
  void initState() {
    super.initState();
    challenges = factory.generateSet();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = scheme.surface;
    final challenge = challenges[index];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onCancel,
                tooltip: 'Volver al foco',
                style: IconButton.styleFrom(foregroundColor: foreground),
                icon: const Icon(Icons.close_rounded),
              ),
              const Spacer(),
              Text(
                '${index + 1} / 5',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(
              5,
              (position) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: position == 4 ? 0 : 7),
                  decoration: BoxDecoration(
                    color: position < index
                        ? foreground
                        : foreground.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            challenge.label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground.withValues(alpha: .55),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            challenge.prompt,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: foreground,
              height: 1.08,
            ),
          ),
          if (mistakes > 0) ...[
            const SizedBox(height: 14),
            Text(
              'Respuesta incorrecta. Nuevo reto.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: foreground.withValues(alpha: .62),
              ),
            ),
          ],
          const Spacer(),
          ...challenge.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _answer(option),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: foreground,
                    side: BorderSide(color: foreground.withValues(alpha: .3)),
                    minimumSize: const Size(0, 58),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    option,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: foreground),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Puedes cerrar y volver a tu sesión en cualquier momento.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground.withValues(alpha: .45),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _answer(String option) async {
    if (option != challenges[index].answer) {
      setState(() {
        mistakes++;
        challenges[index] = factory.generate(index);
      });
      return;
    }
    if (index == 4) {
      await widget.controller.pauseAfterPuzzles();
      return;
    }
    setState(() {
      index++;
      mistakes = 0;
    });
  }
}

class PuzzleChallenge {
  const PuzzleChallenge({
    required this.label,
    required this.prompt,
    required this.options,
    required this.answer,
  });

  final String label;
  final String prompt;
  final List<String> options;
  final String answer;
}

class PuzzleFactory {
  PuzzleFactory() : _random = math.Random();
  final math.Random _random;

  List<PuzzleChallenge> generateSet() =>
      List.generate(5, (index) => generate(index));

  PuzzleChallenge generate(int kind) {
    return switch (kind % 5) {
      0 => _calculation(),
      1 => _series(),
      2 => _logic(),
      3 => _attention(),
      _ => _order(),
    };
  }

  PuzzleChallenge _calculation() {
    final a = 4 + _random.nextInt(6);
    final b = 3 + _random.nextInt(7);
    final c = 2 + _random.nextInt(9);
    final answer = a * b + c;
    return PuzzleChallenge(
      label: 'CÁLCULO',
      prompt: '$a × $b + $c',
      options: _numberOptions(answer, spread: 5),
      answer: '$answer',
    );
  }

  PuzzleChallenge _series() {
    final start = 2 + _random.nextInt(7);
    final step = 3 + _random.nextInt(6);
    final values = List.generate(4, (index) => start + step * index);
    final answer = start + step * 4;
    return PuzzleChallenge(
      label: 'SERIE',
      prompt: '${values.join('  ·  ')}  ·  ?',
      options: _numberOptions(answer, spread: step),
      answer: '$answer',
    );
  }

  PuzzleChallenge _logic() {
    final letters = ['A', 'B', 'C']..shuffle(_random);
    final first = letters[0];
    final second = letters[1];
    final third = letters[2];
    final answer = '$first es mayor';
    final options = [
      answer,
      '$second es mayor',
      '$third es mayor',
      'No se puede saber',
    ]..shuffle(_random);
    return PuzzleChallenge(
      label: 'LÓGICA',
      prompt: '$first > $second y $second > $third. ¿Qué es cierto?',
      options: options,
      answer: answer,
    );
  }

  PuzzleChallenge _attention() {
    const phrases = [
      'NOPE PONE ORDEN DONDE HABÍA RUIDO',
      'POCO A POCO TODO TOMA FORMA',
      'HOY SOLO IMPORTA LO PRIORITARIO',
    ];
    final phrase = phrases[_random.nextInt(phrases.length)];
    final count = 'O'.allMatches(phrase).length;
    return PuzzleChallenge(
      label: 'ATENCIÓN',
      prompt: '¿Cuántas letras O hay?\n\n$phrase',
      options: _numberOptions(count, spread: 2),
      answer: '$count',
    );
  }

  PuzzleChallenge _order() {
    final values = <int>{};
    while (values.length < 5) {
      values.add(10 + _random.nextInt(80));
    }
    final list = values.toList()..shuffle(_random);
    final sorted = [...list]..sort((a, b) => b.compareTo(a));
    final answer = sorted[1];
    final options = list.map((value) => '$value').toList()..shuffle(_random);
    final visibleOptions = options.take(4).toList();
    if (!visibleOptions.contains('$answer')) {
      visibleOptions[_random.nextInt(visibleOptions.length)] = '$answer';
    }
    visibleOptions.shuffle(_random);
    return PuzzleChallenge(
      label: 'ORDEN',
      prompt: 'Elige el segundo número más alto.\n\n${list.join('  ·  ')}',
      options: visibleOptions,
      answer: '$answer',
    );
  }

  List<String> _numberOptions(int answer, {required int spread}) {
    final values = <int>{answer};
    while (values.length < 4) {
      final offset = _random.nextInt(spread * 2 + 1) - spread;
      final minimum = answer >= 10 ? 10 : 0;
      if (offset != 0 && answer + offset >= minimum) {
        values.add(answer + offset);
      }
    }
    return values.map((value) => '$value').toList()..shuffle(_random);
  }
}
