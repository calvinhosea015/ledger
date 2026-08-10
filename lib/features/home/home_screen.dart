import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/purchase_lifecycle/purchase_lifecycle.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    final purchases = ref.watch(purchasesProvider);
    final categories = ref.watch(categoriesProvider);
    final lifecycle = ref.watch(inventoryCatalogProvider).lifecycle;
    final dateFmt = DateFormat.MMMd();

    final catNames = {
      for (final c in categories.valueOrNull ?? []) c.id: c.name as String,
    };

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => ref.read(authStateProvider.notifier).signOut(),
            icon: const Icon(Icons.logout, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/purchases/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                for (final f in HomeFilter.values) ...[
                  FilterChip(
                    label: Text(_filterLabel(f)),
                    selected: filter == f,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: filter == f ? Colors.white : LedgerColors.ink,
                    ),
                    selectedColor: LedgerColors.cta,
                    backgroundColor: LedgerColors.surface,
                    onSelected: (_) {
                      ref.read(homeFilterProvider.notifier).state = f;
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: purchases.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'No purchases yet',
                    body:
                        'Add something you bought to track when it finishes or expires.',
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final status = lifecycle.statusOf(p);
                    final subtitle = status == ItemStatus.finished
                        ? 'Finished ${dateFmt.format(p.finishedAt!)}'
                        : p.expectedFinishAt != null
                            ? 'Expected ${dateFmt.format(p.expectedFinishAt!)}'
                            : p.expiresAt != null
                                ? 'Expires ${dateFmt.format(p.expiresAt!)}'
                                : 'Purchased ${dateFmt.format(p.purchasedAt)}';
                    return PurchaseRow(
                      purchase: p,
                      categoryName: catNames[p.categoryId] ?? 'Category',
                      status: status,
                      priceLabel: formatMoney(p.price, p.currencyCode),
                      subtitle: subtitle,
                      onTap: () => context.push('/purchases/${p.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _filterLabel(HomeFilter f) => switch (f) {
        HomeFilter.all => 'All',
        HomeFilter.finishingSoon => 'Finishing soon',
        HomeFilter.expiringSoon => 'Expiring soon',
        HomeFilter.finished => 'Finished',
      };
}
