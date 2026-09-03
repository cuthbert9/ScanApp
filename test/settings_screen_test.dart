import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/core/design/design.dart';
import 'package:scanapp/shared/widgets/widgets.dart';
import 'package:scanapp/core/sync/application/sync_queue_controller.dart';
import 'package:scanapp/features/auth/application/auth_controller.dart';
import 'package:scanapp/features/settings/application/display_preferences.dart';
import 'package:scanapp/features/settings/application/preferences_controller.dart';
import 'package:scanapp/features/settings/presentation/settings_screen.dart';

void main() {
  const Size portrait = Size(320, 533);
  const Size landscape = Size(533, 320);

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpSettings(
    WidgetTester tester, {
    required ProviderContainer container,
    Size size = portrait,
    double textScale = 1.0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: const SettingsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The page is long, so most of it is outside the lazy ListView's build range
  /// until scrolled to.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(target, 200);
    await tester.pumpAndSettle();
  }

  group('derived figures', () {
    testWidgets('the strip reads from the shift stats', (
      WidgetTester tester,
    ) async {
      await pumpSettings(tester, container: makeContainer());

      expect(find.text('Settings'), findsOneWidget);
      // 148 appears in the strip and again in the detail rows below it, so
      // this scopes to the strip's own tile.
      expect(
        find.descendant(
          of: find.byType(AppStatTile),
          matching: find.text('148'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('99.3'),
        findsOneWidget,
      ); // first pass, unit rendered apart
      expect(find.text('%'), findsOneWidget);
      expect(find.text('6:12'), findsOneWidget); // 06:00 start, 12:12 captured
    });

    testWidgets('first-pass accuracy is computed, not stored', (
      WidgetTester tester,
    ) async {
      await pumpSettings(tester, container: makeContainer());
      // 148 scanned, 1 cold-chain hold -> 147/148 = 99.32%
      await scrollTo(tester, find.text('99.3 %'));
      expect(find.text('99.3 %'), findsOneWidget);
    });

    testWidgets('the operator card derives its initials', (
      WidgetTester tester,
    ) async {
      await pumpSettings(tester, container: makeContainer());

      expect(find.text('NM'), findsOneWidget);
      expect(find.text('Neema Mwakalinga'), findsOneWidget);
    });

    testWidgets('the station card shows the base without a map', (
      WidgetTester tester,
    ) async {
      await pumpSettings(tester, container: makeContainer());
      await scrollTo(tester, find.text('MSD-CVS-DAR'));

      expect(find.text('Dar es Salaam Central Vaccine Store'), findsOneWidget);
      expect(find.text('-6.8123, 39.2691'), findsOneWidget);
      expect(find.text('04  ·  dispatch'), findsOneWidget);
      expect(find.text('Inside  ·  40 m'), findsOneWidget);
    });
  });

  group('the weekly chart', () {
    testWidgets('captions today and the week peak', (
      WidgetTester tester,
    ) async {
      await pumpSettings(tester, container: makeContainer());
      await scrollTo(tester, find.text('Units scanned'));

      expect(find.text('148 today  ·  152 peak'), findsOneWidget);
    });

    testWidgets('tapping a bar reports that day — hover has no equivalent on a '
        'gloved handheld', (WidgetTester tester) async {
      await pumpSettings(tester, container: makeContainer());
      await scrollTo(tester, find.text('Units scanned'));

      await tester.tap(find.bySemanticsLabel('Monday, 141 units'));
      await tester.pumpAndSettle();

      expect(find.text('Monday  ·  141 units'), findsOneWidget);
      expect(find.text('148 today  ·  152 peak'), findsNothing);
    });
  });

  group('preferences actually apply', () {
    testWidgets('choosing Night changes the app theme mode', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = makeContainer();
      await pumpSettings(tester, container: container);
      expect(container.read(themePreferenceProvider), AppThemeChoice.auto);

      await scrollTo(tester, find.text('Night'));
      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle();

      expect(container.read(themePreferenceProvider), AppThemeChoice.night);
      expect(container.read(themePreferenceProvider).themeMode, ThemeMode.dark);
    });

    testWidgets('choosing Gloved raises the text scale', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = makeContainer();
      await pumpSettings(tester, container: container);

      await scrollTo(tester, find.text('Gloved'));
      await tester.tap(find.text('Gloved'));
      await tester.pumpAndSettle();

      expect(
        container.read(textScalePreferenceProvider),
        AppTextScaleChoice.gloved,
      );
      expect(
        container.read(textScalePreferenceProvider).scale,
        greaterThan(AppTextScaleChoice.standard.scale),
      );
    });
  });

  group('signing out', () {
    testWidgets('warns when the outbox still holds work', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = makeContainer();
      container.read(authControllerProvider.notifier).signIn();
      await pumpSettings(tester, container: container);

      // The seeded outbox has two unpushed records.
      expect(container.read(pendingSyncCountProvider), 2);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out with work pending?'), findsOneWidget);
      expect(
        find.textContaining('2 records have not been pushed'),
        findsOneWidget,
      );

      // Backing out leaves the operator signed in.
      await tester.tap(find.text('Stay signed in'));
      await tester.pumpAndSettle();
      expect(container.read(authControllerProvider), isTrue);
    });

    testWidgets('confirming clears the session', (WidgetTester tester) async {
      final ProviderContainer container = makeContainer();
      container.read(authControllerProvider.notifier).signIn();
      await pumpSettings(tester, container: container);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // The dialog's own confirm button, not the bar behind it.
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Sign out'),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(authControllerProvider), isFalse);
    });
  });

  group('responsive', () {
    testWidgets('portrait has no overflow', (WidgetTester tester) async {
      await pumpSettings(tester, container: makeContainer());
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape has no overflow', (WidgetTester tester) async {
      await pumpSettings(tester, container: makeContainer(), size: landscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('font scale 1.3 has no overflow', (WidgetTester tester) async {
      await pumpSettings(tester, container: makeContainer(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape at font scale 1.3 has no overflow', (
      WidgetTester tester,
    ) async {
      await pumpSettings(
        tester,
        container: makeContainer(),
        size: landscape,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
