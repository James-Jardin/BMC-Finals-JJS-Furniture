import 'package:flutter/material.dart';

abstract final class JJ {
  // Core palette measured from the reference prototype.
  static const background = Color(0xFF131117);
  static const card = Color(0xFF211913);
  static const cardRaised = Color(0xFF2A211A);
  static const header = Color(0xFF19110C);
  static const navigation = Color(0xFF261D17);
  static const selected = Color(0xFF5C4130);
  static const copper = Color(0xFFC67C4E);
  static const copperDeep = Color(0xFF9B5C33);
  static const peach = Color(0xFFFFB68C);
  static const cream = Color(0xFFFAF8F3);
  static const text = Color(0xFFE8E1EC);
  static const muted = Color(0xFFD7C4B5);
  static const green = Color(0xFF879774);
  static const success = Color(0xFF9DB985);
  static const gold = Color(0xFFF2B279);
  static const outline = Color(0xFFB5A498);
  static const star = Color(0xFFFFA600);
  static const danger = Color(0xFFFFB4AB);
  static const line = Color(0xFF3B2C24);
  static const inputFill = Color(0xFFF7F1E8);

  static const radius = 18.0;
  static const radiusLarge = 26.0;

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF251C15), Color(0xFF1D1611)],
  );
  static const copperGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [peach, Color(0xFFE89B6C)],
  );
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [copper, copperDeep],
  );
  static const promoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF684A3A), Color(0xFF4A2F22)],
  );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: peach,
      onPrimary: header,
      primaryContainer: selected,
      onPrimaryContainer: cream,
      secondary: copper,
      onSecondary: header,
      surface: card,
      onSurface: text,
      surfaceContainerHighest: cardRaised,
      onSurfaceVariant: muted,
      outline: outline,
      outlineVariant: line,
      error: danger,
      onError: header,
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.12,
        letterSpacing: -0.6,
        color: text,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.15,
        letterSpacing: -0.4,
        color: text,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        height: 1.2,
        letterSpacing: -0.3,
        color: text,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.2,
        color: text,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        color: text,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.3,
        color: text,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: muted),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: muted),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: muted),
      labelLarge: TextStyle(
        fontSize: 15,
        letterSpacing: 0.2,
        fontWeight: FontWeight.w600,
        color: text,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: header,
      foregroundColor: cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      titleTextStyle: TextStyle(
        fontSize: 21,
        color: cream,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        fontFamily: 'Roboto',
      ),
      iconTheme: IconThemeData(color: cream, size: 23),
      actionsIconTheme: IconThemeData(color: cream, size: 22),
    ),
    iconTheme: const IconThemeData(color: muted, size: 22),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      hintStyle: const TextStyle(
        color: Color(0xFF9C8778),
        fontSize: 15,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF7B6658),
        fontSize: 15,
        fontFamily: 'Roboto',
      ),
      floatingLabelStyle: const TextStyle(
        color: selected,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Roboto',
      ),
      prefixIconColor: selected,
      suffixIconColor: selected,
      border: const JJInputBorder(),
      enabledBorder: const JJInputBorder(),
      focusedBorder: const JJInputBorder(
        borderSide: BorderSide(color: peach, width: 1.6),
      ),
      errorBorder: const JJInputBorder(
        borderSide: BorderSide(color: danger, width: 1.2),
      ),
      focusedErrorBorder: const JJInputBorder(
        borderSide: BorderSide(color: danger, width: 1.6),
      ),
      disabledBorder: const JJInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: peach,
        foregroundColor: header,
        disabledBackgroundColor: selected.withValues(alpha: 0.55),
        disabledForegroundColor: muted.withValues(alpha: 0.7),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          fontFamily: 'Roboto',
        ),
        elevation: 0,
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: cream,
        minimumSize: const Size(48, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: const BorderSide(color: line),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: peach,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: cream,
        highlightColor: selected.withValues(alpha: 0.45),
        shape: const CircleBorder(),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: peach,
      foregroundColor: header,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 6,
      shape: StadiumBorder(),
      extendedTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        fontFamily: 'Roboto',
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: line,
      thickness: 1,
      space: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: cream,
        fontFamily: 'Roboto',
      ),
      contentTextStyle: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: muted,
        fontFamily: 'Roboto',
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: card,
      modalBarrierColor: Color(0xB3000000),
      dragHandleColor: outline,
      dragHandleSize: Size(38, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: cardRaised,
      contentTextStyle: const TextStyle(
        color: cream,
        fontSize: 14,
        fontFamily: 'Roboto',
      ),
      actionTextColor: peach,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: header,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: line),
      ),
      textStyle: const TextStyle(
        color: cream,
        fontSize: 12,
        fontFamily: 'Roboto',
      ),
      waitDuration: const Duration(milliseconds: 450),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: peach,
      linearTrackColor: line,
      circularTrackColor: line,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(
        outline.withValues(alpha: 0.35),
      ),
      radius: const Radius.circular(20),
      thickness: const WidgetStatePropertyAll(5),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: copper,
      selectionColor: Color(0x66C67C4E),
      selectionHandleColor: copper,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: muted,
      textColor: cream,
      titleTextStyle: TextStyle(
        fontSize: 16,
        color: cream,
        fontWeight: FontWeight.w500,
        fontFamily: 'Roboto',
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: muted,
        fontFamily: 'Roboto',
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? header : muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? peach : JJ.cardRaised,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? peach : JJ.line,
      ),
    ),
  );

  static String money(num value) => '\u20B1${value.toStringAsFixed(2)}';

  /// Compact percentage-style label used in the dashboard.
  static String compact(num value) => value >= 1000
      ? '\u20B1${(value / 1000).toStringAsFixed(value >= 100000 ? 0 : 1)}k'
      : '\u20B1${value.toStringAsFixed(0)}';
}

/// A filled field border that keeps its floating label inside the fill.
///
/// [OutlineInputBorder] places the floating label on the top border line, which
/// makes it collide with the filled background when the border is transparent.
/// An underline-shaped border floats the label inside instead; this subclass
/// paints a full rounded outline when a border side is supplied.
class JJInputBorder extends UnderlineInputBorder {
  const JJInputBorder({
    super.borderSide = BorderSide.none,
    super.borderRadius = const BorderRadius.all(Radius.circular(28)),
  });

  @override
  JJInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) => JJInputBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  JJInputBorder scale(double t) =>
      JJInputBorder(borderSide: borderSide.scale(t), borderRadius: borderRadius);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) return;
    final outline = borderRadius
        .resolve(textDirection)
        .toRRect(rect)
        .deflate(borderSide.width / 2);
    canvas.drawRRect(outline, borderSide.toPaint());
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is JJInputBorder) {
      return JJInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is JJInputBorder) {
      return JJInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }
}
