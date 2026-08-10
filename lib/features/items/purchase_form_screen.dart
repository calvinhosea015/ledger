import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../catalog/category_date_rules.dart';
import '../../catalog/models.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key, this.purchaseId});

  final String? purchaseId;

  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController(text: '0');
  final _notes = TextEditingController();

  String? _categoryId;
  late DateTime _purchasedAt;
  DateTime? _expectedFinishAt;
  DateTime? _expiresAt;
  Purchase? _existing;
  bool _loading = true;
  String? _error;

  bool get isEdit => widget.purchaseId != null;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _purchasedAt = DateTime(today.year, today.month, today.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Category? _selectedCategory(List<Category> categories) {
    if (_categoryId == null) return null;
    for (final c in categories) {
      if (c.id == _categoryId) return c;
    }
    return null;
  }

  void _applyCategoryDateDefaults(Category? category) {
    if (category == null) {
      _expectedFinishAt = null;
      _expiresAt = null;
      return;
    }
    if (!CategoryDateRules.showsExpectedDate(category.name)) {
      _expectedFinishAt = null;
    } else {
      _expectedFinishAt ??= _purchasedAt.add(const Duration(days: 7));
    }
    if (!CategoryDateRules.showsExpiryDate(category.name)) {
      _expiresAt = null;
    }
  }

  Future<void> _bootstrap() async {
    final cats = await ref.read(categoriesProvider.future);
    if (cats.isNotEmpty) {
      _categoryId ??= cats.first.id;
    }

    if (isEdit) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null) {
        final all =
            await ref.read(inventoryCatalogProvider).purchases(user.id);
        final match = all.where((p) => p.id == widget.purchaseId);
        if (match.isNotEmpty) {
          final p = match.first;
          _existing = p;
          _name.text = p.name;
          _price.text = p.price.toStringAsFixed(
            p.price.truncateToDouble() == p.price ? 0 : 2,
          );
          _notes.text = p.notes ?? '';
          _categoryId = p.categoryId;
          _purchasedAt = p.purchasedAt;
          _expectedFinishAt = p.expectedFinishAt;
          _expiresAt = p.expiresAt;
        }
      }
    }

    _applyCategoryDateDefaults(_selectedCategory(cats));

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      setState(() => _error = 'Pick a category');
      return;
    }

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = _selectedCategory(categories);
    if (category == null) {
      setState(() => _error = 'Pick a category');
      return;
    }

    final needsExpected = CategoryDateRules.showsExpectedDate(category.name);
    final needsExpiry = CategoryDateRules.showsExpiryDate(category.name);
    final expected = needsExpected ? _expectedFinishAt : null;
    final expires = needsExpiry ? _expiresAt : null;

    if (needsExpected && expected == null) {
      setState(() => _error = 'Expected date is required for ${category.name}');
      return;
    }

    setState(() => _error = null);

    final price = double.tryParse(_price.text.replaceAll(',', '')) ?? 0;
    try {
      if (isEdit && _existing != null) {
        final updated = _existing!.copyWith(
          name: _name.text.trim(),
          categoryId: _categoryId!,
          price: price,
          purchasedAt: _purchasedAt,
          expectedFinishAt: expected,
          expiresAt: expires,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          clearExpectedFinishAt: expected == null,
          clearExpiresAt: expires == null,
          clearNotes: _notes.text.trim().isEmpty,
        );
        await ref.read(purchasesProvider.notifier).save(updated);
      } else {
        final currency = ref.read(currencyCodeProvider);
        await ref.read(purchasesProvider.notifier).add(
              NewPurchase(
                name: _name.text.trim(),
                categoryId: _categoryId!,
                price: price,
                currencyCode: currency,
                purchasedAt: _purchasedAt,
                expectedFinishAt: expected,
                expiresAt: expires,
                notes:
                    _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              ),
            );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _markFinished() async {
    if (_existing == null) return;
    await ref.read(purchasesProvider.notifier).markFinished(_existing!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final dateFmt = DateFormat.yMMMd();
    final activeEdit = isEdit && _existing != null && !_existing!.isFinished;
    final category = _selectedCategory(categories);
    final showExpected =
        category != null && CategoryDateRules.showsExpectedDate(category.name);
    final showExpiry =
        category != null && CategoryDateRules.showsExpiryDate(category.name);

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit purchase' : 'Add purchase'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Delete',
              onPressed: _existing == null
                  ? null
                  : () async {
                      await ref
                          .read(purchasesProvider.notifier)
                          .remove(_existing!.id);
                      if (context.mounted) context.pop();
                    },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _categoryId = v;
                          _applyCategoryDateDefaults(
                            _selectedCategory(categories),
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.,]'),
                        ),
                      ],
                      decoration: const InputDecoration(labelText: 'Price'),
                      validator: (v) {
                        if (v == null ||
                            double.tryParse(v.replaceAll(',', '')) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _DateField(
                      label: 'Purchased date',
                      value: dateFmt.format(_purchasedAt),
                      onTap: () => _pickDate(
                        initial: _purchasedAt,
                        onPicked: (d) => setState(() => _purchasedAt = d),
                      ),
                    ),
                    if (showExpected) ...[
                      const SizedBox(height: 16),
                      _DateField(
                        label: 'Expected date',
                        value: _expectedFinishAt == null
                            ? 'Not set'
                            : dateFmt.format(_expectedFinishAt!),
                        onTap: () => _pickDate(
                          initial: _expectedFinishAt ??
                              _purchasedAt.add(const Duration(days: 7)),
                          firstDate: _purchasedAt,
                          onPicked: (d) =>
                              setState(() => _expectedFinishAt = d),
                        ),
                      ),
                    ],
                    if (showExpiry) ...[
                      const SizedBox(height: 16),
                      _DateField(
                        label: 'Expiry (optional)',
                        value: _expiresAt == null
                            ? 'Not set'
                            : dateFmt.format(_expiresAt!),
                        onTap: () async {
                          await _pickDate(
                            initial: _expiresAt ??
                                _expectedFinishAt ??
                                _purchasedAt,
                            firstDate: _purchasedAt,
                            onPicked: (d) => setState(() => _expiresAt = d),
                          );
                        },
                        trailing: _expiresAt == null
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _expiresAt = null),
                              ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: LedgerColors.paleRedFg),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                    if (activeEdit) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _markFinished,
                        child: const Text('Mark finished'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: trailing,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(value),
        ),
      ),
    );
  }
}
