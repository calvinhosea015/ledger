import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';

class SetupRequiredScreen extends ConsumerWidget {
  const SetupRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mono = Theme.of(context).extension<LedgerTypeExt>()?.mono;

    return Scaffold(
      backgroundColor: LedgerColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    'Ledger',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connect Supabase or continue with a local demo.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: LedgerColors.muted,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Pass project defines when you run:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: LedgerColors.hairline),
                      color: LedgerColors.surface,
                    ),
                    child: Text(
                      '--dart-define=SUPABASE_URL=https://xxxx.supabase.co\n'
                      '--dart-define=SUPABASE_ANON_KEY=eyJ…',
                      style: mono?.copyWith(fontSize: 12, height: 1.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Run supabase/schema.sql in the SQL Editor, enable Email auth, '
                    'and prefer disabling Confirm email for local testing. '
                    'Never put the service_role key in the Flutter client.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      ref.read(localDemoUnlockedProvider.notifier).state = true;
                      context.go('/auth');
                    },
                    child: const Text('Continue with local demo'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo data resets when the app quits.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
