/// The operator's theme preference.
///
/// Pure Dart with no Flutter import, so it can live in the domain. The mapping
/// onto `ThemeMode` is made in the app layer, where Flutter is allowed.
enum ThemeChoice {
  /// Force the daylight palette — right under a bright dock roof even after
  /// sunset.
  day('Day'),

  /// Force the dim-aisle palette.
  night('Night'),

  /// Follow the device, which follows sunset and the ambient sensor.
  auto('Auto');

  const ThemeChoice(this.label);
  final String label;

  static ThemeChoice fromName(String? name) {
    for (final ThemeChoice c in ThemeChoice.values) {
      if (c.name == name) return c;
    }
    return ThemeChoice.auto;
  }
}

/// How large interface text should be.
///
/// `Gloved` is not an accessibility afterthought: it is what an operator picks
/// wearing cold-store gloves and safety glasses, and is expected to be the
/// common choice on the floor.
enum TextScaleChoice {
  standard('Standard', 1.0),
  gloved('Gloved', 1.15);

  const TextScaleChoice(this.label, this.scale);
  final String label;
  final double scale;

  static TextScaleChoice fromName(String? name) {
    for (final TextScaleChoice c in TextScaleChoice.values) {
      if (c.name == name) return c;
    }
    return TextScaleChoice.standard;
  }
}
