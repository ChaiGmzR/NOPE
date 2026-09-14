import 'package:flutter/material.dart';

const weekdayShort = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
const weekdayLong = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
const monthNames = [
  'ENERO',
  'FEBRERO',
  'MARZO',
  'ABRIL',
  'MAYO',
  'JUNIO',
  'JULIO',
  'AGOSTO',
  'SEPTIEMBRE',
  'OCTUBRE',
  'NOVIEMBRE',
  'DICIEMBRE',
];

String formatMinute(int minute) {
  final hours = (minute ~/ 60).toString().padLeft(2, '0');
  final minutes = (minute % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

String formatTimeOfDay(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String daysSummary(Set<int> days) {
  if (days.length == 7) return 'Todos los días';
  if (days.length == 5 && {1, 2, 3, 4, 5}.every((day) => days.contains(day))) {
    return 'Lunes a viernes';
  }
  final sorted = days.toList()..sort();
  return sorted.map((day) => weekdayLong[day - 1]).join(', ');
}

String compactDaysSummary(Set<int> days) {
  if (days.length == 7) return 'Todos los días';
  final sorted = days.toList()..sort();
  return sorted.map((day) => weekdayShort[day - 1]).join('  ');
}
