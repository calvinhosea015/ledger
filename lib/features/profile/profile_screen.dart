import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _custom = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _apply(String raw) async {
    setState(() => _error = null);
    try {
      final code = normalizeCurrencyCode(raw);
      await ref.read(profileProvider.notifier).setCurrency(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Currency set to $code')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final current = ref.watch(currencyCodeProvider);

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (_) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Preferred currency for new purchases and envelopes. '
                'Existing amounts keep their snapshot code.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text('Currency', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final code in kCommonCurrencyCodes)
                    ChoiceChip(
                      label: Text(code),
                      selected: current == code,
                      showCheckmark: false,
                      selectedColor: LedgerColors.cta,
                      labelStyle: TextStyle(
                        color: current == code ? Colors.white : LedgerColors.ink,
                      ),
                      onSelected: (_) => _apply(code),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _custom,
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Other ISO code',
                  hintText: 'e.g. MYR',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _apply(_custom.text),
                child: const Text('Use custom code'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: LedgerColors.paleRedFg),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Preview: ${formatMoney(125000, current)}',
                style: Theme.of(context).extension<LedgerTypeExt>()?.mono,
              ),
            ],
          );
        },
      ),
    );
  }
}
