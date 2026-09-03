/// Barrel for the design system.
///
/// `import 'package:scanapp/core/design/design.dart';` gives you
/// `context.colors`, `context.spacing`, `context.type` and friends.
///
/// `tokens/primitive_tokens.dart` is deliberately NOT exported: primitives are
/// an implementation detail of the theme, not an app-wide API.
library;

export 'context_extensions.dart';
export 'extensions/app_colors.dart';
export 'extensions/app_motion.dart';
export 'extensions/app_radii.dart';
export 'extensions/app_sizes.dart';
export 'extensions/app_spacing.dart';
export 'extensions/app_typography.dart';
export 'theme/app_theme.dart';
