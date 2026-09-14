import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._(this._preferences);

  final SharedPreferences _preferences;

  static Future<StorageService> create() async {
    return StorageService._(await SharedPreferences.getInstance());
  }

  bool getBool(String key, {bool fallback = false}) =>
      _preferences.getBool(key) ?? fallback;

  int getInt(String key, {int fallback = 0}) =>
      _preferences.getInt(key) ?? fallback;

  String? getString(String key) => _preferences.getString(key);

  Map<String, int> getIntMap(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> setBool(String key, bool value) =>
      _preferences.setBool(key, value);

  Future<void> setInt(String key, int value) => _preferences.setInt(key, value);

  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  Future<void> setIntMap(String key, Map<String, int> value) =>
      _preferences.setString(key, jsonEncode(value));
}
