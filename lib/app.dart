import 'package:flutter/material.dart';

import 'controllers/focus_controller.dart';
import 'screens/focus_lock_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'theme/nope_theme.dart';

class NopeApp extends StatelessWidget {
  const NopeApp({super.key, required this.controller});

  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'NOPE — Stay Focus',
          debugShowCheckedModeBanner: false,
          theme: NopeTheme.build(
            dark: controller.darkMode,
            paletteIndex: controller.paletteIndex,
          ),
          home: AppRoot(controller: controller),
        );
      },
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, required this.controller});
  final FocusController controller;

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool dialogOpen = false;
  String? promptedVersion;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    _scheduleUpdatePrompt(controller);
    if (!controller.onboardingComplete) {
      return OnboardingScreen(controller: controller);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: controller.shouldShowFocusScreen
          ? FocusLockScreen(
              key: ValueKey(controller.activeEnd?.millisecondsSinceEpoch),
              controller: controller,
            )
          : ShellScreen(key: const ValueKey('shell'), controller: controller),
    );
  }

  void _scheduleUpdatePrompt(FocusController controller) {
    final update = controller.availableUpdate;
    if (update == null ||
        dialogOpen ||
        promptedVersion == update.latestVersion ||
        controller.shouldShowFocusScreen ||
        !controller.onboardingComplete) {
      return;
    }
    dialogOpen = true;
    promptedVersion = update.latestVersion;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final activeUpdate = controller.availableUpdate ?? update;
            return AlertDialog(
              title: Text('NOPE ${activeUpdate.latestVersion} disponible'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hay una versión nueva. NOPE puede descargarla y abrir '
                      'el instalador de Android por ti.',
                    ),
                    if (activeUpdate.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        activeUpdate.notes.trim(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (controller.installingUpdate) ...[
                      const SizedBox(height: 20),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      const Text('Descargando y verificando…'),
                    ],
                    if (controller.updateMessage != null &&
                        !controller.installingUpdate) ...[
                      const SizedBox(height: 16),
                      Text(controller.updateMessage!),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: controller.installingUpdate
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          controller.dismissUpdate();
                        },
                  child: const Text('MÁS TARDE'),
                ),
                FilledButton(
                  onPressed: controller.installingUpdate
                      ? null
                      : () async {
                          final status = await controller
                              .installAvailableUpdate();
                          if (status == 'installerStarted' &&
                              dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('ACTUALIZAR'),
                ),
              ],
            );
          },
        ),
      );
      if (mounted) setState(() => dialogOpen = false);
    });
  }
}
