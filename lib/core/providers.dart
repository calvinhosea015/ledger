import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../adapters/fake/fake_adapters.dart';
import '../adapters/supabase/supabase_adapters.dart';
import '../catalog/catalog_store.dart';
import '../catalog/inventory_catalog.dart';
import '../catalog/models.dart';
import '../core/env.dart';
import '../core/money.dart';
import '../domain/envelope_ledger/envelope_ledger.dart';
import '../domain/purchase_lifecycle/purchase_lifecycle.dart';
import '../domain/spend_summary/spend_summary.dart';

/// Session unlock for local demo when no Supabase project is configured.
final localDemoUnlockedProvider = StateProvider<bool>(
  (ref) => Env.useFake || Env.hasSupabase,
);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (Env.shouldUseFake) return null;
  return Supabase.instance.client;
});

final authSessionProvider = Provider<AuthSession>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return FakeAuthSession();
  return SupabaseAuthSession(client);
});

final catalogStoreProvider = Provider<CatalogStore>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return FakeCatalogStore();
  return SupabaseCatalogStore(client);
});

final inventoryCatalogProvider = Provider<InventoryCatalog>((ref) {
  return InventoryCatalog(store: ref.watch(catalogStoreProvider));
});

final envelopeLedgerProvider = Provider<EnvelopeLedger>((ref) {
  return EnvelopeLedger(store: ref.watch(catalogStoreProvider));
});

final spendSummaryProvider = Provider<SpendSummary>((ref) {
  return const SpendSummary();
});

final authStateProvider =
    AsyncNotifierProvider<AuthController, SessionUser?>(AuthController.new);

class AuthController extends AsyncNotifier<SessionUser?> {
  @override
  Future<SessionUser?> build() {
    return ref.read(authSessionProvider).currentUser();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading<SessionUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(authSessionProvider).signIn(
            email: email.trim(),
            password: password,
          ),
    );
  }

  Future<void> signUp(String email, String password, {String? name}) async {
    state = const AsyncLoading<SessionUser?>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(authSessionProvider).signUp(
            email: email.trim(),
            password: password,
            name: name,
          ),
    );
  }

  Future<void> signOut() async {
    await ref.read(authSessionProvider).signOut();
    state = const AsyncData(null);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileController, Profile?>(ProfileController.new);

class ProfileController extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return null;
    return ref.read(envelopeLedgerProvider).ensureProfile(user.id);
  }

  Future<void> setCurrency(String code) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(envelopeLedgerProvider).setCurrency(user.id, code),
    );
  }
}

final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(profileProvider).valueOrNull?.currencyCode ??
      kDefaultCurrencyCode;
});

final categoriesProvider =
    AsyncNotifierProvider<CategoriesController, List<Category>>(
  CategoriesController.new,
);

class CategoriesController extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) return [];
    return ref.read(inventoryCatalogProvider).ensureSeedCategories(user.id);
  }

  Future<void> refresh() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryCatalogProvider).categories(user.id),
    );
  }

  Future<void> add(String name, {String? color}) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(inventoryCatalogProvider).addCategory(
          user.id,
          NewCategory(name: name, color: color),
        );
    await refresh();
    ref.invalidate(budgetMonthViewProvider);
  }

  Future<void> rename(Category category, String name) async {
    final renamed = await ref
        .read(inventoryCatalogProvider)
        .renameCategory(category, name);
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      final month = ref.read(budgetMonthProvider);
      await ref.read(envelopeLedgerProvider).renameCategoryBudgets(
            userId: user.id,
            category: renamed,
            year: month.year,
            month: month.month,
          );
    }
    await refresh();
    ref.invalidate(budgetMonthViewProvider);
  }

  Future<void> remove(String id) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      final month = ref.read(budgetMonthProvider);
      await ref.read(envelopeLedgerProvider).removeCategoryBudgets(
            userId: user.id,
            categoryId: id,
            year: month.year,
            month: month.month,
          );
    }
    await ref.read(inventoryCatalogProvider).removeCategory(id);
    await refresh();
    ref.invalidate(budgetMonthViewProvider);
  }
}

final homeFilterProvider = StateProvider<HomeFilter>((ref) => HomeFilter.all);

/// `null` means all categories.
final homeCategoryFilterProvider = StateProvider<String?>((ref) => null);

final purchasesProvider =
    AsyncNotifierProvider<PurchasesController, List<Purchase>>(
  PurchasesController.new,
);

class PurchasesController extends AsyncNotifier<List<Purchase>> {
  @override
  Future<List<Purchase>> build() async {
    final user = ref.watch(authStateProvider).valueOrNull;
    final filter = ref.watch(homeFilterProvider);
    final categoryId = ref.watch(homeCategoryFilterProvider);
    if (user == null) return [];
    return ref.read(inventoryCatalogProvider).filteredPurchases(
          user.id,
          filter,
          categoryId: categoryId,
        );
  }

  Future<void> refresh() async {
    final user = ref.read(authStateProvider).valueOrNull;
    final filter = ref.read(homeFilterProvider);
    final categoryId = ref.read(homeCategoryFilterProvider);
    if (user == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(inventoryCatalogProvider).filteredPurchases(
            user.id,
            filter,
            categoryId: categoryId,
          ),
    );
  }

  Future<void> add(NewPurchase input) async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    await ref.read(inventoryCatalogProvider).addPurchase(user.id, input);
    await refresh();
    ref.invalidate(budgetMonthViewProvider);
  }

  Future<void> save(Purchase purchase) async {
    await ref.read(inventoryCatalogProvider).updatePurchase(purchase);
    await refresh();
    ref.invalidate(budgetMonthViewProvider);
  }

  Future<void> markFinished(Purchase purchase) async {
    await ref.read(inventoryCatalogProvider).markFinished(purchase);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(inventoryCatalogProvider).removePurchase(id);
    await refresh();
    ref.invalidate(budgetMonthViewProvider);
  }
}

final budgetMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final budgetMonthViewProvider = FutureProvider<MonthEnvelopeView>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  final month = ref.watch(budgetMonthProvider);
  final currency = ref.watch(currencyCodeProvider);
  if (user == null) {
    return MonthEnvelopeView(
      year: month.year,
      month: month.month,
      lines: const [],
      incomeActual: 0,
      expenseActual: 0,
      expenseBudgeted: 0,
      net: 0,
      remaining: 0,
    );
  }
  final catalog = ref.read(inventoryCatalogProvider);
  final purchases = await catalog.purchases(user.id);
  final categories = await catalog.ensureSeedCategories(user.id);
  return ref.read(envelopeLedgerProvider).resolveMonth(
        userId: user.id,
        year: month.year,
        month: month.month,
        purchases: purchases,
        categories: categories,
        currencyCode: currency,
      );
});
