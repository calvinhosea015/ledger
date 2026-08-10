import '../../catalog/models.dart';

class CategorySpend {
  const CategorySpend({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });

  final String categoryId;
  final String categoryName;
  final double total;
}

class MonthSpendSummary {
  const MonthSpendSummary({
    required this.year,
    required this.month,
    required this.total,
    required this.byCategory,
  });

  final int year;
  final int month;
  final double total;
  final List<CategorySpend> byCategory;
}

/// Deep domain module: aggregate purchase spend over a calendar month.
class SpendSummary {
  const SpendSummary();

  MonthSpendSummary forMonth({
    required List<Purchase> purchases,
    required List<Category> categories,
    required int year,
    required int month,
  }) {
    final nameById = {for (final c in categories) c.id: c.name};
    final filtered = purchases.where((p) {
      return p.purchasedAt.year == year && p.purchasedAt.month == month;
    });

    final totals = <String, double>{};
    var grand = 0.0;
    for (final p in filtered) {
      totals[p.categoryId] = (totals[p.categoryId] ?? 0) + p.price;
      grand += p.price;
    }

    final byCategory = totals.entries
        .map(
          (e) => CategorySpend(
            categoryId: e.key,
            categoryName: nameById[e.key] ?? 'Unknown',
            total: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return MonthSpendSummary(
      year: year,
      month: month,
      total: grand,
      byCategory: byCategory,
    );
  }
}
