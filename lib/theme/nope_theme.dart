import 'package:flutter/material.dart';

class NopeTheme {
  static const palettes = <Color>[
    Color(0xFF171717),
    Color(0xFF17324D),
    Color(0xFF1E4638),
  ];

  static ThemeData build({required bool dark, required int paletteIndex}) {
    final seed = palettes[paletteIndex.clamp(0, palettes.length - 1)];
    final brightness = dark ? Brightness.dark : Brightness.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
          surface: dark ? const Color(0xFF111111) : const Color(0xFFF7F7F4),
        ).copyWith(
          primary: dark ? const Color(0xFFF4F4EF) : seed,
          onPrimary: dark ? const Color(0xFF111111) : Colors.white,
          surfaceContainer: dark
              ? const Color(0xFF1B1B1B)
              : const Color(0xFFFFFFFF),
          surfaceContainerHighest: dark
              ? const Color(0xFF292929)
              : const Color(0xFFECECE8),
          outline: dark ? const Color(0xFF5E5E5E) : const Color(0xFFCBCBC5),
        );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -3,
          height: .96,
        ),
        displayMedium: text.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -2,
          height: 1,
        ),
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          height: 1.05,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.onSurface,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? scheme.surface
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
