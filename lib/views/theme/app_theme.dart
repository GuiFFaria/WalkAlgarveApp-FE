import 'package:flutter/material.dart';

/// Light and dark themes built from the design system's color tokens.
class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  static final light = _build(
    background: const Color(0xFFF6F6F3),
    colors: const ColorScheme.light(
      surface: Color(0xFFFFFFFF),
      surfaceContainerHighest: Color(0xFFECEEEA),
      onSurface: Color(0xFF13262B),
      onSurfaceVariant: Color(0xFF52666B),
      outline: Color(0xFF7E9196),
      outlineVariant: Color(0xFFDDE1DD),
      primary: Color(0xFF0B6B72),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFDDEEED),
      onPrimaryContainer: Color(0xFF0B6B72),
      secondary: Color(0xFFE9A23B),
      onSecondary: Color(0xFF13262B),
      secondaryContainer: Color(0xFFFBEFD9),
      onSecondaryContainer: Color(0xFF7A4A00),
      tertiary: Color(0xFF1F6B45),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE2F2E8),
      onTertiaryContainer: Color(0xFF1F6B45),
      error: Color(0xFFB3261E),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFBE9E7),
      onErrorContainer: Color(0xFFB3261E),
    ),
  );

  static final dark = _build(
    background: const Color(0xFF0E1719),
    colors: const ColorScheme.dark(
      surface: Color(0xFF162225),
      surfaceContainerHighest: Color(0xFF1F2D31),
      onSurface: Color(0xFFE8F0EF),
      onSurfaceVariant: Color(0xFF9DB1B4),
      outline: Color(0xFF5E767B),
      outlineVariant: Color(0xFF2A3B3F),
      primary: Color(0xFF5CC4C2),
      onPrimary: Color(0xFF06282A),
      primaryContainer: Color(0xFF173A3C),
      onPrimaryContainer: Color(0xFF5CC4C2),
      secondary: Color(0xFFF2B65A),
      onSecondary: Color(0xFF2A1A00),
      secondaryContainer: Color(0xFF3A2C12),
      onSecondaryContainer: Color(0xFFF6CE8B),
      tertiary: Color(0xFF8FDDB1),
      onTertiary: Color(0xFF14352A),
      tertiaryContainer: Color(0xFF14352A),
      onTertiaryContainer: Color(0xFF8FDDB1),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF3D1A17),
      errorContainer: Color(0xFF3D1A17),
      onErrorContainer: Color(0xFFFFB4AB),
    ),
  );

  static ThemeData _build({
    required Color background,
    required ColorScheme colors,
  }) {
    // Material reads several container shades; the design has one surface.
    final scheme = colors.copyWith(
      surfaceContainerLowest: colors.surface,
      surfaceContainerLow: colors.surface,
      surfaceContainer: colors.surface,
      surfaceContainerHigh: colors.surface,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(colorScheme: scheme, fontFamily: fontFamily);
    final text = base.textTheme.copyWith(
      headlineMedium: _style(28, FontWeight.w800, 1.2, scheme.onSurface),
      titleLarge: _style(20, FontWeight.w800, 1.3, scheme.onSurface),
      titleMedium: _style(16, FontWeight.w700, 1.35, scheme.onSurface),
      bodyLarge: _style(16, FontWeight.w400, 1.5, scheme.onSurface),
      bodyMedium: _style(15, FontWeight.w400, 1.5, scheme.onSurface),
      bodySmall: _style(13, FontWeight.w400, 1.45, scheme.onSurfaceVariant),
      labelLarge: _style(16, FontWeight.w700, 1.35, scheme.onSurface),
    );

    const buttonSize = Size(64, 52);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final filledButton = FilledButton.styleFrom(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      minimumSize: buttonSize,
      shape: buttonShape,
      textStyle: text.labelLarge,
      elevation: 0,
    );

    OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: filledButton),
      filledButtonTheme: FilledButtonThemeData(style: filledButton),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.secondary,
        foregroundColor: scheme.onSecondary,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: fieldBorder(scheme.outline),
        focusedBorder: fieldBorder(scheme.primary, 2),
        errorBorder: fieldBorder(scheme.error, 2),
        focusedErrorBorder: fieldBorder(scheme.error, 2),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: _style(12, FontWeight.w700, 1.35, scheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        dragHandleColor: scheme.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  static TextStyle _style(
    double size,
    FontWeight weight,
    double height,
    Color color,
  ) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );
}
