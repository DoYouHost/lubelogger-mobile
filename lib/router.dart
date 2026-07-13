import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/garage/garage_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/setup/setup_screen.dart';
import 'providers.dart';

/// Root navigator key — lets us push routes from outside the widget tree.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// App router. Without a saved profile every route redirects to `/setup`; once
/// a profile is saved the app opens at `/`.
final routerProvider = Provider<GoRouter>((ref) {
  final hasProfile =
      ref.watch(serverProfileProvider.select((p) => p != null));
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: hasProfile ? '/' : '/setup',
    redirect: (context, state) {
      if (!hasProfile && state.matchedLocation != '/setup') {
        return '/setup';
      }
      if (hasProfile && state.matchedLocation == '/setup') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/', builder: (_, _) => const GarageScreen()),
      GoRoute(
        path: '/vehicle/:id',
        builder: (_, state) => DashboardScreen(
          vehicleId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    ],
  );
  // "Change server" (profile set→null→set) rebuilds a new GoRouter — dispose
  // the old one so its listeners don't leak.
  ref.onDispose(router.dispose);
  return router;
});
