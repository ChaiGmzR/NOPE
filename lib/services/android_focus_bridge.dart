import 'package:flutter/services.dart';

import '../models/app_update.dart';

class AndroidFocusBridge {
  static const _channel = MethodChannel('com.nopefocus.nope/protection');

  Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('accessibilityEnabled') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  Future<void> syncProtectionState({
    required int activeUntil,
    required int pausedUntil,
    required String schedulesJson,
  }) async {
    try {
      await _channel.invokeMethod<void>('syncProtectionState', {
        'activeUntil': activeUntil,
        'pausedUntil': pausedUntil,
        'schedulesJson': schedulesJson,
      });
    } on PlatformException {
      // The Flutter UI stays usable on non-Android test targets.
    } on MissingPluginException {
      // The Flutter UI stays usable on non-Android test targets.
    }
  }

  Future<bool> launchEssential(String target) async {
    try {
      return await _channel.invokeMethod<bool>('launchEssential', {
            'target': target,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<({AppUpdate? update, String currentVersion})> checkForUpdate() async {
    try {
      final response = await _channel.invokeMapMethod<Object?, Object?>(
        'checkForUpdate',
      );
      final current = response?['currentVersion'] as String? ?? '0.1.0';
      if (response?['available'] != true) {
        return (update: null, currentVersion: current);
      }
      return (update: AppUpdate.fromMap(response!), currentVersion: current);
    } on PlatformException {
      return (update: null, currentVersion: '0.1.0');
    } on MissingPluginException {
      return (update: null, currentVersion: '0.1.0');
    }
  }

  Future<String> downloadAndInstallUpdate(AppUpdate update) async {
    try {
      final response = await _channel
          .invokeMapMethod<Object?, Object?>('downloadAndInstallUpdate', {
            'downloadUrl': update.downloadUrl,
            'version': update.latestVersion,
            'digest': update.digest ?? '',
          });
      return response?['status'] as String? ?? 'failed';
    } on PlatformException {
      return 'failed';
    } on MissingPluginException {
      return 'failed';
    }
  }
}
