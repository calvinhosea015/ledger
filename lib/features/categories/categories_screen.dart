import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

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
              body: 'Add a category to organize purchases.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final c = items[i];
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
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () async {
                  final controller = TextEditingController(text: c.name);
                  final name = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Rename category'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await ref
                                .read(categoriesProvider.notifier)
                                .remove(c.id);
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: LedgerColors.paleRedFg),
                          ),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, controller.text.trim()),
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  );
                  if (name != null && name.isNotEmpty && name != c.name) {
                    await ref
                        .read(categoriesProvider.notifier)
                        .rename(c, name);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
