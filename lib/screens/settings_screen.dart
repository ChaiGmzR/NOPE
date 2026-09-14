import 'package:flutter/material.dart';

import '../controllers/focus_controller.dart';
import '../theme/nope_theme.dart';
import '../widgets/nope_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: PageHeading(eyebrow: 'Personaliza', title: 'Ajustes'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                _ProtectionSettings(controller: controller),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'APARIENCIA',
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Modo oscuro'),
                        subtitle: const Text(
                          'Reduce el brillo visual al estudiar.',
                        ),
                        value: controller.darkMode,
                        onChanged: controller.setDarkMode,
                      ),
                      const Divider(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'COLOR DE TINTA',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 68,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: NopeTheme.focusBackground(
                            controller.paletteIndex,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'NOPE',
                              style: TextStyle(
                                color: NopeTheme.focusForeground,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              NopeTheme.paletteNames[controller.paletteIndex],
                              style: const TextStyle(
                                color: NopeTheme.focusForeground,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(NopeTheme.palettes.length, (
                          index,
                        ) {
                          final selected = controller.paletteIndex == index;
                          return Expanded(
                            child: InkWell(
                              onTap: () => controller.setPalette(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: NopeTheme.palettes[index],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.surface,
                                          width: 4,
                                        ),
                                        boxShadow: selected
                                            ? [
                                                BoxShadow(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: selected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 18,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      NopeTheme.paletteNames[index],
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: selected
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: selected
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'RELOJ DE BLOQUEO',
                  child: Column(
                    children: [
                      _ClockChoice(
                        label: 'Digital',
                        icon: Icons.more_time_rounded,
                        selected: controller.clockStyle == ClockStyle.digital,
                        onTap: () =>
                            controller.setClockStyle(ClockStyle.digital),
                      ),
                      const Divider(height: 1),
                      _ClockChoice(
                        label: 'Analógico',
                        icon: Icons.schedule_rounded,
                        selected: controller.clockStyle == ClockStyle.analog,
                        onTap: () =>
                            controller.setClockStyle(ClockStyle.analog),
                      ),
                      const Divider(height: 1),
                      _ClockChoice(
                        label: 'Arena',
                        icon: Icons.hourglass_bottom_rounded,
                        selected: controller.clockStyle == ClockStyle.hourglass,
                        onTap: () =>
                            controller.setClockStyle(ClockStyle.hourglass),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'SIEMPRE DISPONIBLES',
                  child: Column(
                    children: [
                      const _EssentialRow(
                        icon: Icons.phone_outlined,
                        title: 'Teléfono',
                        subtitle: 'Llamadas y emergencias',
                      ),
                      const Divider(height: 1),
                      const _EssentialRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'SMS',
                        subtitle: 'Mensajes del sistema',
                      ),
                      const Divider(height: 1),
                      const _EssentialRow(
                        icon: Icons.forum_outlined,
                        title: 'WhatsApp',
                        subtitle: 'Personal y Business',
                      ),
                      const Divider(height: 1),
                      _EssentialRow(
                        icon: Icons.security_outlined,
                        title: 'Authenticator',
                        subtitle: controller.authenticatorAvailable
                            ? 'Detectado y disponible'
                            : 'No instalado',
                        active: controller.authenticatorAvailable,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const _SettingsCard(
                  title: 'FRICCIÓN INTENCIONAL',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: NumberBadge('10'),
                    title: Text('Diez retos por cada pausa'),
                    subtitle: Text(
                      'Incluye Sudoku, sopa de letras y une los puntos. Cada '
                      'tanda concede cinco minutos. '
                      'Al volver al bloqueo, se reinicia el requisito.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'ACTUALIZACIONES',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.system_update_alt_rounded),
                        title: Text('Versión ${controller.currentVersion}'),
                        subtitle: const Text(
                          'NOPE busca nuevas versiones al iniciar.',
                        ),
                        trailing: controller.checkingForUpdate
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                      if (controller.updateMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          controller.updateMessage!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: controller.checkingForUpdate
                              ? null
                              : () => controller.checkForUpdates(manual: true),
                          child: const Text('BUSCAR ACTUALIZACIÓN'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const Center(child: NopeWordmark()),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'VERSIÓN ${controller.currentVersion}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtectionSettings extends StatelessWidget {
  const _ProtectionSettings({required this.controller});
  final FocusController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: controller.accessibilityEnabled
            ? scheme.primary
            : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controller.accessibilityEnabled
              ? scheme.primary
              : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                controller.accessibilityEnabled
                    ? Icons.shield_rounded
                    : Icons.shield_outlined,
                color: controller.accessibilityEnabled
                    ? scheme.onPrimary
                    : scheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  controller.accessibilityEnabled
                      ? 'Protección activa'
                      : 'Protección desactivada',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: controller.accessibilityEnabled
                        ? scheme.onPrimary
                        : scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Accesibilidad permite a NOPE detectar la app visible y devolver '
            'el teléfono a la pantalla de foco. No inspecciona contenido.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: controller.accessibilityEnabled
                  ? scheme.onPrimary.withValues(alpha: .72)
                  : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: controller.openAccessibilitySettings,
            style: FilledButton.styleFrom(
              backgroundColor: controller.accessibilityEnabled
                  ? scheme.onPrimary
                  : scheme.primary,
              foregroundColor: controller.accessibilityEnabled
                  ? scheme.primary
                  : scheme.onPrimary,
            ),
            child: Text(
              controller.accessibilityEnabled ? 'REVISAR PERMISO' : 'ACTIVAR',
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ClockChoice extends StatelessWidget {
  const _ClockChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon),
      title: Text(label),
      trailing: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 15,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }
}

class _EssentialRow extends StatelessWidget {
  const _EssentialRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.active = true,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        active ? Icons.check_rounded : Icons.remove_rounded,
        size: 20,
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
