import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../core/formatters.dart';
import '../models/focus_schedule.dart';
import '../widgets/nope_components.dart';

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key, required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          PageHeading(
            eyebrow: 'Rutinas',
            title: 'Horarios',
            trailing: IconButton.filled(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Nuevo horario',
            ),
          ),
          Expanded(
            child: controller.schedules.isEmpty
                ? _EmptySchedules(onCreate: () => _edit(context))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
                    itemCount: controller.schedules.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final schedule = controller.schedules[index];
                      return _ScheduleCard(
                        schedule: schedule,
                        onToggle: (enabled) => controller.saveSchedule(
                          schedule.copyWith(enabled: enabled),
                        ),
                        onEdit: () => _edit(context, schedule),
                        onDelete: () => _delete(context, schedule),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, [FocusSchedule? schedule]) async {
    final result = await showModalBottomSheet<FocusSchedule>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ScheduleEditorSheet(schedule: schedule),
    );
    if (result != null) await controller.saveSchedule(result);
  }

  Future<void> _delete(BuildContext context, FocusSchedule schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar horario'),
        content: Text('“${schedule.name}” dejará de aplicarse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.deleteSchedule(schedule.id);
  }
}

class _EmptySchedules extends StatelessWidget {
  const _EmptySchedules({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: const Icon(Icons.schedule_rounded, size: 34),
          ),
          const SizedBox(height: 24),
          Text(
            'Protege lo importante\nantes de que empiece.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Programa trabajo, clases o estudio. NOPE se activará '
            'automáticamente.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          NopeButton(
            label: 'Crear primer horario',
            icon: Icons.add_rounded,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final FocusSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            schedule.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusPill(
                          label: schedule.enabled ? 'Activo' : 'Pausa',
                          active: schedule.enabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${formatMinute(schedule.startMinute)} — '
                      '${formatMinute(schedule.endMinute)}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      compactDaysSummary(schedule.weekdays),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: muted,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Switch(value: schedule.enabled, onChanged: onToggle),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScheduleEditorSheet extends StatefulWidget {
  const ScheduleEditorSheet({super.key, this.schedule});
  final FocusSchedule? schedule;

  @override
  State<ScheduleEditorSheet> createState() => _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends State<ScheduleEditorSheet> {
  late final TextEditingController nameController;
  late Set<int> weekdays;
  late TimeOfDay start;
  late TimeOfDay end;

  @override
  void initState() {
    super.initState();
    final schedule = widget.schedule;
    nameController = TextEditingController(text: schedule?.name ?? 'Estudio');
    weekdays = {
      ...(schedule?.weekdays ?? {1, 2, 3, 4, 5}),
    };
    start = _time(schedule?.startMinute ?? 9 * 60);
    end = _time(schedule?.endMinute ?? 11 * 60);
  }

  TimeOfDay _time(int minute) =>
      TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 4, 24, 24 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.schedule == null ? 'Nuevo horario' : 'Editar horario',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ponle nombre a la prioridad que quieres proteger.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Actividad'),
          ),
          const SizedBox(height: 24),
          Text('DÍAS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final day = index + 1;
              final selected = weekdays.contains(day);
              return InkWell(
                onTap: () => setState(() {
                  selected ? weekdays.remove(day) : weekdays.add(day);
                }),
                customBorder: const CircleBorder(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    weekdayShort[index],
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'INICIO',
                  value: start,
                  onTap: () => _selectTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: 'FIN',
                  value: end,
                  onTap: () => _selectTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          NopeButton(
            label: widget.schedule == null
                ? 'Crear horario'
                : 'Guardar cambios',
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(bool isStart) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? start : end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected == null) return;
    setState(() => isStart ? start = selected : end = selected);
  }

  void _save() {
    final name = nameController.text.trim();
    final startMinute = start.hour * 60 + start.minute;
    final endMinute = end.hour * 60 + end.minute;
    if (name.isEmpty || weekdays.isEmpty || startMinute == endMinute) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Añade un nombre, al menos un día y horas diferentes.'),
        ),
      );
      return;
    }
    final original = widget.schedule;
    Navigator.pop(
      context,
      FocusSchedule(
        id: original?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        weekdays: weekdays,
        startMinute: startMinute,
        endMinute: endMinute,
        createdAt: original?.createdAt ?? DateTime.now(),
        enabled: original?.enabled ?? true,
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 7),
            Text(
              formatTimeOfDay(value),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
