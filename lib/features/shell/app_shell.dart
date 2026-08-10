import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    ('/home', 'Home', Icons.home_outlined, Icons.home),
    ('/budget', 'Budget', Icons.account_balance_wallet_outlined,
        Icons.account_balance_wallet),
    ('/categories', 'Categories', Icons.label_outline, Icons.label),
    ('/profile', 'Profile', Icons.person_outline, Icons.person),
  ];

  int _indexFor(String location) {
    if (location.startsWith('/budget')) return 1;
    if (location.startsWith('/categories')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFor(location);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: child,
      ),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: LedgerColors.canvas,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: LedgerColors.surface,
              selectedIndex: index,
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].$1),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.$3),
                    selectedIcon: Icon(d.$4),
                    label: Text(d.$2),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      body: content,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_destinations[i].$1),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.$3),
              selectedIcon: Icon(d.$4),
              label: d.$2,
            ),
        ],
      ),
    );
  }
}
