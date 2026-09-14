import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../core/formatters.dart';
import '../theme/nope_theme.dart';
import '../widgets/focus_minigames.dart';
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
    final background = NopeTheme.focusBackground(
      widget.controller.paletteIndex,
    );
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: widget.controller.isPaused
                ? _PauseView(
                    key: const ValueKey('pause'),
                    controller: widget.controller,
                  )
                : solving
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
    const foreground = NopeTheme.focusForeground;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
          const SizedBox(height: 24),
          _FocusClock(controller: controller),
          const SizedBox(height: 20),
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
          const SizedBox(height: 12),
          _EssentialActions(controller: controller),
          const SizedBox(height: 28),
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
            '10 retos · pausa de 5 minutos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: .5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseView extends StatelessWidget {
  const _PauseView({super.key, required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    const foreground = NopeTheme.focusForeground;
    final pauseRemaining = controller.pausedUntil?.difference(controller.now);
    final safeRemaining = pauseRemaining == null || pauseRemaining.isNegative
        ? Duration.zero
        : pauseRemaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: NopeWordmark(inverse: true),
          ),
          const Spacer(),
          Icon(
            Icons.pause_rounded,
            color: foreground.withValues(alpha: .55),
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            'PAUSA ACTIVA',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground.withValues(alpha: .64),
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            formatDuration(safeRemaining),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: foreground,
              fontSize: 76,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tómate estos minutos con intención. El bloqueo volverá de forma '
            'automática al terminar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: foreground.withValues(alpha: .68),
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
          const SizedBox(height: 12),
          _EssentialActions(controller: controller),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: controller.resumeFocusNow,
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground.withValues(alpha: .34)),
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: const Text('VOLVER AL FOCO AHORA'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialActions extends StatelessWidget {
  const _EssentialActions({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final actions = <({IconData icon, String label, String target})>[
      (icon: Icons.phone_outlined, label: 'Teléfono', target: 'phone'),
      (icon: Icons.chat_bubble_outline_rounded, label: 'SMS', target: 'sms'),
      (icon: Icons.forum_outlined, label: 'WhatsApp', target: 'whatsapp'),
      if (controller.authenticatorAvailable)
        (
          icon: Icons.security_outlined,
          label: 'Authenticator',
          target: 'authenticator',
        ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          _EssentialButton(
            icon: actions[index].icon,
            label: actions[index].label,
            onTap: () => _launch(context, actions[index].target),
          ),
        ],
      ],
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
    const foreground = NopeTheme.focusForeground;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: foreground.withValues(alpha: .34)),
          ),
          child: Icon(icon, color: foreground, size: 22),
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
        color: NopeTheme.focusForeground,
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
          color: NopeTheme.focusForeground,
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
    final phase =
        (controller.now.second + controller.now.millisecond / 1000) % 1;
    return SizedBox(
      width: 184,
      height: 218,
      child: CustomPaint(
        painter: _HourglassPainter(
          progress: progress,
          phase: phase,
          color: NopeTheme.focusForeground,
        ),
      ),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  const _HourglassPainter({
    required this.progress,
    required this.phase,
    required this.color,
  });
  final double progress;
  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final middle = size.height / 2;
    final left = size.width * .2;
    final right = size.width * .8;
    const top = 19.0;
    final bottom = size.height - 19;
    final chamberTop = top + 13;
    final chamberBottom = bottom - 13;
    final glass = Path()
      ..moveTo(left + 8, chamberTop)
      ..cubicTo(
        left + 9,
        middle - 48,
        centerX - 17,
        middle - 12,
        centerX,
        middle,
      )
      ..cubicTo(
        centerX - 17,
        middle + 12,
        left + 9,
        middle + 48,
        left + 8,
        chamberBottom,
      )
      ..lineTo(right - 8, chamberBottom)
      ..cubicTo(
        right - 9,
        middle + 48,
        centerX + 17,
        middle + 12,
        centerX,
        middle,
      )
      ..cubicTo(
        centerX + 17,
        middle - 12,
        right - 9,
        middle - 48,
        right - 8,
        chamberTop,
      )
      ..close();

    final sand = Paint()..color = color.withValues(alpha: .78);
    final chamberHeight = middle - chamberTop - 7;
    canvas.save();
    canvas.clipPath(glass);
    if (progress > .005) {
      final upperSurface = middle - 6 - chamberHeight * progress;
      canvas.drawRect(
        Rect.fromLTRB(left, upperSurface, right, middle - 4),
        sand,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, upperSurface),
          width: (right - left) * (.25 + .68 * progress),
          height: 5,
        ),
        Paint()..color = color.withValues(alpha: .9),
      );
    }
    final lowerProgress = 1 - progress;
    if (lowerProgress > .005) {
      final lowerSurface = chamberBottom - chamberHeight * lowerProgress;
      canvas.drawRect(
        Rect.fromLTRB(left, lowerSurface, right, chamberBottom + 2),
        sand,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(centerX, lowerSurface),
          width: (right - left) * (.25 + .68 * lowerProgress),
          height: 5,
        ),
        Paint()..color = color.withValues(alpha: .9),
      );
    }
    if (progress > .005 && progress < .995) {
      canvas.drawLine(
        Offset(centerX, middle - 1),
        Offset(centerX, chamberBottom - 8),
        Paint()
          ..color = color.withValues(alpha: .82)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      for (var grain = 0; grain < 3; grain++) {
        final grainPhase = (phase + grain / 3) % 1;
        canvas.drawCircle(
          Offset(centerX + (grain - 1) * 1.3, middle + 7 + grainPhase * 60),
          1.25,
          Paint()..color = color.withValues(alpha: .72),
        );
      }
    }
    canvas.restore();

    final frame = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(glass, frame..color = color.withValues(alpha: .8));
    frame.color = color;
    canvas.drawLine(Offset(left - 8, top), Offset(right + 8, top), frame);
    canvas.drawLine(Offset(left - 8, bottom), Offset(right + 8, bottom), frame);
    canvas.drawLine(
      Offset(left - 2, top + 6),
      Offset(left + 5, chamberTop),
      frame..strokeWidth = 1.8,
    );
    canvas.drawLine(
      Offset(right + 2, top + 6),
      Offset(right - 5, chamberTop),
      frame,
    );
    canvas.drawLine(
      Offset(left - 2, bottom - 6),
      Offset(left + 5, chamberBottom),
      frame,
    );
    canvas.drawLine(
      Offset(right + 2, bottom - 6),
      Offset(right - 5, chamberBottom),
      frame,
    );
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.phase != phase ||
      oldDelegate.color != color;
}

enum PuzzleKind {
  calculation,
  series,
  logic,
  attention,
  order,
  equation,
  comparison,
  sudoku,
  wordSearch,
  connectDots,
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
  late final List<PuzzleKind> kinds;
  PuzzleChallenge? challenge;
  int index = 0;
  int mistakes = 0;

  PuzzleKind get currentKind => kinds[index];

  @override
  void initState() {
    super.initState();
    kinds = factory.shuffledKinds();
    _loadChallenge();
  }

  void _loadChallenge() {
    challenge = factory.isMiniGame(currentKind)
        ? null
        : factory.generate(currentKind);
  }

  @override
  Widget build(BuildContext context) {
    const foreground = NopeTheme.focusForeground;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
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
                '${index + 1} / ${PuzzleKind.values.length}',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: foreground),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              PuzzleKind.values.length,
              (position) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: position == PuzzleKind.values.length - 1 ? 0 : 5,
                  ),
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
          const SizedBox(height: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _challengeView(context, foreground),
            ),
          ),
          Center(
            child: Text(
              'Cerrar los retos conserva tu sesión de foco.',
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

  Widget _challengeView(BuildContext context, Color foreground) {
    final key = ValueKey('${currentKind.name}-$index-$mistakes');
    return switch (currentKind) {
      PuzzleKind.sudoku => _MiniGameFrame(
        key: key,
        label: 'SUDOKU 4 × 4',
        foreground: foreground,
        child: SudokuMiniGame(foreground: foreground, onSolved: _advance),
      ),
      PuzzleKind.wordSearch => _MiniGameFrame(
        key: key,
        label: 'SOPA DE LETRAS',
        foreground: foreground,
        child: WordSearchMiniGame(foreground: foreground, onSolved: _advance),
      ),
      PuzzleKind.connectDots => _MiniGameFrame(
        key: key,
        label: 'UNE LOS PUNTOS',
        foreground: foreground,
        child: ConnectDotsMiniGame(foreground: foreground, onSolved: _advance),
      ),
      _ => _ChoiceChallenge(
        key: key,
        challenge: challenge!,
        mistakes: mistakes,
        foreground: foreground,
        onAnswer: _answer,
      ),
    };
  }

  void _answer(String option) {
    if (option != challenge!.answer) {
      setState(() {
        mistakes++;
        challenge = factory.generate(currentKind);
      });
      return;
    }
    _advance();
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (index == PuzzleKind.values.length - 1) {
      await widget.controller.pauseAfterPuzzles();
      if (mounted) widget.onCancel();
      return;
    }
    setState(() {
      index++;
      mistakes = 0;
      _loadChallenge();
    });
  }
}

class _MiniGameFrame extends StatelessWidget {
  const _MiniGameFrame({
    super.key,
    required this.label,
    required this.foreground,
    required this.child,
  });
  final String label;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground.withValues(alpha: .55),
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _ChoiceChallenge extends StatelessWidget {
  const _ChoiceChallenge({
    super.key,
    required this.challenge,
    required this.mistakes,
    required this.foreground,
    required this.onAnswer,
  });
  final PuzzleChallenge challenge;
  final int mistakes;
  final Color foreground;
  final ValueChanged<String> onAnswer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
            SizedBox(
              height: 42,
              child: mistakes > 0
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Respuesta incorrecta. Se generó un reto distinto.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: foreground.withValues(alpha: .62),
                        ),
                      ),
                    )
                  : null,
            ),
            ...challenge.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onAnswer(option),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: foreground,
                      side: BorderSide(color: foreground.withValues(alpha: .3)),
                      minimumSize: const Size(0, 54),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
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
          ],
        ),
      ),
    );
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
  PuzzleFactory({math.Random? random}) : _random = random ?? math.Random();
  final math.Random _random;

  List<PuzzleKind> shuffledKinds() => [...PuzzleKind.values]..shuffle(_random);

  bool isMiniGame(PuzzleKind kind) =>
      kind == PuzzleKind.sudoku ||
      kind == PuzzleKind.wordSearch ||
      kind == PuzzleKind.connectDots;

  PuzzleChallenge generate(PuzzleKind kind) {
    return switch (kind) {
      PuzzleKind.calculation => _calculation(),
      PuzzleKind.series => _series(),
      PuzzleKind.logic => _logic(),
      PuzzleKind.attention => _attention(),
      PuzzleKind.order => _order(),
      PuzzleKind.equation => _equation(),
      PuzzleKind.comparison => _comparison(),
      _ => throw ArgumentError('$kind es un minijuego interactivo.'),
    };
  }

  PuzzleChallenge _calculation() {
    final a = 7 + _random.nextInt(9);
    final b = 4 + _random.nextInt(8);
    final c = 3 + _random.nextInt(12);
    final answer = a * b + c;
    return PuzzleChallenge(
      label: 'CÁLCULO',
      prompt: '$a × $b + $c',
      options: _numberOptions(answer, spread: 8),
      answer: '$answer',
    );
  }

  PuzzleChallenge _series() {
    final start = 3 + _random.nextInt(8);
    final firstStep = 2 + _random.nextInt(4);
    final values = <int>[start];
    for (var index = 0; index < 4; index++) {
      values.add(values.last + firstStep + index);
    }
    final answer = values.last + firstStep + 4;
    return PuzzleChallenge(
      label: 'SERIE VARIABLE',
      prompt: '${values.join('  ·  ')}  ·  ?',
      options: _numberOptions(answer, spread: 7),
      answer: '$answer',
    );
  }

  PuzzleChallenge _logic() {
    final letters = ['A', 'B', 'C', 'D']..shuffle(_random);
    final answer = '${letters.first} es mayor';
    final options = [
      answer,
      '${letters[1]} es mayor',
      '${letters[2]} es mayor',
      'No se puede saber',
    ]..shuffle(_random);
    return PuzzleChallenge(
      label: 'LÓGICA',
      prompt:
          '${letters[0]} > ${letters[1]}, ${letters[1]} > ${letters[2]} y '
          '${letters[2]} > ${letters[3]}. ¿Qué es cierto?',
      options: options,
      answer: answer,
    );
  }

  PuzzleChallenge _attention() {
    const phrases = [
      'NOPE PONE ORDEN DONDE HABÍA RUIDO',
      'POCO A POCO TODO TOMA FORMA',
      'HOY SOLO IMPORTA LO PRIORITARIO',
      'EL FOCO CONVIERTE PLANES EN PROGRESO',
    ];
    final phrase = phrases[_random.nextInt(phrases.length)];
    final target = ['O', 'A', 'E'][_random.nextInt(3)];
    final count = target.allMatches(phrase).length;
    return PuzzleChallenge(
      label: 'ATENCIÓN',
      prompt: '¿Cuántas letras $target hay?\n\n$phrase',
      options: _numberOptions(count, spread: 3),
      answer: '$count',
    );
  }

  PuzzleChallenge _order() {
    final values = <int>{};
    while (values.length < 6) {
      values.add(12 + _random.nextInt(86));
    }
    final list = values.toList()..shuffle(_random);
    final sorted = [...list]..sort((a, b) => b.compareTo(a));
    final answer = sorted[2];
    final options = [...sorted.take(4)].map((value) => '$value').toList()
      ..shuffle(_random);
    return PuzzleChallenge(
      label: 'ORDEN',
      prompt: 'Elige el tercer número más alto.\n\n${list.join('  ·  ')}',
      options: options,
      answer: '$answer',
    );
  }

  PuzzleChallenge _equation() {
    final x = 3 + _random.nextInt(9);
    final multiplier = 2 + _random.nextInt(7);
    final offset = 3 + _random.nextInt(12);
    final total = multiplier * x + offset;
    return PuzzleChallenge(
      label: 'DESPEJA X',
      prompt: '$multiplier × x + $offset = $total',
      options: _numberOptions(x, spread: 4),
      answer: '$x',
    );
  }

  PuzzleChallenge _comparison() {
    final a = 3 + _random.nextInt(7);
    final b = 4 + _random.nextInt(6);
    final values = <String, int>{
      '$a × $b': a * b,
      '${a + 5} + ${b + 9}': a + b + 14,
      '${a * b + 8} − 5': a * b + 3,
      '${(a + b) * 2} ÷ 2': a + b,
    };
    final answer = values.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final options = values.keys.toList()..shuffle(_random);
    return PuzzleChallenge(
      label: 'COMPARACIÓN',
      prompt: '¿Qué expresión da el resultado más alto?',
      options: options,
      answer: answer,
    );
  }

  List<String> _numberOptions(int answer, {required int spread}) {
    final values = <int>{answer};
    while (values.length < 4) {
      final offset = _random.nextInt(spread * 2 + 1) - spread;
      final minimum = answer >= 10 ? 1 : 0;
      if (offset != 0 && answer + offset >= minimum) {
        values.add(answer + offset);
      }
    }
    return values.map((value) => '$value').toList()..shuffle(_random);
  }
}
