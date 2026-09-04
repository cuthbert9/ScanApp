/// GS1 barcode parsing.
///
/// Pure Dart with no dependencies, so it is unit-testable without a widget
/// binding — which matters, because this is the most bug-prone code here.
library;

/// One displayable piece of a decoded barcode.
///
/// [ai] is the GS1 Application Identifier when the value came from one, so the
/// UI can emphasise `(10)` in `(10)ZNC26B118`. Derived text — a formatted
/// expiry, a hold reason — has no AI.
class Gs1Segment {
  const Gs1Segment({required this.text, this.ai});

  final String text;
  final String? ai;

  @override
  bool operator ==(Object other) =>
      other is Gs1Segment && other.text == text && other.ai == ai;

  @override
  int get hashCode => Object.hash(text, ai);

  @override
  String toString() => ai == null ? text : '($ai)$text';
}

/// A decoded GS1 barcode: Application Identifier to value.
///
/// Two input forms are handled:
///
/// * **Bracketed** — `(00)360098000000440(10)MRD24L221(17)270930`. Human
///   readable, unambiguous, and what a printed pallet label shows.
/// * **Concatenated** — raw scanner output. Fixed-length AIs are read by
///   length; variable-length ones run to an FNC1 separator (ASCII GS, 0x1D) or
///   the end of the string.
///
/// Concatenated input *without* FNC1 separators is genuinely ambiguous after a
/// variable-length AI, and no parser can resolve it. Rather than guess, this
/// one takes the trailing run as the value and stops. Bracketed input is the
/// reliable form for manual entry.
class Gs1Barcode {
  const Gs1Barcode._(this.elements, this.raw);

  /// Application Identifier to value, in the order encountered.
  final Map<String, String> elements;

  /// Exactly what was scanned or typed, kept for diagnostics.
  final String raw;

  /// AIs whose value has a fixed length, so no separator is needed.
  static const Map<String, int> _fixedLengths = <String, int>{
    '00': 18, // SSCC
    '01': 14, // GTIN
    '11': 6, // production date
    '13': 6, // packaging date
    '15': 6, // best before
    '17': 6, // expiry, YYMMDD
    '20': 2, // variant
  };

  /// Variable-length AIs this parser recognises. An unrecognised AI aborts the
  /// parse rather than producing plausible-looking nonsense.
  static const Set<String> _variableAis = <String>{
    '10', // batch / lot
    '21', // serial
    '30', // variable count
    '37', // count of trade items
    '91', '92', // internal use
  };

  /// FNC1 group separator, ASCII GS (0x1D).
  ///
  /// Built from its code point rather than written as a literal: it is an
  /// invisible control character, and an invisible character in source is a
  /// character that gets lost in a copy-paste or a diff.
  static final String _fnc1 = String.fromCharCode(0x1d);

  static final RegExp _bracketed = RegExp(r'\((\d{2,4})\)([^(]*)');
  static final RegExp _digitsOnly = RegExp(r'^\d+$');

  String? get sscc => elements['00'];
  String? get gtin => elements['01'];
  String? get batch => elements['10'];
  String? get serial => elements['21'];

  /// Nothing recognisable was decoded.
  bool get isEmpty => elements.isEmpty;

  /// The best available identifier for a catalogue lookup.
  String? get primaryKey => gtin ?? sscc;

  /// Expiry as a date, or null when absent or malformed.
  ///
  /// GS1 encodes `YYMMDD`; a day of `00` means "end of month", represented here
  /// as the last day of that month.
  DateTime? get expiry => _parseDate(elements['17'] ?? elements['15']);

  /// A stable identity for duplicate detection.
  ///
  /// A serial or SSCC identifies a specific physical unit; product-plus-batch
  /// identifies a pack. Falls back to the raw string when nothing better
  /// decoded, so two identical unreadable scans still count as duplicates.
  ///
  /// Defined here rather than on the record so the controller can judge an
  /// incoming scan before building one, without restating the rule.
  String get identity {
    final String? unique = serial ?? sscc;
    if (unique != null) return unique;
    final String? key = primaryKey;
    if (key != null) return '$key/${batch ?? ''}';
    return raw;
  }

  /// `2027-09`, the form printed on a label. Null when there is no expiry.
  String? get expiryLabel {
    final DateTime? date = expiry;
    if (date == null) return null;
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(String? yymmdd) {
    if (yymmdd == null || yymmdd.length != 6) return null;
    final int? yy = int.tryParse(yymmdd.substring(0, 2));
    final int? mm = int.tryParse(yymmdd.substring(2, 4));
    final int? dd = int.tryParse(yymmdd.substring(4, 6));
    if (yy == null || mm == null || dd == null) return null;
    if (mm < 1 || mm > 12) return null;

    // GS1 rule: 00-49 is 20xx, 50-99 is 19xx.
    final int year = yy <= 49 ? 2000 + yy : 1900 + yy;
    // Day 00 means end of month; DateTime(y, m + 1, 0) is its last day.
    if (dd == 0) return DateTime(year, mm + 1, 0);
    if (dd > 31) return null;
    return DateTime(year, mm, dd);
  }

  /// Decodes [raw]. Never throws: unrecognised input yields an empty barcode,
  /// so a scan is always recorded rather than silently dropped.
  static Gs1Barcode parse(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return const Gs1Barcode._(<String, String>{}, '');

    if (trimmed.contains('(')) {
      return Gs1Barcode._(_parseBracketed(trimmed), raw);
    }

    // A bare numeric code with no AI is an ordinary EAN/UPC/GTIN — the common
    // case when scanning a retail item rather than a pallet label.
    if (_digitsOnly.hasMatch(trimmed) &&
        const <int>[8, 12, 13, 14].contains(trimmed.length)) {
      return Gs1Barcode._(<String, String>{
        '01': trimmed.padLeft(14, '0'),
      }, raw);
    }

    return Gs1Barcode._(_parseConcatenated(trimmed), raw);
  }

  static Map<String, String> _parseBracketed(String input) {
    final Map<String, String> result = <String, String>{};
    for (final RegExpMatch match in _bracketed.allMatches(input)) {
      final String ai = match.group(1)!;
      final String value = match.group(2)!.trim();
      if (value.isNotEmpty) result[ai] = value;
    }
    return result;
  }

  static Map<String, String> _parseConcatenated(String input) {
    final Map<String, String> result = <String, String>{};
    int index = 0;

    while (index + 2 <= input.length) {
      final String ai = input.substring(index, index + 2);
      final int? fixed = _fixedLengths[ai];

      if (fixed == null && !_variableAis.contains(ai)) {
        // Not an AI we know. Guessing past this point would invent data, so
        // return whatever was decoded before it.
        break;
      }
      index += 2;

      if (fixed != null) {
        // Take what remains if the value is truncated, rather than dropping it.
        final int end = (index + fixed) > input.length
            ? input.length
            : index + fixed;
        result[ai] = input.substring(index, end);
        index = end;
        continue;
      }

      final int separator = input.indexOf(_fnc1, index);
      final int end = separator == -1 ? input.length : separator;
      result[ai] = input.substring(index, end);
      index = separator == -1 ? input.length : separator + 1;
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Gs1Barcode) return false;
    if (other.raw != raw || other.elements.length != elements.length) {
      return false;
    }
    for (final MapEntry<String, String> entry in elements.entries) {
      if (other.elements[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    raw,
    Object.hashAllUnordered(
      elements.entries.map(
        (MapEntry<String, String> e) => '${e.key}=${e.value}',
      ),
    ),
  );

  @override
  String toString() => 'Gs1Barcode($elements)';
}
