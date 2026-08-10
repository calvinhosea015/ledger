import 'package:uuid/uuid.dart';

import '../../catalog/catalog_store.dart';
import '../../catalog/models.dart';

/// In-memory [CatalogStore] for tests and offline demo without Supabase.
class FakeCatalogStore implements CatalogStore {
  FakeCatalogStore({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final Map<String, Category> _categories = {};
  final Map<String, Purchase> _purchases = {};
  final Map<String, Profile> _profilesByUser = {};
  final Map<String, Envelope> _envelopes = {};

  @override
  Future<List<Category>> listCategories(String userId) async {
    return _categories.values.where((c) => c.userId == userId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Category> createCategory(String userId, NewCategory input) async {
    final category = Category(
      id: _uuid.v4(),
      userId: userId,
      name: input.name,
      color: input.color,
    );
    _categories[category.id] = category;
    return category;
  }

  @override
  Future<Category> updateCategory(Category category) async {
    _categories[category.id] = category;
    return category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _categories.remove(categoryId);
  }

  @override
  Future<List<Purchase>> listPurchases(String userId) async {
    return _purchases.values.where((p) => p.userId == userId).toList()
      ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
  }

  @override
  Future<Purchase> createPurchase(String userId, NewPurchase input) async {
    final purchase = Purchase(
      id: _uuid.v4(),
      userId: userId,
      name: input.name,
      categoryId: input.categoryId,
      price: input.price,
      currencyCode: input.currencyCode,
      purchasedAt: input.purchasedAt,
      expectedFinishAt: input.expectedFinishAt,
      expiresAt: input.expiresAt,
      notes: input.notes,
    );
    _purchases[purchase.id] = purchase;
    return purchase;
  }

  @override
  Future<Purchase> updatePurchase(Purchase purchase) async {
    _purchases[purchase.id] = purchase;
    return purchase;
  }

  @override
  Future<void> deletePurchase(String purchaseId) async {
    _purchases.remove(purchaseId);
  }

  @override
  Future<Profile?> getProfile(String userId) async => _profilesByUser[userId];

  @override
  Future<Profile> upsertProfile(
    String userId, {
    required String currencyCode,
  }) async {
    final existing = _profilesByUser[userId];
    final profile = Profile(
      id: existing?.id ?? _uuid.v4(),
      userId: userId,
      currencyCode: currencyCode,
    );
    _profilesByUser[userId] = profile;
    return profile;
  }

  @override
  Future<List<Envelope>> listEnvelopes(
    String userId,
    int year,
    int month,
  ) async {
    return _envelopes.values
        .where(
          (e) => e.userId == userId && e.year == year && e.month == month,
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<Envelope> createEnvelope(String userId, NewEnvelope input) async {
    final envelope = Envelope(
      id: _uuid.v4(),
      userId: userId,
      year: input.year,
      month: input.month,
      name: input.name,
      type: input.type,
      budgeted: input.budgeted,
      actual: input.actual,
      currencyCode: input.currencyCode,
      categoryId: input.categoryId,
    );
    _envelopes[envelope.id] = envelope;
    return envelope;
  }

  @override
  Future<Envelope> updateEnvelope(Envelope envelope) async {
    _envelopes[envelope.id] = envelope;
    return envelope;
  }

  @override
  Future<void> deleteEnvelope(String envelopeId) async {
    _envelopes.remove(envelopeId);
  }
}

class FakeAuthSession implements AuthSession {
  FakeAuthSession({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  final Map<String, _FakeAccount> _accounts = {};
  SessionUser? _current;

  @override
  Future<SessionUser?> currentUser() async => _current;

  @override
  Future<SessionUser> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    if (_accounts.values.any((a) => a.email == email)) {
      throw StateError('Email already registered');
    }
    final user = SessionUser(id: _uuid.v4(), email: email, name: name);
    _accounts[user.id] = _FakeAccount(
      user: user,
      password: password,
    );
    _current = user;
    return user;
  }

  @override
  Future<SessionUser> signIn({
    required String email,
    required String password,
  }) async {
    final match = _accounts.values.where(
      (a) => a.email == email && a.password == password,
    );
    if (match.isEmpty) {
      throw StateError('Invalid email or password');
    }
    _current = match.first.user;
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }
}

class _FakeAccount {
  _FakeAccount({required this.user, required this.password});

  final SessionUser user;
  final String password;

  String get email => user.email;
}
