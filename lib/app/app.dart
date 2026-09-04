import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../domain/models/display_choice.dart';
import 'router/app_router.dart';
import 'state/preferences_controller.dart';

/// Maps the operator's choice onto Flutter's [ThemeMode].
///
/// Kept here rather than on the enum so the domain stays free of Flutter.
extension ThemeChoiceMode on ThemeChoice {
  ThemeMode get themeMode => switch (this) {
    ThemeChoice.day => ThemeMode.light,
    ThemeChoice.night => ThemeMode.dark,
    ThemeChoice.auto => ThemeMode.system,
  };
}

/// The application root.
///
/// Holds only wiring — theme, text scale, router. Anything with behaviour
/// belongs in a feature or the domain.
class ScanApp extends ConsumerWidget {
  const ScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final ThemeChoice theme = ref.watch(resolvedThemeChoiceProvider);
    final TextScaleChoice textScale = ref.watch(resolvedTextScaleProvider);

    return MaterialApp.router(
      title: 'scanapp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // The operator's choice, from Settings. Changing it repaints all five
      // screens on the tap — the whole app reads one token set.
      themeMode: theme.themeMode,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) =>
          _TextScale(choice: textScale, child: child),
    );
  }
}

/// Applies the text-size preference on top of the device's own accessibility
/// setting.
///
/// It *multiplies* rather than replaces: someone who has already turned system
/// font size up should not have it silently reset by choosing `Gloved`.
class _TextScale extends StatelessWidget {
  const _TextScale({required this.choice, required this.child});

  final TextScaleChoice choice;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    final MediaQueryData media = MediaQuery.of(context);

    // Read the device's effective factor by scaling a reference size. Exact for
    // a linear scaler, and a fair approximation of a non-linear one.
    final double deviceFactor = media.textScaler.scale(100) / 100;

    return MediaQuery(
      data: media.copyWith(
        textScaler: TextScaler.linear(deviceFactor * choice.scale),
      ),
      child: child!,
    );
  }
}
