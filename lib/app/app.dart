import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/design.dart';
import '../features/settings/application/display_preferences.dart';
import '../features/settings/application/preferences_controller.dart';
import 'router/app_router.dart';

/// The application root.
///
/// Holds only wiring — theme, text scale, router. Anything with behaviour
/// belongs in a feature.
class ScanApp extends ConsumerWidget {
  const ScanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(appRouterProvider);
    final AppThemeChoice themeChoice = ref.watch(themePreferenceProvider);
    final AppTextScaleChoice textChoice = ref.watch(
      textScalePreferenceProvider,
    );

    return MaterialApp.router(
      title: 'scanapp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // The operator's choice, from Settings. `Auto` follows the device, which
      // is what an outdoor dock wants after sunset.
      themeMode: themeChoice.themeMode,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) =>
          _TextScale(choice: textChoice, child: child),
    );
  }
}

/// Applies the operator's text-size preference on top of the device's own
/// accessibility setting.
///
/// It *multiplies* rather than replaces: someone who has already turned system
/// font size up should not have it silently reset by choosing `Gloved`.
class _TextScale extends StatelessWidget {
  const _TextScale({required this.choice, required this.child});

  final AppTextScaleChoice choice;
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
