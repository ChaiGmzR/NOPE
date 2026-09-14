class FocusSchedule {
  const FocusSchedule({
    required this.id,
    required this.name,
    required this.weekdays,
    required this.startMinute,
    required this.endMinute,
    required this.createdAt,
    this.enabled = true,
  });

  final String id;
  final String name;
  final Set<int> weekdays;
  final int startMinute;
  final int endMinute;
  final DateTime createdAt;
  final bool enabled;

  int get durationMinutes {
    final difference = endMinute - startMinute;
    return difference > 0 ? difference : 24 * 60 + difference;
  }

  bool isActiveAt(DateTime dateTime) {
    if (!enabled) return false;
    final minute = dateTime.hour * 60 + dateTime.minute;
    if (startMinute < endMinute) {
      return weekdays.contains(dateTime.weekday) &&
          minute >= startMinute &&
          minute < endMinute;
    }
    if (minute >= startMinute) return weekdays.contains(dateTime.weekday);
    final previousDay = dateTime.weekday == DateTime.monday
        ? DateTime.sunday
        : dateTime.weekday - 1;
    return minute < endMinute && weekdays.contains(previousDay);
  }

  DateTime? endAt(DateTime now) {
    if (!isActiveAt(now)) return null;
    final minute = now.hour * 60 + now.minute;
    final endsTomorrow = startMinute >= endMinute && minute >= startMinute;
    final base = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: endsTomorrow ? 1 : 0));
    return base.add(Duration(minutes: endMinute));
  }

  FocusSchedule copyWith({
    String? name,
    Set<int>? weekdays,
    int? startMinute,
    int? endMinute,
    bool? enabled,
  }) {
    return FocusSchedule(
      id: id,
      name: name ?? this.name,
      weekdays: weekdays ?? this.weekdays,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      createdAt: createdAt,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'weekdays': weekdays.toList()..sort(),
    'startMinute': startMinute,
    'endMinute': endMinute,
    'createdAt': createdAt.toIso8601String(),
    'enabled': enabled,
  };

  factory FocusSchedule.fromJson(Map<String, dynamic> json) {
    return FocusSchedule(
      id: json['id'] as String,
      name: json['name'] as String,
      weekdays: (json['weekdays'] as List)
          .cast<num>()
          .map((e) => e.toInt())
          .toSet(),
      startMinute: (json['startMinute'] as num).toInt(),
      endMinute: (json['endMinute'] as num).toInt(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
