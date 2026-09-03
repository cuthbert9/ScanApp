/// Every navigable location in the app, in one place.
///
/// Paths are constants rather than string literals at call sites so a rename is
/// a single edit and a typo is a compile error rather than a blank screen.
abstract final class Routes {
  /// Sign-in, outside the tab shell — it has no bottom navigation.
  static const String login = '/login';

  /// The home tab: what is staged at this dock.
  static const String orders = '/orders';

  static const String scan = '/scan';
  static const String load = '/load';
  static const String sync = '/sync';
  static const String settings = '/settings';

  /// Where a signed-in operator lands.
  static const String initial = orders;
}
