import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/core/design/design.dart';
import 'package:scanapp/features/loading/presentation/scan_screen.dart';
import 'package:scanapp/shared/widgets/widgets.dart';

void main() {
  /// Codes that resolve against the fake catalogue.
  const String oxytocin = '(00)3600980000004407(10)OXY26A001(17)271130';
  const String rutf = '(00)3600980000004406(10)RTF26B002(17)280430';
  const String alreadyScanned = '(00)3600980000004404(10)MRD24L221(17)270930';
  const String notOnManifest = '(00)9999999999999999(10)XXX999(17)300101';

  /// The real device, upright.
  const Size portrait = Size(320, 533);

  /// Rotated: only 320 dp of height.
  const Size landscape = Size(533, 320);

  Future<void> pumpScan(
    WidgetTester tester, {
    Size size = portrait,
    double textScale = 1.0,
    double keyboardInset = 0,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (BuildContext context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                viewInsets: EdgeInsets.only(bottom: keyboardInset),
              ),
              child: const ScanScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Enters [code] and fires the keyboard's done action, which is what a
  /// DataWedge keyboard-wedge scan does on a real device.
  Future<void> scan(WidgetTester tester, String code) async {
    await tester.enterText(find.byType(TextField), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  group('seeded session', () {
    testWidgets('renders the feed and derives every count', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester);

      expect(find.text('Scan & Verify'), findsOneWidget);
      // Product names render inside Text.rich, so plain find.text misses them.
      expect(
        find.textContaining('Zinc Sulfate 20 mg', findRichText: true),
        findsOneWidget,
      );

      // 13 of 14 loaded, from 14 records of which one is held.
      expect(find.text('13/14'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppStatTile),
          matching: find.text('13'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(AppStatTile), matching: find.text('1')),
        findsOneWidget,
      );
    });
  });

  group('manifest rules', () {
    testWidgets('a valid unscanned unit completes the load', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester);
      expect(find.text('13/14'), findsOneWidget);

      await scan(tester, oxytocin);

      expect(find.text('14/14'), findsOneWidget);
      expect(
        find.textContaining('Oxytocin 10 IU', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('scanning past the manifest is held, not accepted', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester);
      await scan(tester, oxytocin); // completes 14/14
      await scan(tester, rutf); // one too many

      expect(
        find.text('14/14'),
        findsOneWidget,
        reason: 'load must not exceed 14',
      );
      expect(
        find.textContaining('Over-count', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a duplicate is held', (WidgetTester tester) async {
      await pumpScan(tester);
      await scan(tester, alreadyScanned);

      expect(
        find.textContaining('Duplicate', findRichText: true),
        findsOneWidget,
      );
      // A duplicate does not advance the load.
      expect(find.text('13/14'), findsOneWidget);
    });

    testWidgets('an unrecognised code is recorded, never dropped', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester);
      await scan(tester, notOnManifest);

      expect(
        find.textContaining('Unrecognised code', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Not on this manifest', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('empty input is ignored', (WidgetTester tester) async {
      await pumpScan(tester);
      await scan(tester, '   ');

      expect(find.text('13/14'), findsOneWidget);
      expect(
        find.textContaining('Unrecognised code', findRichText: true),
        findsNothing,
      );
    });
  });

  group('responsive', () {
    testWidgets('portrait has no overflow', (WidgetTester tester) async {
      await pumpScan(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape has no overflow', (WidgetTester tester) async {
      await pumpScan(tester, size: landscape);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard open collapses chrome and does not overflow', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester, keyboardInset: 250);

      // The ring gives way to the compact line, and the cold-chain banner goes.
      expect(find.byType(AppStatRing), findsNothing);
      expect(find.text('13/14 loaded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('font scale 1.3 has no overflow', (WidgetTester tester) async {
      await pumpScan(tester, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('landscape at font scale 1.3 has no overflow', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester, size: landscape, textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keyboard open in landscape has no overflow', (
      WidgetTester tester,
    ) async {
      await pumpScan(tester, size: landscape, keyboardInset: 180);
      expect(tester.takeException(), isNull);
    });
  });
}
