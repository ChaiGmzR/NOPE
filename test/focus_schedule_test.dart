import 'package:flutter_test/flutter_test.dart';
import 'package:nope/models/focus_schedule.dart';

void main() {
  group('FocusSchedule', () {
    test('detects a regular active period', () {
      final schedule = FocusSchedule(
        id: 'study',
        name: 'Estudio',
        weekdays: const {DateTime.monday},
        startMinute: 9 * 60,
        endMinute: 11 * 60,
        createdAt: DateTime(2026),
      );

      expect(schedule.isActiveAt(DateTime(2026, 9, 14, 10)), isTrue);
      expect(schedule.isActiveAt(DateTime(2026, 9, 14, 12)), isFalse);
    });

    test('supports schedules that cross midnight', () {
      final schedule = FocusSchedule(
        id: 'deep-work',
        name: 'Trabajo profundo',
        weekdays: const {DateTime.monday},
        startMinute: 23 * 60,
        endMinute: 60,
        createdAt: DateTime(2026),
      );

      expect(schedule.isActiveAt(DateTime(2026, 9, 14, 23, 30)), isTrue);
      expect(schedule.isActiveAt(DateTime(2026, 9, 15, 0, 30)), isTrue);
      expect(schedule.isActiveAt(DateTime(2026, 9, 15, 2)), isFalse);
    });

    test('serializes without losing weekdays', () {
      final original = FocusSchedule(
        id: 'school',
        name: 'Escuela',
        weekdays: const {1, 3, 5},
        startMinute: 480,
        endMinute: 600,
        createdAt: DateTime(2026, 9, 14),
      );

      final restored = FocusSchedule.fromJson(original.toJson());
      expect(restored.weekdays, original.weekdays);
      expect(restored.durationMinutes, 120);
    });
  });
}
