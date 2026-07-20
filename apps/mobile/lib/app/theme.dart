import 'package:flutter/material.dart';

@immutable
class AutomotiveColors extends ThemeExtension<AutomotiveColors> {
  const AutomotiveColors({
    required this.metal,
    required this.metalBright,
    required this.info,
    required this.warning,
    required this.requiredAction,
    required this.error,
    required this.onWarning,
    required this.success,
    required this.onSuccess,
    required this.track,
    required this.trackActive,
  });

  static const dark = AutomotiveColors(
    metal: Color(0xFF68747B),
    metalBright: Color(0xFFB8C2C7),
    info: Color(0xFF64B5F6),
    warning: Color(0xFFF2A72B),
    requiredAction: Color(0xFFFF8A3D),
    error: Color(0xFFFF6B63),
    onWarning: Color(0xFF251700),
    success: Color(0xFF65C18C),
    onSuccess: Color(0xFF002111),
    track: Color(0xFF30383D),
    trackActive: Color(0xFFF2A72B),
  );

  final Color metal;
  final Color metalBright;
  final Color info;
  final Color warning;
  final Color requiredAction;
  final Color error;
  final Color onWarning;
  final Color success;
  final Color onSuccess;
  final Color track;
  final Color trackActive;

  @override
  AutomotiveColors copyWith({
    Color? metal,
    Color? metalBright,
    Color? info,
    Color? warning,
    Color? requiredAction,
    Color? error,
    Color? onWarning,
    Color? success,
    Color? onSuccess,
    Color? track,
    Color? trackActive,
  }) {
    return AutomotiveColors(
      metal: metal ?? this.metal,
      metalBright: metalBright ?? this.metalBright,
      info: info ?? this.info,
      warning: warning ?? this.warning,
      requiredAction: requiredAction ?? this.requiredAction,
      error: error ?? this.error,
      onWarning: onWarning ?? this.onWarning,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      track: track ?? this.track,
      trackActive: trackActive ?? this.trackActive,
    );
  }

  @override
  AutomotiveColors lerp(
    covariant ThemeExtension<AutomotiveColors>? other,
    double t,
  ) {
    if (other is! AutomotiveColors) {
      return this;
    }
    return AutomotiveColors(
      metal: Color.lerp(metal, other.metal, t)!,
      metalBright: Color.lerp(metalBright, other.metalBright, t)!,
      info: Color.lerp(info, other.info, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      requiredAction: Color.lerp(requiredAction, other.requiredAction, t)!,
      error: Color.lerp(error, other.error, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      track: Color.lerp(track, other.track, t)!,
      trackActive: Color.lerp(trackActive, other.trackActive, t)!,
    );
  }
}

ThemeData buildAutoDoctorTheme() {
  const scheme = ColorScheme.dark(
    primary: Color(0xFFF2A72B),
    onPrimary: Color(0xFF251700),
    primaryContainer: Color(0xFF4A3208),
    onPrimaryContainer: Color(0xFFFFDDA5),
    secondary: Color(0xFF91A4B1),
    onSecondary: Color(0xFF102028),
    secondaryContainer: Color(0xFF273943),
    onSecondaryContainer: Color(0xFFCDE5F2),
    tertiary: Color(0xFFB8C4CA),
    onTertiary: Color(0xFF1A252A),
    error: Color(0xFFFF6B63),
    onError: Color(0xFF350300),
    errorContainer: Color(0xFF5C1714),
    onErrorContainer: Color(0xFFFFDAD7),
    surface: Color(0xFF111518),
    onSurface: Color(0xFFE4E8EA),
    onSurfaceVariant: Color(0xFFA8B1B7),
    outline: Color(0xFF59646B),
    outlineVariant: Color(0xFF30383D),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE4E8EA),
    onInverseSurface: Color(0xFF252A2D),
    inversePrimary: Color(0xFF7C5700),
    surfaceTint: Color(0xFFF2A72B),
    surfaceContainerLowest: Color(0xFF090C0E),
    surfaceContainerLow: Color(0xFF13181C),
    surfaceContainer: Color(0xFF171D21),
    surfaceContainerHigh: Color(0xFF1D2429),
    surfaceContainerHighest: Color(0xFF242C32),
  );

  final baseTextTheme = Typography.material2021(
    platform: TargetPlatform.android,
  ).white;
  final textTheme = baseTextTheme
      .copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -1.2,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -0.8,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.4,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          height: 1.45,
          letterSpacing: 0.1,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          height: 1.45,
          letterSpacing: 0.1,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          height: 1.4,
          letterSpacing: 0.2,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      )
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

  const controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
  );

  return ThemeData(
    colorScheme: scheme,
    brightness: Brightness.dark,
    useMaterial3: true,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    visualDensity: VisualDensity.compact,
    splashFactory: InkSparkle.splashFactory,
    extensions: const [AutomotiveColors.dark],
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Color(0xFF171D21),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Color(0xFF30383D)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: controlShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: scheme.outline),
        shape: controlShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: controlShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh,
      selectedColor: scheme.primaryContainer,
      disabledColor: scheme.surfaceContainerLow,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: scheme.onPrimaryContainer,
      ),
      checkmarkColor: scheme.primary,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      modalBackgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelSmall?.copyWith(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 0.4,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          size: 24,
        );
      }),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.secondary,
      textColor: scheme.onSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      minTileHeight: 52,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
      circularTrackColor: scheme.outlineVariant,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
