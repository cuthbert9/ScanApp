import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/core/design/design.dart';
import 'package:scanapp/features/loading/application/scan_session_controller.dart';
import 'package:scanapp/features/loading/presentation/load_reconciliation_screen.dart';

void main() {
  /// Resolves against the fake catalogue and is not already on the load.
  const String oxytocin = '(00)3600980000004407(10)OXY26A001(17)271130';

  const Size portrait = Size(320, 533);
  const Size landscape = Size(533, 320);

  /// Pumps the screen against [container], so a test can drive the session
  /// before rendering.
  Future<void> pumpLoad(
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
              child: const LoadReconciliationScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The notice sits below the two cards, so on a 320x533 canvas it is outside
  /// the lazy ListView's build range until scrolled to.
  Future<void> scrollToBottom(WidgetTester tester) async {
    for (int i = 0; i < 3; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
  }

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('derived figures', () {
    testWidgets('every line comes from the session', (
      WidgetTester tester,
    ) async {
      await pumpLoad(tester, container: makeContainer());

      expect(find.text('14 units'), findsOneWidget);
      expect(find.text('13 units'), findsOneWidget);
      expect(find.text('1  ·  FEFO hold'), findsOneWidget);
      expect(find.text('92.9 %'), findsOneWidget);
    });

    testWidgets('utilisation is summed from the verified records', (
      WidgetTester tester,
    ) async {
      await pumpLoad(tester, container: makeContainer());

      expect(find.text('2 986 / 8 000 kg'), findsOneWidget);
      expect(find.text('18.4 / 26.0 m³'), findsOneWidget);
      expect(find.textContaining('stable'), findsOneWidget);
    });

    testWidgets('a short load warns about the amended manifest', (
      WidgetTester tester,
    ) async {
      await pumpLoad(tester, container: makeContainer());
      await scrollToBottom(tester);

      expect(
        find.textContaining('will print 13 lines, not 14'),
        findsOneWidget,
      );
    });
  });

  group('shared session', () {
    testWidgets('a scan on the session moves every load figure', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = makeContainer();

      // Pump first. Inside testWidgets the clock is faked, so awaiting the
      // repository's future before any pump would never complete.
      await pumpLoad(tester, container: container);
      expect(find.text('13 units'), findsOneWidget);

      // Now drive the session the way the Scan tab would.
      container
          .read(scanSessionControllerProvider.notifier)
          .submitScan(oxytocin);
      await tester.pumpAndSettle();

      // 14 of 14 now verified: nothing short, the warning is gone, and the
      // yield is 100%. This is why scan and load are one feature.
      expect(find.text('14 units'), findsNWidgets(2));
      expect(find.text('100.0 %'), findsOneWidget);

      // Scroll to where the notice would be, so its absence is real rather
      // than an artefact of it never having been built.
      await scrollToBottom(tester);
      expect(
        find.textContaining('amended manifest'),
        findsNothing,
        reason: 'a clean load has nothing to warn about',
      );
    });
  });

  group('responsive', () {
    testWidgets('portrait has no overflow', (WidgetTester tester) async {
      await pumpLoad(tester, container: makeContainer());
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape has no overflow', (WidgetTester tester) async {
      await pumpLoad(tester, container: makeContainer(), size: landscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('font scale 1.3 has no overflow', (WidgetTester tester) async {
      await pumpLoad(tester, container: makeContainer(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape at font scale 1.3 has no overflow', (
      WidgetTester tester,
    ) async {
      await pumpLoad(
        tester,
        container: makeContainer(),
        size: landscape,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
