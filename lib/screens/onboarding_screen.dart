import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../widgets/nope_components.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.controller});

  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 52,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const NopeWordmark(),
                    const Spacer(),
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.onSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        'N',
                        style: TextStyle(
                          color: scheme.surface,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Tu atención vuelve a ser tuya.',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'NOPE bloquea las distracciones durante tus horas importantes. '
                      'Teléfono, SMS y WhatsApp siguen disponibles.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    const _OnboardingStep(
                      number: '01',
                      text: 'Elige cuánto tiempo quieres proteger.',
                    ),
                    const _OnboardingStep(
                      number: '02',
                      text: 'Activa la protección una sola vez en Android.',
                    ),
                    const _OnboardingStep(
                      number: '03',
                      text:
                          'Si necesitas una pausa, primero resuelve diez retos.',
                    ),
                    const SizedBox(height: 24),
                    NopeButton(
                      label: controller.accessibilityEnabled
                          ? 'Protección activada'
                          : 'Activar protección',
                      icon: controller.accessibilityEnabled
                          ? Icons.check_rounded
                          : Icons.shield_outlined,
                      onPressed: controller.accessibilityEnabled
                          ? null
                          : controller.openAccessibilitySettings,
                    ),
                    const SizedBox(height: 10),
                    NopeButton(
                      label: 'Continuar',
                      secondary: true,
                      onPressed: controller.completeOnboarding,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NOPE usa Accesibilidad únicamente para detectar qué aplicación '
                      'está al frente y aplicar tus reglas. No lee, guarda ni comparte '
                      'el contenido de la pantalla.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          NumberBadge(number),
          const SizedBox(width: 14),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
