import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LedgerColors {
  static const canvas = Color(0xFFF7F6F3);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2F3437);
  static const muted = Color(0xFF787774);
  static const hairline = Color(0xFFEAEAEA);
  static const cta = Color(0xFF111111);

  static const paleYellowBg = Color(0xFFFBF3DB);
  static const paleYellowFg = Color(0xFF956400);
  static const paleRedBg = Color(0xFFFDEBEC);
  static const paleRedFg = Color(0xFF9F2F2D);
  static const paleGreenBg = Color(0xFFEDF3EC);
  static const paleGreenFg = Color(0xFF346538);
  static const paleBlueBg = Color(0xFFE1F3FE);
  static const paleBlueFg = Color(0xFF1F6C9F);
}

ThemeData buildLedgerTheme() {
  final baseText = GoogleFonts.outfitTextTheme();
  final mono = GoogleFonts.jetBrainsMonoTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: LedgerColors.canvas,
    colorScheme: const ColorScheme.light(
      surface: LedgerColors.surface,
      primary: LedgerColors.cta,
      onPrimary: Colors.white,
      onSurface: LedgerColors.ink,
      outline: LedgerColors.hairline,
    ),
    textTheme: baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        color: LedgerColors.ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        color: LedgerColors.ink,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        color: LedgerColors.ink,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        color: LedgerColors.ink,
        height: 1.5,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        color: LedgerColors.ink,
        height: 1.5,
      ),
      bodySmall: baseText.bodySmall?.copyWith(color: LedgerColors.muted),
      labelLarge: baseText.labelLarge?.copyWith(
        color: LedgerColors.ink,
        fontWeight: FontWeight.w500,
      ),
    ).apply(bodyColor: LedgerColors.ink, displayColor: LedgerColors.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: LedgerColors.canvas,
      foregroundColor: LedgerColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: baseText.titleLarge?.copyWith(
        color: LedgerColors.ink,
        fontWeight: FontWeight.w500,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: LedgerColors.hairline,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LedgerColors.surface,
      labelStyle: const TextStyle(color: LedgerColors.muted),
      hintStyle: const TextStyle(color: LedgerColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: LedgerColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: LedgerColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: LedgerColors.ink, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: LedgerColors.paleRedFg),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LedgerColors.cta,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LedgerColors.ink,
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: LedgerColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: LedgerColors.ink),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LedgerColors.surface,
      selectedColor: LedgerColors.cta,
      labelStyle: const TextStyle(color: LedgerColors.ink, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      side: const BorderSide(color: LedgerColors.hairline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LedgerColors.surface,
      indicatorColor: LedgerColors.hairline,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          color: LedgerColors.ink,
        );
      }),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(color: LedgerColors.ink, size: 22),
      ),
      elevation: 0,
      height: 64,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LedgerColors.cta,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    cardTheme: CardThemeData(
      color: LedgerColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: LedgerColors.hairline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LedgerColors.ink,
      contentTextStyle: baseText.bodyMedium?.copyWith(color: Colors.white),
    ),
    extensions: [
      LedgerTypeExt(mono: mono.bodyMedium?.copyWith(color: LedgerColors.ink)),
    ],
  );
}

class LedgerTypeExt extends ThemeExtension<LedgerTypeExt> {
  const LedgerTypeExt({required this.mono});

  final TextStyle? mono;

  @override
  LedgerTypeExt copyWith({TextStyle? mono}) =>
      LedgerTypeExt(mono: mono ?? this.mono);

  @override
  LedgerTypeExt lerp(ThemeExtension<LedgerTypeExt>? other, double t) {
    if (other is! LedgerTypeExt) return this;
    return LedgerTypeExt(mono: TextStyle.lerp(mono, other.mono, t));
  }
}
