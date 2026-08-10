/// Which lifecycle dates apply for a category, matched by name (case-insensitive).
class CategoryDateRules {
  const CategoryDateRules._();

  static String _norm(String name) => name.trim().toLowerCase();

  /// Expected finish/date: Utilities and Groceries only.
  static bool showsExpectedDate(String categoryName) {
    final n = _norm(categoryName);
    return n == 'utilities' || n == 'groceries';
  }

  /// Expiry date: Groceries only.
  static bool showsExpiryDate(String categoryName) {
    return _norm(categoryName) == 'groceries';
  }
}
