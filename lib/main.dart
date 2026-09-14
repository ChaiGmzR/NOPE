import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'controllers/focus_controller.dart';
import 'services/android_focus_bridge.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final storage = await StorageService.create();
  final controller = FocusController(storage, AndroidFocusBridge());
  await controller.initialize();
  runApp(NopeApp(controller: controller));
}
