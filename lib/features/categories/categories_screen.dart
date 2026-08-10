import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/models.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/envelope_ledger/envelope_ledger.dart';
import '../widgets/common_widgets.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return LedgerColors.hairline;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return LedgerColors.hairline;
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(categoriesProvider.notifier).add(name);
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    required Category category,
    required Envelope? envelope,
    required String currency,
  }) async {
    final nameController = TextEditingController(text: category.name);
    final budgetController = TextEditingController(
      text: (envelope?.budgeted ?? 0).toString(),
    );

    final result = await showDialog<_CategoryEditResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Monthly budget ($currency)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const _CategoryEditResult(delete: true),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: LedgerColors.paleRedFg),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _CategoryEditResult(
                name: nameController.text.trim(),
                budgeted: double.tryParse(
                      budgetController.text.replaceAll(',', ''),
                    ) ??
                    0,
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result.delete) {
      await ref.read(categoriesProvider.notifier).remove(category.id);
      return;
    }

    final name = result.name ?? category.name;
    if (name.isNotEmpty && name != category.name) {
      await ref.read(categoriesProvider.notifier).rename(category, name);
    }

    final budgeted = result.budgeted ?? envelope?.budgeted ?? 0;
    if (envelope != null && budgeted != envelope.budgeted) {
      await ref.read(envelopeLedgerProvider).saveEnvelope(
            envelope.copyWith(budgeted: budgeted),
          );
      ref.invalidate(budgetMonthViewProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final budgetView = ref.watch(budgetMonthViewProvider);
    final currency = ref.watch(currencyCodeProvider);
    final mono = Theme.of(context).extension<LedgerTypeExt>()?.mono;

    final budgetByCategory = <String, EnvelopeLine>{};
    for (final line in budgetView.valueOrNull?.lines ?? const []) {
      final id = line.envelope.categoryId;
      if (id != null) budgetByCategory[id] = line;
    }

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          TextButton(
            onPressed: () => _add(context, ref),
            child: const Text('Add'),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No categories',
              body: 'Add a category to organize purchases and set its budget.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final c = items[i];
              final line = budgetByCategory[c.id];
              final budgeted = line?.envelope.budgeted ?? 0;
              final remaining = line?.difference;
              final remainingLabel = remaining == null
                  ? 'No budget this month'
                  : 'Remaining ${formatMoney(remaining, currency)}';
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseColor(c.color),
                    shape: BoxShape.circle,
                    border: Border.all(color: LedgerColors.hairline),
                  ),
                ),
                title: Text(c.name),
                subtitle: Text(
                  remainingLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: remaining != null && remaining < 0
                            ? LedgerColors.paleRedFg
                            : null,
                      ),
                ),
                trailing: Text(
                  formatMoney(budgeted, currency),
                  style: mono?.copyWith(fontSize: 13),
                ),
                onTap: () => _edit(
                  context,
                  ref,
                  category: c,
                  envelope: line?.envelope,
                  currency: currency,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryEditResult {
  const _CategoryEditResult({
    this.name,
    this.budgeted,
    this.delete = false,
  });

  final String? name;
  final double? budgeted;
  final bool delete;
}
