import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../core/formatters.dart';
import '../widgets/nope_components.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.controller});
  final FocusController controller;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late DateTime visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    visibleMonth = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeading(eyebrow: 'Consistencia', title: 'Tu progreso'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        value: '${controller.overallCompliance}%',
                        label: 'CUMPLIMIENTO',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        value: '${controller.currentStreak}',
                        label: 'RACHA ACTUAL',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        value: _hours(controller.totalFocusedMinutes),
                        label: 'HORAS DE FOCO',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => setState(() {
                                visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month - 1,
                                );
                              }),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            Expanded(
                              child: Text(
                                '${monthNames[visibleMonth.month - 1]} '
                                '${visibleMonth.year}',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(letterSpacing: 1.1),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() {
                                visibleMonth = DateTime(
                                  visibleMonth.year,
                                  visibleMonth.month + 1,
                                );
                              }),
                              icon: const Icon(Icons.arrow_forward_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: weekdayShort
                              .map(
                                (day) => Expanded(
                                  child: Text(
                                    day,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        _MonthGrid(month: visibleMonth, controller: controller),
                        const SizedBox(height: 18),
                        const Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            _LegendItem(
                              kind: _DayKind.complete,
                              label: 'Cumplido',
                            ),
                            _LegendItem(
                              kind: _DayKind.partial,
                              label: 'Interrumpido',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _WeeklyRhythm(controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes / 60;
    return hours == hours.roundToDouble()
        ? '${hours.round()}h'
        : '${hours.toStringAsFixed(1)}h';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: .4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DayKind { none, planned, complete, partial, missed }

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.controller});
  final DateTime month;
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final leading = DateTime(month.year, month.month, 1).weekday - 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 46,
      ),
      itemCount: leading + days,
      itemBuilder: (context, index) {
        if (index < leading) return const SizedBox.shrink();
        final day = index - leading + 1;
        final date = DateTime(month.year, month.month, day);
        final compliance = controller.complianceForDate(date);
        final today = DateTime.now();
        final dateOnly = DateTime(date.year, date.month, date.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        final planned = controller.schedules.any(
          (schedule) =>
              schedule.enabled &&
              !dateOnly.isBefore(
                DateTime(
                  schedule.createdAt.year,
                  schedule.createdAt.month,
                  schedule.createdAt.day,
                ),
              ) &&
              schedule.weekdays.contains(date.weekday),
        );
        final kind = compliance >= .8
            ? _DayKind.complete
            : compliance >= 0
            ? (compliance >= .4 ? _DayKind.partial : _DayKind.missed)
            : planned && !dateOnly.isBefore(todayOnly)
            ? _DayKind.planned
            : _DayKind.none;
        return _CalendarDay(day: day, kind: kind, today: dateOnly == todayOnly);
      },
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.day,
    required this.kind,
    required this.today,
  });
  final int day;
  final _DayKind kind;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = kind == _DayKind.complete;
    final partial = kind == _DayKind.partial;
    return Center(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled
              ? scheme.primary
              : partial
              ? scheme.surfaceContainerHighest
              : Colors.transparent,
          border: today || kind == _DayKind.planned || kind == _DayKind.missed
              ? Border.all(
                  color: kind == _DayKind.missed
                      ? scheme.error
                      : scheme.onSurface,
                  width: today ? 1.6 : 1,
                )
              : null,
        ),
        child: Text(
          '$day',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: filled ? scheme.onPrimary : scheme.onSurface,
            decoration: kind == _DayKind.missed
                ? TextDecoration.lineThrough
                : null,
            fontWeight: today ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.kind});
  final _DayKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kind == _DayKind.complete
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.kind, required this.label});
  final _DayKind kind;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LegendDot(kind: kind),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _WeeklyRhythm extends StatelessWidget {
  const _WeeklyRhythm({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index)),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RITMO DE 7 DÍAS',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 108,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((day) {
                  final value = controller.complianceForDate(day);
                  final height = value < 0 ? 5.0 : 16 + value * 70;
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 22,
                          height: height,
                          decoration: BoxDecoration(
                            color: value >= .8
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          weekdayShort[day.weekday - 1],
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              controller.plannedMinutes.isEmpty
                  ? 'Tu primera sesión empezará a dibujar este ritmo.'
                  : 'La constancia cuenta más que una sesión perfecta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
