import 'package:flutter/material.dart';

/// Shared values from the exported screen CSS. Screens use these via the theme.
abstract final class RemoriColors {
  static const purple = Color(0xFF6D4AA8);
  static const purpleHover = Color(0xFF57398C);
  static const cream = Color(0xFFF7F4EE);
  static const surface = Color(0xFFFEFEFE);
  static const ink = Color(0xFF141414);
  static const muted = Color(0xAD000000);
  static const border = Color(0xCC6D4AA8);
  static const success = Color(0xFFCFE8C9);
  static const successInk = Color(0xFF2F5130);
  static const warning = Color(0xFFFBE7B5);
  static const warningInk = Color(0xFF7A5410);
  static const danger = Color(0xFFF9D5CC);
  static const dangerInk = Color(0xFF9A3B26);
  static const lavender = Color(0xFFD9CCF0);
  static const blue = Color(0xFFAFC8E8);
  static const waveLilac = Color(0xFFE4D9E9);
  static const wavePink = Color(0xFFECD9E1);
  static const waveLine = Color(0xFF8C6CC7);
  static const curveLilac = Color(0xFFDFE0EB);
  static const curveGreen = Color(0xFFE1E8DA);
  static const curveBlue = Color(0xFFD9E1EE);
  static const curvePink = Color(0xFFF4DDD6);
  static const curveLine = Color(0xFF9DB3D8);
}

enum RemoriMode { caregiver, patient }

/// Each shell selects its mode; locale independently controls text direction.
abstract final class RemoriTheme {
  static const buttonShadow = BoxShadow(
    color: Color(0x306D4AA8),
    offset: Offset(0, 8),
    blurRadius: 20,
  );
  static const statusShadows = [
    BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x26000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 1,
    ),
  ];
  static const navigationShadow = BoxShadow(
    color: Color(0x146D4AA8),
    offset: Offset(0, -3),
    blurRadius: 8,
  );
  static const actionShadow = BoxShadow(
    color: Color(0x476D4AA8),
    offset: Offset(0, 6),
    blurRadius: 16,
  );

  static ThemeData forMode(RemoriMode mode, {bool arabic = false}) {
    final patient = mode == RemoriMode.patient;
    final family = arabic ? 'Readex Pro' : 'DM Sans';
    final headingFamily = arabic ? 'Readex Pro' : 'Manrope';
    final textTheme = TextTheme(
      headlineLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: patient ? 32 : 28,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: patient ? 32 : 22,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: patient ? 24 : 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontFamily: family, fontSize: patient ? 22 : 15),
      bodyMedium: TextStyle(fontFamily: family, fontSize: patient ? 22 : 14),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: patient ? 22 : 13,
        color: RemoriColors.muted,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: patient ? 24 : 17,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontFamily: family,
        fontSize: patient ? 22 : 14,
        fontWeight: FontWeight.w600,
      ),
    ).apply(bodyColor: RemoriColors.ink, displayColor: RemoriColors.ink);
    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, patient ? 64 : 52)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return RemoriColors.purple.withValues(alpha: .38);
        }
        return states.contains(WidgetState.hovered)
            ? RemoriColors.purpleHover
            : RemoriColors.purple;
      }),
      foregroundColor: const WidgetStatePropertyAll(RemoriColors.surface),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: family,
      colorScheme: const ColorScheme.light(
        primary: RemoriColors.purple,
        onPrimary: RemoriColors.surface,
        surface: RemoriColors.surface,
        onSurface: RemoriColors.ink,
        error: RemoriColors.dangerInk,
        onError: RemoriColors.surface,
        outline: RemoriColors.border,
      ),
      scaffoldBackgroundColor: RemoriColors.cream,
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: buttonStyle.copyWith(
          backgroundColor: const WidgetStatePropertyAll(RemoriColors.surface),
          foregroundColor: const WidgetStatePropertyAll(RemoriColors.purple),
          side: WidgetStatePropertyAll(
            BorderSide(color: RemoriColors.purple, width: patient ? 2 : 1),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RemoriColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: RemoriColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: RemoriColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(color: RemoriColors.purple, width: 2),
        ),
      ),
    );
  }
}
