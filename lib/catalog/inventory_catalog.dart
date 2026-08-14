import '../catalog/catalog_store.dart';
import '../catalog/models.dart';
import '../domain/purchase_lifecycle/purchase_lifecycle.dart';

const defaultCategorySeeds = <NewCategory>[
  NewCategory(name: 'Groceries', color: '#EDF3EC'),
  NewCategory(name: 'Utilities', color: '#E8DEEE'),
  NewCategory(name: 'Household', color: '#E1F3FE'),
  NewCategory(name: 'Personal', color: '#FBF3DB'),
  NewCategory(name: 'Other', color: '#FDEBEC'),
];

/// Deep module over [CatalogStore]: list/filter/mutate + seed defaults.
class InventoryCatalog {
  InventoryCatalog({
    required this._store,
    this.lifecycle = const PurchaseLifecycle(),
  });

  final CatalogStore _store;
  final PurchaseLifecycle lifecycle;

  Future<List<Category>> categories(String userId) =>
      _store.listCategories(userId);

  Future<List<Category>> ensureSeedCategories(String userId) async {
    final existing = await _store.listCategories(userId);
    if (existing.isNotEmpty) return existing;
    final created = <Category>[];
    for (final seed in defaultCategorySeeds) {
      created.add(await _store.createCategory(userId, seed));
    }
    return created;
  }

  Future<Category> addCategory(String userId, NewCategory input) =>
      _store.createCategory(userId, input);

  Future<Category> renameCategory(Category category, String name) =>
      _store.updateCategory(category.copyWith(name: name));

  Future<void> removeCategory(String categoryId) =>
      _store.deleteCategory(categoryId);

  Future<List<Purchase>> purchases(String userId) =>
      _store.listPurchases(userId);

  Future<List<Purchase>> filteredPurchases(
    String userId,
    HomeFilter filter, {
    String? categoryId,
    DateTime? today,
  }) async {
    final all = await _store.listPurchases(userId);
    return all
        .where((p) => lifecycle.matchesFilter(p, filter, today: today))
        .where((p) => categoryId == null || p.categoryId == categoryId)
        .toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }

  Future<Purchase> addPurchase(String userId, NewPurchase input) {
    _validate(input.purchasedAt, input.expectedFinishAt, input.expiresAt);
    return _store.createPurchase(userId, input);
  }

  Future<Purchase> updatePurchase(Purchase purchase) {
    _validate(
      purchase.purchasedAt,
      purchase.expectedFinishAt,
      purchase.expiresAt,
    );
    return _store.updatePurchase(purchase);
  }

  Future<Purchase> markFinished(Purchase purchase, {DateTime? at}) {
    final next = lifecycle.markFinished(purchase, at: at);
    return _store.updatePurchase(next);
  }

  Future<void> removePurchase(String purchaseId) =>
      _store.deletePurchase(purchaseId);

  void _validate(
    DateTime purchasedAt,
    DateTime? expectedFinishAt,
    DateTime? expiresAt,
  ) {
    final buy = DateTime(
      purchasedAt.year,
      purchasedAt.month,
      purchasedAt.day,
    );
    if (expectedFinishAt != null) {
      final finish = DateTime(
        expectedFinishAt.year,
        expectedFinishAt.month,
        expectedFinishAt.day,
      );
      if (finish.isBefore(buy)) {
        throw ArgumentError(
          'Expected finish must be on or after purchase date',
        );
      }
    }
    if (expiresAt != null) {
      final exp = DateTime(expiresAt.year, expiresAt.month, expiresAt.day);
      if (exp.isBefore(buy)) {
        throw ArgumentError('Expiry must be on or after purchase date');
      }
    }
  }
}
