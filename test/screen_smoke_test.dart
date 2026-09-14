import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nope/app.dart';
import 'package:nope/controllers/focus_controller.dart';
import 'package:nope/services/android_focus_bridge.dart';
import 'package:nope/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.nopefocus.nope/protection');

  testWidgets('all main tabs render on a compact Android viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    SharedPreferences.setMockInitialValues({'onboardingComplete': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'accessibilityEnabled') return true;
          return null;
        });
    final controller = FocusController(
      await StorageService.create(),
      AndroidFocusBridge(),
    );
    await controller.initialize();
    await tester.pumpWidget(NopeApp(controller: controller));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pump();
    expect(find.text('Horarios'), findsWidgets);

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pump();
    expect(find.text('Tu progreso'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.tune_outlined));
    await tester.pump();
    expect(find.text('Ajustes'), findsWidgets);
    expect(tester.takeException(), isNull);

    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
