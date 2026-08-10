import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger/adapters/fake/fake_adapters.dart';
import 'package:ledger/app.dart';
import 'package:ledger/core/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ledger/core/env.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (Env.hasSupabase) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
    }
  });

  testWidgets('Ledger reaches auth when Supabase is configured', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LedgerApp()));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('local demo unlock reaches auth', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDemoUnlockedProvider.overrideWith((ref) => true),
          authSessionProvider.overrideWithValue(FakeAuthSession()),
          catalogStoreProvider.overrideWithValue(FakeCatalogStore()),
        ],
        child: const LedgerApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
  });
}
