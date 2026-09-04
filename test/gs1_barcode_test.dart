import 'package:flutter_test/flutter_test.dart';
import 'package:scanapp/domain/models/gs1_barcode.dart';

/// The parser is the most bug-prone code in the scan feature and is pure Dart,
/// so it gets tested directly rather than through a widget.
void main() {
  final String fnc1 = String.fromCharCode(0x1d);

  group('bracketed form', () {
    test('decodes SSCC, batch and expiry', () {
      final Gs1Barcode code = Gs1Barcode.parse(
        '(00)3600980000004404(10)MRD24L221(17)270930',
      );

      expect(code.sscc, '3600980000004404');
      expect(code.batch, 'MRD24L221');
      expect(code.expiryLabel, '2027-09');
    });

    test('decodes a GTIN', () {
      final Gs1Barcode code = Gs1Barcode.parse(
        '(01)03600980000441(10)AMX25C441',
      );
      expect(code.gtin, '03600980000441');
      expect(code.batch, 'AMX25C441');
      expect(code.primaryKey, '03600980000441');
    });

    test('tolerates whitespace around values', () {
      final Gs1Barcode code = Gs1Barcode.parse('(10) LOT123 ');
      expect(code.batch, 'LOT123');
    });
  });

  group('concatenated form', () {
    test('reads fixed-length AIs by length', () {
      // (01) is 14 digits, (17) is 6.
      final Gs1Barcode code = Gs1Barcode.parse('010360098000044117270630');
      expect(code.gtin, '03600980000441');
      expect(code.expiryLabel, '2027-06');
    });

    test('ends a variable-length AI at an FNC1 separator', () {
      final Gs1Barcode code = Gs1Barcode.parse('10AMX25C441${fnc1}17270630');
      expect(code.batch, 'AMX25C441');
      expect(code.expiryLabel, '2027-06');
    });

    test('stops at an unrecognised AI instead of inventing data', () {
      // 99 is not an AI we model; everything before it still decodes.
      final Gs1Barcode code = Gs1Barcode.parse('010360098000044199ZZZZ');
      expect(code.gtin, '03600980000441');
      expect(code.elements.containsKey('99'), isFalse);
    });
  });

  group('bare numeric codes', () {
    test('treats a 13-digit EAN as a GTIN, zero-padded to 14', () {
      final Gs1Barcode code = Gs1Barcode.parse('3600980000441');
      expect(code.gtin, '03600980000441');
    });

    test('does not treat an odd-length number as a GTIN', () {
      final Gs1Barcode code = Gs1Barcode.parse('12345');
      expect(code.gtin, isNull);
    });
  });

  group('expiry', () {
    test('maps a two-digit year by the GS1 50-year rule', () {
      expect(Gs1Barcode.parse('(17)270930').expiry?.year, 2027);
      expect(Gs1Barcode.parse('(17)990930').expiry?.year, 1999);
    });

    test('day 00 means the last day of that month', () {
      final DateTime? date = Gs1Barcode.parse('(17)270200').expiry;
      expect(date, DateTime(2027, 2, 28));
    });

    test('rejects an impossible month', () {
      expect(Gs1Barcode.parse('(17)271330').expiry, isNull);
    });

    test('rejects a wrong-length value', () {
      expect(Gs1Barcode.parse('(17)2709').expiry, isNull);
    });
  });

  group('robustness', () {
    test('empty input decodes to an empty barcode rather than throwing', () {
      final Gs1Barcode code = Gs1Barcode.parse('');
      expect(code.isEmpty, isTrue);
      expect(code.primaryKey, isNull);
    });

    test('unstructured text does not throw', () {
      final Gs1Barcode code = Gs1Barcode.parse('not a barcode at all');
      expect(code.isEmpty, isTrue);
      expect(code.raw, 'not a barcode at all');
    });

    test('a truncated fixed-length value keeps what is there', () {
      final Gs1Barcode code = Gs1Barcode.parse('0036009800');
      expect(code.sscc, '36009800');
    });
  });

  group('identity', () {
    test('prefers a unique unit identifier over the product', () {
      final Gs1Barcode code = Gs1Barcode.parse(
        '(00)3600980000004404(10)MRD24L221',
      );
      expect(code.identity, '3600980000004404');
    });

    test('falls back to product plus batch', () {
      final Gs1Barcode code = Gs1Barcode.parse(
        '(01)03600980000441(10)AMX25C441',
      );
      expect(code.identity, '03600980000441/AMX25C441');
    });

    test('two identical undecodable scans share an identity', () {
      expect(
        Gs1Barcode.parse('mystery').identity,
        Gs1Barcode.parse('mystery').identity,
      );
    });
  });
}
