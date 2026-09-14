import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../core/formatters.dart';
import '../models/focus_schedule.dart';
import '../widgets/nope_components.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});
  final FocusController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedMinutes = 45;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final next = controller.nextSchedule();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const NopeWordmark(),
                  StatusPill(
                    label: controller.accessibilityEnabled
                        ? 'Protegido'
                        : 'Sin proteger',
                    active: controller.accessibilityEnabled,
                  ),
                ],
              ),
            ),
          ),
          if (controller.isPaused)
            SliverToBoxAdapter(child: _PauseBanner(controller: controller)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.list(
              children: [
                _FocusHero(
                  minutes: selectedMinutes,
                  onStart: () => _start(context),
                ),
                const SizedBox(height: 24),
                Text(
                  'DURACIÓN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [25, 45, 60, 90]
                      .map(
                        (minutes) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: minutes == 90 ? 0 : 8,
                            ),
                            child: _DurationOption(
                              value: minutes,
                              selected: selectedMinutes == minutes,
                              onTap: () =>
                                  setState(() => selectedMinutes = minutes),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'PRÓXIMO BLOQUE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${controller.currentStreak} DÍAS DE RACHA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _NextScheduleCard(schedule: next),
                if (!controller.accessibilityEnabled) ...[
                  const SizedBox(height: 16),
                  _ProtectionCard(controller: controller),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    if (!widget.controller.accessibilityEnabled) {
      final configure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activa la protección'),
          content: const Text(
            'Android necesita que actives el servicio de NOPE para bloquear '
            'otras aplicaciones durante la sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('AHORA NO'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONFIGURAR'),
            ),
          ],
        ),
      );
      if (configure == true) {
        await widget.controller.openAccessibilitySettings();
      }
      return;
    }
    await widget.controller.startFocus(
      Duration(minutes: selectedMinutes),
      label: 'Enfoque libre',
    );
  }
}

class _FocusHero extends StatelessWidget {
  const _FocusHero({required this.minutes, required this.onStart});
  final int minutes;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 330,
      decoration: BoxDecoration(
        color: scheme.onSurface,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _OrbitPainter(
                color: scheme.surface.withValues(alpha: .16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusPill(label: 'Listo para enfocar', active: false),
                const Spacer(),
                Text(
                  '$minutes',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: scheme.surface,
                    fontSize: 92,
                  ),
                ),
                Text(
                  'MINUTOS SIN RUIDO',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.surface.withValues(alpha: .72),
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.surface,
                    foregroundColor: scheme.onSurface,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('COMENZAR BLOQUE'),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationOption extends StatelessWidget {
  const _DurationOption({
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.onSurface : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? scheme.onSurface : scheme.outline,
          ),
        ),
        child: Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: selected ? scheme.surface : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _NextScheduleCard extends StatelessWidget {
  const _NextScheduleCard({required this.schedule});
  final FocusSchedule? schedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: schedule == null
            ? Row(
                children: [
                  const NumberBadge('—'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sin horarios aún',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Crea una rutina desde Horarios.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const NumberBadge('01'),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule!.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${compactDaysSummary(schedule!.weekdays)} · '
                          '${formatMinute(schedule!.startMinute)}—'
                          '${formatMinute(schedule!.endMinute)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
      ),
    );
  }
}

class _ProtectionCard extends StatelessWidget {
  const _ProtectionCard({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protección pendiente',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Actívala para que NOPE pueda detener las apps distractoras.',
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: controller.openAccessibilitySettings,
                    child: const Text('ABRIR AJUSTES'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseBanner extends StatelessWidget {
  const _PauseBanner({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          child: Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded, size: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pausa activa · '
                  '${formatDuration(controller.pausedUntil!.difference(controller.now))}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              TextButton(
                onPressed: controller.resumeFocusNow,
                child: const Text('VOLVER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width * 1.02, size.height * .06);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(center, 68.0 + i * 23, paint);
    }
    final left = Offset(-size.width * .08, size.height * 1.02);
    for (var i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: left, radius: 80.0 + i * 28),
        -math.pi / 2,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.color != color;
}
