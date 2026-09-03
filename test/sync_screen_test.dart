import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/core/design/design.dart';
import 'package:scanapp/core/sync/application/sync_queue_controller.dart';
import 'package:scanapp/features/sync/presentation/sync_screen.dart';

void main() {
  const Size portrait = Size(320, 533);
  const Size landscape = Size(533, 320);

  ProviderContainer makeContainer() {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpSync(
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
              child: const SyncScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The local-queue card sits below three mode cards, so on a 320x533 canvas
  /// the lazy ListView has not built it until scrolled to.
  Future<void> scrollToBottom(WidgetTester tester) async {
    for (int i = 0; i < 4; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
    }
  }

  group('derived figures', () {
    testWidgets('the strip reads from the queue', (WidgetTester tester) async {
      await pumpSync(tester, container: makeContainer());

      expect(find.text('Offline Sync'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // pending
      expect(find.text('0'), findsOneWidget); // failed
      expect(find.text('08:09'), findsOneWidget); // last push
    });

    testWidgets('the local queue card is computed, not hardcoded', (
      WidgetTester tester,
    ) async {
      await pumpSync(tester, container: makeContainer());
      await scrollToBottom(tester);

      expect(find.text('2 scans'), findsOneWidget);
      expect(find.text('08:07'), findsOneWidget); // oldest of the two records
      expect(find.text('4.1 kB'), findsOneWidget); // 2 x 2050 bytes
      expect(find.text('08:09  ·  accepted'), findsOneWidget);
    });

    testWidgets('store & forward with work waiting reads as accumulating', (
      WidgetTester tester,
    ) async {
      await pumpSync(tester, container: makeContainer());

      expect(find.text('Store & forward'), findsWidgets);
      expect(find.text('ACCUMULATING'), findsOneWidget);
    });
  });

  group('mode selection', () {
    testWidgets('choosing online direct changes the state word', (
      WidgetTester tester,
    ) async {
      await pumpSync(tester, container: makeContainer());
      expect(find.text('ACCUMULATING'), findsOneWidget);

      await tester.tap(find.text('Online direct'));
      await tester.pumpAndSettle();

      // Nothing is held locally in online mode, so the outbox reads as live.
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('ACCUMULATING'), findsNothing);
    });

    testWidgets('choosing air-gapped reads as archiving', (
      WidgetTester tester,
    ) async {
      await pumpSync(tester, container: makeContainer());

      // The third card is below the fold, so the lazy ListView has not built
      // it yet.
      await tester.scrollUntilVisible(find.text('Air-gapped depot'), 200);
      await tester.tap(find.text('Air-gapped depot'));
      await tester.pumpAndSettle();

      // The banner is pinned, so it is still on screen after scrolling.
      expect(find.text('ARCHIVING'), findsOneWidget);
    });
  });

  group('flushing', () {
    testWidgets('empties the queue and the tab badge together', (
      WidgetTester tester,
    ) async {
      final ProviderContainer container = makeContainer();
      await pumpSync(tester, container: container);

      // The badge the shell renders comes from the same provider.
      expect(container.read(pendingSyncCountProvider), 2);

      await tester.tap(find.text('Flush queue now'));
      await tester.pumpAndSettle();

      expect(container.read(pendingSyncCountProvider), 0);
      expect(find.text('0'), findsWidgets);

      await scrollToBottom(tester);
      expect(find.text('0 scans'), findsOneWidget);
      expect(find.text('—'), findsOneWidget); // no oldest record left
      expect(find.text('0 B'), findsOneWidget); // nothing to send
    });

    testWidgets('the action is disabled once there is nothing to send', (
      WidgetTester tester,
    ) async {
      await pumpSync(tester, container: makeContainer());

      await tester.tap(find.text('Flush queue now'));
      await tester.pumpAndSettle();

      final FilledButton button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('Flush queue now'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('responsive', () {
    testWidgets('portrait has no overflow', (WidgetTester tester) async {
      await pumpSync(tester, container: makeContainer());
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape has no overflow', (WidgetTester tester) async {
      await pumpSync(tester, container: makeContainer(), size: landscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('font scale 1.3 has no overflow', (WidgetTester tester) async {
      await pumpSync(tester, container: makeContainer(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape at font scale 1.3 has no overflow', (
      WidgetTester tester,
    ) async {
      await pumpSync(
        tester,
        container: makeContainer(),
        size: landscape,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
