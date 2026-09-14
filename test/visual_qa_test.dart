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

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'accessibilityEnabled') return true;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('onboarding portrait visual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({});
    final controller = FocusController(
      await StorageService.create(),
      AndroidFocusBridge(),
    );
    await controller.initialize();
    await tester.pumpWidget(NopeApp(controller: controller));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/onboarding.png'),
    );
    controller.dispose();
  });

  testWidgets('home portrait visual', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({
      'onboardingComplete': true,
      'clockStyle': ClockStyle.hourglass.index,
      'paletteIndex': 2,
    });
    final controller = FocusController(
      await StorageService.create(),
      AndroidFocusBridge(),
    );
    await controller.initialize();
    await tester.pumpWidget(NopeApp(controller: controller));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
    controller.dispose();
  });

  testWidgets('lock portrait visual and puzzle layout', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({
      'onboardingComplete': true,
      'clockStyle': ClockStyle.hourglass.index,
      'paletteIndex': 2,
    });
    final controller = FocusController(
      await StorageService.create(),
      AndroidFocusBridge(),
    );
    await controller.initialize();
    await controller.startFocus(const Duration(minutes: 45));
    await tester.pumpWidget(NopeApp(controller: controller));
    await tester.pump();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/focus_lock.png'),
    );

    await tester.tap(find.text('NECESITO UNA PAUSA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('/ 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('pause keeps focus shell visible', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    SharedPreferences.setMockInitialValues({'onboardingComplete': true});
    final controller = FocusController(
      await StorageService.create(),
      AndroidFocusBridge(),
    );
    await controller.initialize();
    await controller.startFocus(const Duration(minutes: 45));
    await controller.pauseAfterPuzzles();
    await tester.pumpWidget(NopeApp(controller: controller));
    await tester.pump();

    expect(find.text('PAUSA ACTIVA'), findsOneWidget);
    expect(find.text('Hoy'), findsNothing);
    expect(find.text('VOLVER AL FOCO AHORA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
