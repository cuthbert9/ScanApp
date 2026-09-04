/// Barrel for the shared widget library.
///
/// Everything here is used by two or more features and carries no
/// feature-specific logic. A widget used by exactly one feature belongs in that
/// feature's `presentation/widgets/` folder instead (CLAUDE.md rule 2).
library;

export 'display/app_badge.dart';
export 'display/app_detail_row.dart';
export 'display/app_meta_row.dart';
export 'display/app_section_heading.dart';
export 'display/app_stat_ring.dart';
export 'display/app_stat_tile.dart';
export 'display/app_summary_compact_line.dart';
export 'feedback/app_info_panel.dart';
export 'feedback/placeholder_screen.dart';
export 'layout/app_bottom_action_bar.dart';
export 'layout/app_pinned_summary.dart';
export 'layout/app_screen_header.dart';
export 'layout/app_summary_strip.dart';
