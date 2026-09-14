import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../models/focus_schedule.dart';
import '../models/app_update.dart';
import '../services/android_focus_bridge.dart';
import '../services/storage_service.dart';

enum ClockStyle { digital, analog, hourglass }

class FocusController extends ChangeNotifier with WidgetsBindingObserver {
  FocusController(this._storage, this._bridge);

  final StorageService _storage;
  final AndroidFocusBridge _bridge;
  Timer? _timer;

  bool onboardingComplete = false;
  bool accessibilityEnabled = false;
  bool authenticatorAvailable = false;
  bool darkMode = false;
  int paletteIndex = 0;
  ClockStyle clockStyle = ClockStyle.digital;
  DateTime? manualStartedAt;
  DateTime? manualEndsAt;
  DateTime? pausedUntil;
  String activeLabel = 'Sesión de enfoque';
  List<FocusSchedule> schedules = [];
  Map<String, int> plannedMinutes = {};
  Map<String, int> completedMinutes = {};
  Map<String, int> interruptions = {};
  AppUpdate? availableUpdate;
  String currentVersion = '0.2.0';
  String? updateMessage;
  bool checkingForUpdate = false;
  bool installingUpdate = false;

  DateTime get now => DateTime.now();

  FocusSchedule? get activeSchedule {
    for (final schedule in schedules) {
      if (schedule.isActiveAt(now)) return schedule;
    }
    return null;
  }

  DateTime? get activeEnd {
    if (manualEndsAt != null && manualEndsAt!.isAfter(now)) return manualEndsAt;
    return activeSchedule?.endAt(now);
  }

  bool get isFocusActive => activeEnd != null;
  bool get isPaused => pausedUntil != null && pausedUntil!.isAfter(now);
  bool get shouldShowLock => isFocusActive && !isPaused;
  bool get shouldShowFocusScreen => isFocusActive;

  Duration get remaining {
    final end = activeEnd;
    if (end == null) return Duration.zero;
    final value = end.difference(now);
    return value.isNegative ? Duration.zero : value;
  }

  String get currentLabel => manualEndsAt != null && manualEndsAt!.isAfter(now)
      ? activeLabel
      : activeSchedule?.name ?? 'Sesión de enfoque';

  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    onboardingComplete = _storage.getBool('onboardingComplete');
    darkMode = _storage.getBool('darkMode');
    paletteIndex = _storage.getInt('paletteIndex');
    final clockIndex = _storage.getInt('clockStyle');
    clockStyle =
        ClockStyle.values[clockIndex.clamp(0, ClockStyle.values.length - 1)];
    activeLabel = _storage.getString('activeLabel') ?? 'Sesión de enfoque';
    manualStartedAt = _readDate('manualStartedAt');
    manualEndsAt = _readDate('manualEndsAt');
    pausedUntil = _readDate('pausedUntil');
    plannedMinutes = _storage.getIntMap('plannedMinutes');
    completedMinutes = _storage.getIntMap('completedMinutes');
    interruptions = _storage.getIntMap('interruptions');
    schedules = _readSchedules();
    await refreshPermission();
    await _reconcileFinishedSession();
    _reconcilePastSchedules();
    await _syncNative();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (onboardingComplete) unawaited(checkForUpdates());
  }

  DateTime? _readDate(String key) {
    final value = _storage.getString(key);
    return value == null || value.isEmpty ? null : DateTime.tryParse(value);
  }

  List<FocusSchedule> _readSchedules() {
    final raw = _storage.getString('schedules');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => FocusSchedule.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _tick() async {
    await _reconcileFinishedSession();
    if (pausedUntil != null && !pausedUntil!.isAfter(now)) {
      pausedUntil = null;
      await _storage.setString('pausedUntil', '');
      await _syncNative();
    }
    notifyListeners();
  }

  Future<void> _reconcileFinishedSession() async {
    if (manualEndsAt == null || manualStartedAt == null) return;
    if (manualEndsAt!.isAfter(now)) return;
    final dateKey = keyForDate(manualStartedAt!);
    final minutes = manualEndsAt!.difference(manualStartedAt!).inMinutes;
    completedMinutes[dateKey] = (completedMinutes[dateKey] ?? 0) + minutes;
    manualStartedAt = null;
    manualEndsAt = null;
    pausedUntil = null;
    await Future.wait([
      _storage.setString('manualStartedAt', ''),
      _storage.setString('manualEndsAt', ''),
      _storage.setString('pausedUntil', ''),
      _storage.setIntMap('completedMinutes', completedMinutes),
    ]);
    await _syncNative();
  }

  void _reconcilePastSchedules() {
    if (schedules.isEmpty) return;
    final today = DateTime(now.year, now.month, now.day);
    var changed = false;
    for (final schedule in schedules.where((item) => item.enabled)) {
      final created = DateTime(
        schedule.createdAt.year,
        schedule.createdAt.month,
        schedule.createdAt.day,
      );
      final oldest = today.subtract(const Duration(days: 45));
      final first = created.isBefore(oldest) ? oldest : created;
      for (
        var day = first;
        !day.isAfter(today);
        day = day.add(const Duration(days: 1))
      ) {
        if (!schedule.weekdays.contains(day.weekday)) continue;
        final endDay = schedule.startMinute >= schedule.endMinute
            ? day.add(const Duration(days: 1))
            : day;
        final end = endDay.add(Duration(minutes: schedule.endMinute));
        if (end.isAfter(now)) continue;
        final markerKey = 'schedule:${keyForDate(day)}:${schedule.id}';
        if (_storage.getBool(markerKey)) continue;
        final dateKey = keyForDate(day);
        plannedMinutes[dateKey] =
            (plannedMinutes[dateKey] ?? 0) + schedule.durationMinutes;
        completedMinutes[dateKey] =
            (completedMinutes[dateKey] ?? 0) + schedule.durationMinutes;
        _storage.setBool(markerKey, true);
        changed = true;
      }
    }
    if (changed) {
      _storage.setIntMap('plannedMinutes', plannedMinutes);
      _storage.setIntMap('completedMinutes', completedMinutes);
    }
  }

  Future<void> completeOnboarding() async {
    onboardingComplete = true;
    await _storage.setBool('onboardingComplete', true);
    notifyListeners();
    unawaited(checkForUpdates());
  }

  Future<void> checkForUpdates({bool manual = false}) async {
    if (checkingForUpdate) return;
    checkingForUpdate = true;
    if (manual) updateMessage = null;
    notifyListeners();
    final result = await _bridge.checkForUpdate();
    currentVersion = result.currentVersion;
    availableUpdate = result.update;
    if (manual && result.update == null) {
      updateMessage = 'NOPE está actualizado.';
    }
    checkingForUpdate = false;
    notifyListeners();
  }

  Future<String> installAvailableUpdate() async {
    final update = availableUpdate;
    if (update == null || installingUpdate) return 'failed';
    installingUpdate = true;
    updateMessage = null;
    notifyListeners();
    final status = await _bridge.downloadAndInstallUpdate(update);
    installingUpdate = false;
    updateMessage = switch (status) {
      'needsPermission' =>
        'Permite instalar desde NOPE y vuelve a pulsar Actualizar.',
      'installerStarted' =>
        'Descarga lista. Confirma la instalación en Android.',
      _ => 'No se pudo descargar la actualización. Inténtalo de nuevo.',
    };
    if (status == 'installerStarted') availableUpdate = null;
    notifyListeners();
    return status;
  }

  void dismissUpdate() {
    availableUpdate = null;
    notifyListeners();
  }

  Future<void> refreshPermission() async {
    final states = await Future.wait<bool>([
      _bridge.isAccessibilityEnabled(),
      _bridge.isEssentialAvailable('authenticator'),
    ]);
    accessibilityEnabled = states[0];
    authenticatorAvailable = states[1];
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() =>
      _bridge.openAccessibilitySettings();

  Future<void> startFocus(
    Duration duration, {
    String label = 'Enfoque libre',
  }) async {
    final started = now;
    manualStartedAt = started;
    manualEndsAt = started.add(duration);
    pausedUntil = null;
    activeLabel = label;
    final key = keyForDate(started);
    plannedMinutes[key] = (plannedMinutes[key] ?? 0) + duration.inMinutes;
    await Future.wait([
      _storage.setString('manualStartedAt', started.toIso8601String()),
      _storage.setString('manualEndsAt', manualEndsAt!.toIso8601String()),
      _storage.setString('pausedUntil', ''),
      _storage.setString('activeLabel', activeLabel),
      _storage.setIntMap('plannedMinutes', plannedMinutes),
    ]);
    await _syncNative();
    notifyListeners();
  }

  Future<void> pauseAfterPuzzles() async {
    pausedUntil = now.add(const Duration(minutes: 5));
    final key = keyForDate(now);
    interruptions[key] = (interruptions[key] ?? 0) + 1;
    await Future.wait([
      _storage.setString('pausedUntil', pausedUntil!.toIso8601String()),
      _storage.setIntMap('interruptions', interruptions),
    ]);
    await _syncNative();
    notifyListeners();
  }

  Future<void> resumeFocusNow() async {
    pausedUntil = null;
    await _storage.setString('pausedUntil', '');
    await _syncNative();
    notifyListeners();
  }

  Future<void> saveSchedule(FocusSchedule schedule) async {
    final index = schedules.indexWhere((item) => item.id == schedule.id);
    if (index == -1) {
      schedules = [...schedules, schedule];
    } else {
      schedules = [...schedules]..[index] = schedule;
    }
    await _persistSchedules();
  }

  Future<void> deleteSchedule(String id) async {
    schedules = schedules.where((item) => item.id != id).toList();
    await _persistSchedules();
  }

  Future<void> _persistSchedules() async {
    await _storage.setString(
      'schedules',
      jsonEncode(schedules.map((item) => item.toJson()).toList()),
    );
    await _syncNative();
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _storage.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setPalette(int value) async {
    paletteIndex = value;
    await _storage.setInt('paletteIndex', value);
    notifyListeners();
  }

  Future<void> setClockStyle(ClockStyle value) async {
    clockStyle = value;
    await _storage.setInt('clockStyle', value.index);
    notifyListeners();
  }

  Future<bool> launchEssential(String target) =>
      _bridge.launchEssential(target);

  Future<void> _syncNative() {
    return _bridge.syncProtectionState(
      activeUntil: manualEndsAt?.millisecondsSinceEpoch ?? 0,
      pausedUntil: pausedUntil?.millisecondsSinceEpoch ?? 0,
      schedulesJson: jsonEncode(
        schedules.map((item) => item.toJson()).toList(),
      ),
    );
  }

  FocusSchedule? nextSchedule() {
    final from = now;
    FocusSchedule? best;
    DateTime? bestStart;
    for (var offset = 0; offset <= 7; offset++) {
      final date = DateTime(
        from.year,
        from.month,
        from.day,
      ).add(Duration(days: offset));
      for (final schedule in schedules.where((item) => item.enabled)) {
        if (!schedule.weekdays.contains(date.weekday)) continue;
        final start = date.add(Duration(minutes: schedule.startMinute));
        if (start.isBefore(from)) continue;
        if (bestStart == null || start.isBefore(bestStart)) {
          best = schedule;
          bestStart = start;
        }
      }
      if (best != null) break;
    }
    return best;
  }

  double complianceForDate(DateTime date) {
    final key = keyForDate(date);
    final planned = plannedMinutes[key] ?? 0;
    if (planned == 0) return -1;
    final completed = completedMinutes[key] ?? 0;
    final lost = (interruptions[key] ?? 0) * 5;
    return ((completed - lost).clamp(0, planned) / planned).clamp(0, 1);
  }

  int get totalFocusedMinutes {
    var total = 0;
    completedMinutes.forEach((key, value) {
      total += (value - (interruptions[key] ?? 0) * 5).clamp(0, value);
    });
    return total;
  }

  int get overallCompliance {
    final planned = plannedMinutes.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (planned == 0) return 0;
    var effective = 0;
    completedMinutes.forEach((key, value) {
      effective += (value - (interruptions[key] ?? 0) * 5).clamp(0, value);
    });
    return ((effective / planned).clamp(0, 1) * 100).round();
  }

  int get currentStreak {
    var streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 90; i++) {
      final compliance = complianceForDate(cursor);
      if (compliance < 0) {
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (compliance < .8) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshPermission();
      _syncNative();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  static String keyForDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
