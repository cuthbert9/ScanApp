import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/domain/session.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/loading/presentation/load_reconciliation_screen.dart';
import '../../features/loading/presentation/scan_screen.dart';
import '../../features/orders/presentation/loading_queue_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/sync/presentation/sync_screen.dart';
import 'routes.dart';

part 'app_router.g.dart';

/// The app's navigation graph.
///
/// `keepAlive` because the router owns navigation state for the whole session;
/// letting it be disposed and rebuilt would reset the operator's position.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // The router is built once, so it cannot `watch` auth. Instead it listens and
  // notifies go_router to re-run the redirect — this re-evaluates the guard
  // without tearing down and rebuilding the navigation stack.
  bool signedIn(AsyncValue<Session?> auth) => auth.value != null;

  final ValueNotifier<bool> authChanged = ValueNotifier<bool>(
    signedIn(ref.read(authControllerProvider)),
  );
  ref.listen<AsyncValue<Session?>>(
    authControllerProvider,
    (AsyncValue<Session?>? _, AsyncValue<Session?> next) =>
        authChanged.value = signedIn(next),
  );
  ref.onDispose(authChanged.dispose);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: authChanged,
    debugLogDiagnostics: kDebugMode,

    /// Single guard for the whole app: signed-out operators can only be at
    /// login, and signed-in ones are bounced off it.
    redirect: (BuildContext context, GoRouterState state) {
      final bool isSignedIn = signedIn(ref.read(authControllerProvider));
      final bool isAtLogin = state.matchedLocation == Routes.login;

      if (!isSignedIn) return isAtLogin ? null : Routes.login;
      if (isAtLogin) return Routes.initial;
      return null;
    },

    routes: <RouteBase>[
      GoRoute(
        path: Routes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),

      // Each branch keeps its own navigator, so a tab remembers where it was.
      // Branch order must match AppShell's tab order.
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) => AppShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.orders,
                builder: (BuildContext context, GoRouterState state) =>
                    const LoadingQueueScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.scan,
                builder: (BuildContext context, GoRouterState state) =>
                    const ScanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.load,
                builder: (BuildContext context, GoRouterState state) =>
                    const LoadReconciliationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.sync,
                builder: (BuildContext context, GoRouterState state) =>
                    const SyncScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: Routes.settings,
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
