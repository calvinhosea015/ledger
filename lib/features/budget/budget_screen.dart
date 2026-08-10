import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../catalog/models.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../domain/envelope_ledger/envelope_ledger.dart';
import '../../domain/export/monthly_excel_export.dart';
import '../export/monthly_excel_exporter.dart';
import '../widgets/common_widgets.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(budgetMonthProvider);
    final view = ref.watch(budgetMonthViewProvider);
    final currency = ref.watch(currencyCodeProvider);
    final monthLabel = DateFormat.yMMMM().format(month);
    final mono = Theme.of(context).extension<LedgerTypeExt>()?.mono;
    final range = MonthRange(month.year, month.month);

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          IconButton(
            tooltip: 'Export Excel ($monthLabel)',
            onPressed: () => _exportMonth(context, ref, month),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEnvelopeSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(budgetMonthProvider.notifier).state = DateTime(
                      month.year,
                      month.month - 1,
                    );
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${DateFormat.MMMd().format(range.start)}'
                        ' – ${DateFormat.MMMd().format(range.end)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(budgetMonthProvider.notifier).state = DateTime(
                      month.year,
                      month.month + 1,
                    );
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: view.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (data) {
                if (data.lines.isEmpty) {
                  return const EmptyState(
                    title: 'No envelopes',
                    body:
                        'Add an envelope or reopen this month to seed defaults.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 88),
                  children: [
                    _SummaryBlock(
                      currency: currency,
                      data: data,
                      mono: mono,
                    ),
                    const SizedBox(height: 28),
                    for (final type in EnvelopeType.values) ...[
                      if (data.ofType(type).isNotEmpty) ...[
                        Text(
                          _typeLabel(type),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        for (final line in data.ofType(type))
                          _EnvelopeRow(
                            line: line,
                            currency: currency,
                            mono: mono,
                            onTap: () => _openEnvelopeSheet(
                              context,
                              ref,
                              existing: line.envelope,
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportMonth(
    BuildContext context,
    WidgetRef ref,
    DateTime month,
  ) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Preparing Excel export…')),
    );

    try {
      final catalog = ref.read(inventoryCatalogProvider);
      final purchases = await catalog.purchases(user.id);
      final categories = await catalog.categories(user.id);
      final budget = await ref.read(budgetMonthViewProvider.future);

      final path = await MonthlyExcelExporter().exportMonth(
        year: month.year,
        month: month.month,
        purchases: purchases,
        categories: categories,
        budget: budget,
      );

      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      if (path == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Export cancelled')),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  static String _typeLabel(EnvelopeType type) {
    switch (type) {
      case EnvelopeType.income:
        return 'Income';
      case EnvelopeType.fixed:
        return 'Fixed';
      case EnvelopeType.variable:
        return 'Variable';
      case EnvelopeType.savings:
        return 'Savings';
    }
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.currency,
    required this.data,
    required this.mono,
  });

  final String currency;
  final MonthEnvelopeView data;
  final TextStyle? mono;

  @override
  Widget build(BuildContext context) {
    final remaining = data.remaining;
    final over = remaining < 0;
    final remainingColor =
        over ? LedgerColors.paleRedFg : LedgerColors.paleGreenFg;

    Widget cell(String label, double amount) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              formatMoney(amount, currency),
              style: mono?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Remaining budget',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text(
          formatMoney(remaining, currency),
          style: mono?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: remainingColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          over
              ? 'Over by ${formatMoney(-remaining, currency)} '
                  '(budgeted ${formatMoney(data.expenseBudgeted, currency)})'
              : 'of ${formatMoney(data.expenseBudgeted, currency)} budgeted · '
                  'spent ${formatMoney(data.expenseActual, currency)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            cell('Income', data.incomeActual),
            cell('Expense', data.expenseActual),
            cell('Net', data.net),
          ],
        ),
      ],
    );
  }
}

class _EnvelopeRow extends StatelessWidget {
  const _EnvelopeRow({
    required this.line,
    required this.currency,
    required this.mono,
    required this.onTap,
  });

  final EnvelopeLine line;
  final String currency;
  final TextStyle? mono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isExpense = line.envelope.type.isExpense;
    final remaining = line.difference;
    final over = remaining < 0;
    final badgeBg =
        over ? LedgerColors.paleRedBg : LedgerColors.paleGreenBg;
    final badgeFg =
        over ? LedgerColors.paleRedFg : LedgerColors.paleGreenFg;
    final badgeLabel = isExpense ? 'Remaining' : 'Vs budget';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.envelope.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: badgeBg,
                  child: Text(
                    '$badgeLabel ${formatMoney(remaining, currency)}',
                    style: mono?.copyWith(fontSize: 12, color: badgeFg),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Budgeted ${formatMoney(line.envelope.budgeted, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  'Actual ${formatMoney(line.resolvedActual, currency)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
          ],
        ),
      ),
    );
  }
}

Future<void> _openEnvelopeSheet(
  BuildContext context,
  WidgetRef ref, {
  Envelope? existing,
}) async {
  final month = ref.read(budgetMonthProvider);
  final currency = ref.read(currencyCodeProvider);
  final categories = ref.read(categoriesProvider).valueOrNull ?? [];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LedgerColors.surface,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: _EnvelopeForm(
          existing: existing,
          year: month.year,
          month: month.month,
          currencyCode: currency,
          categories: categories,
          onSaved: () => ref.invalidate(budgetMonthViewProvider),
        ),
      );
    },
  );
}

class _EnvelopeForm extends ConsumerStatefulWidget {
  const _EnvelopeForm({
    required this.year,
    required this.month,
    required this.currencyCode,
    required this.categories,
    required this.onSaved,
    this.existing,
  });

  final Envelope? existing;
  final int year;
  final int month;
  final String currencyCode;
  final List<Category> categories;
  final VoidCallback onSaved;

  @override
  ConsumerState<_EnvelopeForm> createState() => _EnvelopeFormState();
}

class _EnvelopeFormState extends ConsumerState<_EnvelopeForm> {
  final _name = TextEditingController();
  final _budgeted = TextEditingController(text: '0');
  final _actual = TextEditingController(text: '0');
  late EnvelopeType _type;
  String? _categoryId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? EnvelopeType.variable;
    _name.text = e?.name ?? '';
    _budgeted.text = (e?.budgeted ?? 0).toString();
    _actual.text = (e?.actual ?? 0).toString();
    _categoryId = e?.categoryId ??
        (widget.categories.isEmpty ? null : widget.categories.first.id);
  }

  @override
  void dispose() {
    _name.dispose();
    _budgeted.dispose();
    _actual.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name required');
      return;
    }
    final budgeted =
        double.tryParse(_budgeted.text.replaceAll(',', '')) ?? 0;
    final actual = double.tryParse(_actual.text.replaceAll(',', '')) ?? 0;
    final ledger = ref.read(envelopeLedgerProvider);

    try {
      if (widget.existing != null) {
        await ledger.saveEnvelope(
          widget.existing!.copyWith(
            name: name,
            type: _type,
            budgeted: budgeted,
            actual: _type.usesPurchaseActual ? widget.existing!.actual : actual,
            categoryId: _type.usesPurchaseActual ? _categoryId : null,
            clearCategoryId: !_type.usesPurchaseActual,
            currencyCode: widget.currencyCode,
          ),
        );
      } else {
        await ledger.addEnvelope(
          user.id,
          NewEnvelope(
            year: widget.year,
            month: widget.month,
            name: name,
            type: _type,
            budgeted: budgeted,
            actual: _type.usesPurchaseActual ? 0 : actual,
            currencyCode: widget.currencyCode,
            categoryId: _type.usesPurchaseActual ? _categoryId : null,
          ),
        );
      }
      widget.onSaved();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    await ref.read(envelopeLedgerProvider).removeEnvelope(e.id);
    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final editActual = !_type.usesPurchaseActual;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.existing == null ? 'Add envelope' : 'Edit envelope',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<EnvelopeType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final t in EnvelopeType.values)
                    DropdownMenuItem(value: t, child: Text(t.name)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _type = v);
                },
              ),
              if (_type.usesPurchaseActual) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category (for actual spend)',
                  ),
                  items: [
                    for (final c in widget.categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _budgeted,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(labelText: 'Budgeted'),
              ),
              if (editActual) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _actual,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(labelText: 'Actual'),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  'Actual is summed from purchases in the linked category.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: LedgerColors.paleRedFg),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(onPressed: _save, child: const Text('Save')),
              if (widget.existing != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _delete,
                  child: const Text('Delete'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
