import 'models.dart';

/// Persistence seam for Categories, Purchases, Profiles, and Envelopes.
abstract class CatalogStore {
  Future<List<Category>> listCategories(String userId);

  Future<Category> createCategory(String userId, NewCategory input);

  Future<Category> updateCategory(Category category);

  Future<void> deleteCategory(String categoryId);

  Future<List<Purchase>> listPurchases(String userId);

  Future<Purchase> createPurchase(String userId, NewPurchase input);

  Future<Purchase> updatePurchase(Purchase purchase);

  Future<void> deletePurchase(String purchaseId);

  Future<Profile?> getProfile(String userId);

  Future<Profile> upsertProfile(String userId, {required String currencyCode});

  Future<List<Envelope>> listEnvelopes(String userId, int year, int month);

  Future<Envelope> createEnvelope(String userId, NewEnvelope input);

  Future<Envelope> updateEnvelope(Envelope envelope);

  Future<void> deleteEnvelope(String envelopeId);
}

class SessionUser {
  const SessionUser({required this.id, required this.email, this.name});

  final String id;
  final String email;
  final String? name;
}

/// Authentication seam.
abstract class AuthSession {
  Future<SessionUser?> currentUser();

  Future<SessionUser> signUp({
    required String email,
    required String password,
    String? name,
  });

  Future<SessionUser> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
