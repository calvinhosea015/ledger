import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_screen.dart';
import '../features/budget/budget_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/home/home_screen.dart';
import '../features/items/purchase_form_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/setup/setup_required_screen.dart';
import '../features/shell/app_shell.dart';
import 'env.dart';
import 'providers.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Do not watch auth here — that recreates GoRouter on every auth change and
  // resets navigation (looks like an instant logout after sign-in).
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final demoUnlocked = ref.read(localDemoUnlockedProvider);
      final loc = state.matchedLocation;
      final onSetup = loc == '/setup';
      final needsSetup =
          !Env.hasSupabase && !Env.useFake && !demoUnlocked;

      if (needsSetup && !onSetup) return '/setup';
      if (!needsSetup && onSetup) return '/auth';

      final loggingIn = loc == '/auth';
      // Prefer valueOrNull so a loading refresh does not look logged-out.
      final user = auth.valueOrNull;
      final resolvingSession = auth.isLoading && !auth.hasValue;

      if (needsSetup) return null;
      if (resolvingSession) return null;
      if (user == null && !loggingIn) return '/auth';
      if (user != null && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupRequiredScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/budget',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BudgetScreen(),
            ),
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoriesScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/purchases/new',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const PurchaseFormScreen(),
      ),
      GoRoute(
        path: '/purchases/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PurchaseFormScreen(purchaseId: id);
        },
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(localDemoUnlockedProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;
}
