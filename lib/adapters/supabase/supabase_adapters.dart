import 'package:supabase_flutter/supabase_flutter.dart';

import '../../catalog/catalog_store.dart';
import '../../catalog/models.dart';
import '../../core/env.dart';
import '../../core/money.dart';

class SupabaseAuthSession implements AuthSession {
  SupabaseAuthSession(this._client);

  final SupabaseClient _client;

  SessionUser _fromUser(User user) {
    final meta = user.userMetadata;
    final name = meta?['name'] as String? ?? meta?['full_name'] as String?;
    return SessionUser(
      id: user.id,
      email: user.email ?? '',
      name: (name == null || name.isEmpty) ? null : name,
    );
  }

  @override
  Future<SessionUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _fromUser(user);
  }

  @override
  Future<SessionUser> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: name == null || name.isEmpty ? null : {'name': name},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Sign up failed');
    }
    if (response.session == null) {
      throw StateError(
        'Check your email to confirm the account, or disable '
        '"Confirm email" under Supabase Auth → Providers → Email.',
      );
    }
    return _fromUser(user);
  }

  @override
  Future<SessionUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Sign in failed');
    }
    return _fromUser(user);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class SupabaseCatalogStore implements CatalogStore {
  SupabaseCatalogStore(this._client);

  final SupabaseClient _client;

  String get _categories => Env.categoriesTable;
  String get _items => Env.itemsTable;
  String get _profiles => Env.profilesTable;
  String get _envelopes => Env.envelopesTable;

  @override
  Future<List<Category>> listCategories(String userId) async {
    final rows = await _client
        .from(_categories)
        .select()
        .eq('user_id', userId)
        .order('name')
        .limit(100);
    return (rows as List).map((r) => _categoryFromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<Category> createCategory(String userId, NewCategory input) async {
    final row = await _client
        .from(_categories)
        .insert({
          'user_id': userId,
          'name': input.name,
          if (input.color != null) 'color': input.color,
        })
        .select()
        .single();
    return _categoryFromRow(row);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final row = await _client
        .from(_categories)
        .update({
          'name': category.name,
          if (category.color != null) 'color': category.color,
        })
        .eq('id', category.id)
        .select()
        .single();
    return _categoryFromRow(row);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from(_categories).delete().eq('id', categoryId);
  }

  @override
  Future<List<Purchase>> listPurchases(String userId) async {
    final rows = await _client
        .from(_items)
        .select()
        .eq('user_id', userId)
        .order('purchased_at', ascending: false)
        .limit(500);
    return (rows as List).map((r) => _purchaseFromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<Purchase> createPurchase(String userId, NewPurchase input) async {
    final row = await _client
        .from(_items)
        .insert(
          _purchaseData(
            userId: userId,
            name: input.name,
            categoryId: input.categoryId,
            price: input.price,
            currencyCode: input.currencyCode,
            purchasedAt: input.purchasedAt,
            expectedFinishAt: input.expectedFinishAt,
            expiresAt: input.expiresAt,
            finishedAt: null,
            notes: input.notes,
          ),
        )
        .select()
        .single();
    return _purchaseFromRow(row);
  }

  @override
  Future<Purchase> updatePurchase(Purchase purchase) async {
    final row = await _client
        .from(_items)
        .update(
          _purchaseData(
            userId: purchase.userId,
            name: purchase.name,
            categoryId: purchase.categoryId,
            price: purchase.price,
            currencyCode: purchase.currencyCode,
            purchasedAt: purchase.purchasedAt,
            expectedFinishAt: purchase.expectedFinishAt,
            expiresAt: purchase.expiresAt,
            finishedAt: purchase.finishedAt,
            notes: purchase.notes,
          ),
        )
        .eq('id', purchase.id)
        .select()
        .single();
    return _purchaseFromRow(row);
  }

  @override
  Future<void> deletePurchase(String purchaseId) async {
    await _client.from(_items).delete().eq('id', purchaseId);
  }

  @override
  Future<Profile?> getProfile(String userId) async {
    final rows = await _client
        .from(_profiles)
        .select()
        .eq('user_id', userId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return _profileFromRow(list.first as Map<String, dynamic>);
  }

  @override
  Future<Profile> upsertProfile(
    String userId, {
    required String currencyCode,
  }) async {
    final row = await _client
        .from(_profiles)
        .upsert(
          {
            'user_id': userId,
            'currency_code': currencyCode,
          },
          onConflict: 'user_id',
        )
        .select()
        .single();
    return _profileFromRow(row);
  }

  @override
  Future<List<Envelope>> listEnvelopes(
    String userId,
    int year,
    int month,
  ) async {
    final rows = await _client
        .from(_envelopes)
        .select()
        .eq('user_id', userId)
        .eq('year', year)
        .eq('month', month)
        .limit(100);
    return (rows as List).map((r) => _envelopeFromRow(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<Envelope> createEnvelope(String userId, NewEnvelope input) async {
    final row = await _client
        .from(_envelopes)
        .insert(
          _envelopeData(
            userId: userId,
            year: input.year,
            month: input.month,
            name: input.name,
            type: input.type,
            budgeted: input.budgeted,
            actual: input.actual,
            currencyCode: input.currencyCode,
            categoryId: input.categoryId,
          ),
        )
        .select()
        .single();
    return _envelopeFromRow(row);
  }

  @override
  Future<Envelope> updateEnvelope(Envelope envelope) async {
    final row = await _client
        .from(_envelopes)
        .update(
          _envelopeData(
            userId: envelope.userId,
            year: envelope.year,
            month: envelope.month,
            name: envelope.name,
            type: envelope.type,
            budgeted: envelope.budgeted,
            actual: envelope.actual,
            currencyCode: envelope.currencyCode,
            categoryId: envelope.categoryId,
          ),
        )
        .eq('id', envelope.id)
        .select()
        .single();
    return _envelopeFromRow(row);
  }

  @override
  Future<void> deleteEnvelope(String envelopeId) async {
    await _client.from(_envelopes).delete().eq('id', envelopeId);
  }

  Map<String, dynamic> _purchaseData({
    required String userId,
    required String name,
    required String categoryId,
    required double price,
    required String currencyCode,
    required DateTime purchasedAt,
    required DateTime expectedFinishAt,
    required DateTime? expiresAt,
    required DateTime? finishedAt,
    required String? notes,
  }) {
    return {
      'user_id': userId,
      'name': name,
      'category_id': categoryId,
      'price': price,
      'currency_code': currencyCode,
      'purchased_at': purchasedAt.toUtc().toIso8601String(),
      'expected_finish_at': expectedFinishAt.toUtc().toIso8601String(),
      'expires_at': expiresAt?.toUtc().toIso8601String(),
      'finished_at': finishedAt?.toUtc().toIso8601String(),
      'notes': notes,
    };
  }

  Map<String, dynamic> _envelopeData({
    required String userId,
    required int year,
    required int month,
    required String name,
    required EnvelopeType type,
    required double budgeted,
    required double actual,
    required String currencyCode,
    required String? categoryId,
  }) {
    return {
      'user_id': userId,
      'year': year,
      'month': month,
      'name': name,
      'type': type.wire,
      'budgeted': budgeted,
      'actual': actual,
      'currency_code': currencyCode,
      'category_id': categoryId,
    };
  }

  Category _categoryFromRow(Map<String, dynamic> row) {
    return Category(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      color: row['color'] as String?,
    );
  }

  Purchase _purchaseFromRow(Map<String, dynamic> row) {
    DateTime? parseOpt(dynamic v) =>
        v == null ? null : DateTime.parse(v as String).toLocal();

    final code = row['currency_code'] as String?;
    return Purchase(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      categoryId: row['category_id'] as String,
      price: (row['price'] as num).toDouble(),
      currencyCode: (code == null || code.isEmpty) ? kDefaultCurrencyCode : code,
      purchasedAt: DateTime.parse(row['purchased_at'] as String).toLocal(),
      expectedFinishAt:
          DateTime.parse(row['expected_finish_at'] as String).toLocal(),
      expiresAt: parseOpt(row['expires_at']),
      finishedAt: parseOpt(row['finished_at']),
      notes: row['notes'] as String?,
    );
  }

  Profile _profileFromRow(Map<String, dynamic> row) {
    return Profile(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      currencyCode: row['currency_code'] as String? ?? kDefaultCurrencyCode,
    );
  }

  Envelope _envelopeFromRow(Map<String, dynamic> row) {
    return Envelope(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      year: (row['year'] as num).toInt(),
      month: (row['month'] as num).toInt(),
      name: row['name'] as String,
      type: EnvelopeType.fromWire(row['type'] as String),
      budgeted: (row['budgeted'] as num).toDouble(),
      actual: (row['actual'] as num?)?.toDouble() ?? 0,
      currencyCode: row['currency_code'] as String? ?? kDefaultCurrencyCode,
      categoryId: row['category_id'] as String?,
    );
  }
}
