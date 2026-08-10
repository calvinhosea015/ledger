import '../../catalog/catalog_store.dart';
import '../../catalog/models.dart';
import '../../core/money.dart';

class EnvelopeLine {
  const EnvelopeLine({
    required this.envelope,
    required this.resolvedActual,
    required this.difference,
  });

  final Envelope envelope;

  /// Purchase rollup for expense types; stored actual for income/savings.
  final double resolvedActual;

  /// Expense: budgeted − actual. Income/savings: actual − budgeted.
  final double difference;
}

class MonthEnvelopeView {
  const MonthEnvelopeView({
    required this.year,
    required this.month,
    required this.lines,
    required this.incomeActual,
    required this.expenseActual,
    required this.expenseBudgeted,
    required this.net,
    required this.remaining,
  });

  final int year;
  final int month;
  final List<EnvelopeLine> lines;
  final double incomeActual;
  final double expenseActual;
  final double expenseBudgeted;
  final double net;
  final double remaining;

  List<EnvelopeLine> ofType(EnvelopeType type) =>
      lines.where((l) => l.envelope.type == type).toList();
}

/// Deep module: month envelopes + purchase-driven expense actuals.
class EnvelopeLedger {
  const EnvelopeLedger({required CatalogStore store}) : _store = store;

  final CatalogStore _store;

  Future<MonthEnvelopeView> resolveMonth({
    required String userId,
    required int year,
    required int month,
    required List<Purchase> purchases,
    required List<Category> categories,
    required String currencyCode,
  }) async {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be 1–12');
    }

    var envelopes = await _store.listEnvelopes(userId, year, month);
    if (envelopes.isEmpty) {
      envelopes = await _seedMonth(
        userId: userId,
        year: year,
        month: month,
        categories: categories,
        currencyCode: currencyCode,
      );
    } else {
      envelopes = await _ensureCategoryEnvelopes(
        userId: userId,
        year: year,
        month: month,
        categories: categories,
        currencyCode: currencyCode,
        existing: envelopes,
      );
    }

    final spendByCategory = _monthSpendByCategory(purchases, year, month);
    final lines = <EnvelopeLine>[];
    var incomeActual = 0.0;
    var expenseActual = 0.0;
    var expenseBudgeted = 0.0;

    for (final envelope in envelopes) {
      final resolved = envelope.type.usesPurchaseActual
          ? (envelope.categoryId == null
              ? 0.0
              : (spendByCategory[envelope.categoryId] ?? 0.0))
          : envelope.actual;

      final difference = envelope.type.isExpense
          ? envelope.budgeted - resolved
          : resolved - envelope.budgeted;

      lines.add(
        EnvelopeLine(
          envelope: envelope,
          resolvedActual: resolved,
          difference: difference,
        ),
      );

      if (envelope.type == EnvelopeType.income) {
        incomeActual += resolved;
      } else if (envelope.type.isExpense) {
        expenseActual += resolved;
        expenseBudgeted += envelope.budgeted;
      }
    }

    lines.sort((a, b) {
      final typeCmp = a.envelope.type.index.compareTo(b.envelope.type.index);
      if (typeCmp != 0) return typeCmp;
      return a.envelope.name.compareTo(b.envelope.name);
    });

    return MonthEnvelopeView(
      year: year,
      month: month,
      lines: lines,
      incomeActual: incomeActual,
      expenseActual: expenseActual,
      expenseBudgeted: expenseBudgeted,
      net: incomeActual - expenseActual,
      remaining: expenseBudgeted - expenseActual,
    );
  }

  Future<Envelope> addEnvelope(String userId, NewEnvelope input) {
    _validateMonth(input.month);
    return _store.createEnvelope(userId, input);
  }

  Future<Envelope> saveEnvelope(Envelope envelope) {
    _validateMonth(envelope.month);
    return _store.updateEnvelope(envelope);
  }

  Future<void> removeEnvelope(String envelopeId) =>
      _store.deleteEnvelope(envelopeId);

  /// Creates a variable expense envelope linked to [category] for the month.
  Future<Envelope> addCategoryBudget({
    required String userId,
    required Category category,
    required int year,
    required int month,
    required String currencyCode,
    double budgeted = 0,
  }) {
    _validateMonth(month);
    return _store.createEnvelope(
      userId,
      NewEnvelope(
        year: year,
        month: month,
        name: category.name,
        type: EnvelopeType.variable,
        budgeted: budgeted,
        currencyCode: currencyCode,
        categoryId: category.id,
      ),
    );
  }

  /// Removes envelopes linked to a deleted category for the given month.
  Future<void> removeCategoryBudgets({
    required String userId,
    required String categoryId,
    required int year,
    required int month,
  }) async {
    final envelopes = await _store.listEnvelopes(userId, year, month);
    for (final e in envelopes) {
      if (e.categoryId == categoryId) {
        await _store.deleteEnvelope(e.id);
      }
    }
  }

  /// Keeps envelope name in sync when a category is renamed.
  Future<void> renameCategoryBudgets({
    required String userId,
    required Category category,
    required int year,
    required int month,
  }) async {
    final envelopes = await _store.listEnvelopes(userId, year, month);
    for (final e in envelopes) {
      if (e.categoryId == category.id && e.name != category.name) {
        await _store.updateEnvelope(e.copyWith(name: category.name));
      }
    }
  }

  Future<Profile> ensureProfile(String userId) async {
    final existing = await _store.getProfile(userId);
    if (existing != null) return existing;
    return _store.upsertProfile(userId, currencyCode: kDefaultCurrencyCode);
  }

  Future<Profile> setCurrency(String userId, String currencyCode) {
    return _store.upsertProfile(
      userId,
      currencyCode: normalizeCurrencyCode(currencyCode),
    );
  }

  Map<String, double> _monthSpendByCategory(
    List<Purchase> purchases,
    int year,
    int month,
  ) {
    final totals = <String, double>{};
    for (final p in purchases) {
      if (p.purchasedAt.year != year || p.purchasedAt.month != month) continue;
      totals[p.categoryId] = (totals[p.categoryId] ?? 0) + p.price;
    }
    return totals;
  }

  Future<List<Envelope>> _seedMonth({
    required String userId,
    required String currencyCode,
    required int year,
    required int month,
    required List<Category> categories,
  }) async {
    final seeds = <NewEnvelope>[
      NewEnvelope(
        year: year,
        month: month,
        name: 'Salary',
        type: EnvelopeType.income,
        budgeted: 0,
        currencyCode: currencyCode,
      ),
      for (final category in categories)
        NewEnvelope(
          year: year,
          month: month,
          name: category.name,
          type: EnvelopeType.variable,
          budgeted: 0,
          currencyCode: currencyCode,
          categoryId: category.id,
        ),
      NewEnvelope(
        year: year,
        month: month,
        name: 'Emergency savings',
        type: EnvelopeType.savings,
        budgeted: 0,
        currencyCode: currencyCode,
      ),
    ];

    final created = <Envelope>[];
    for (final seed in seeds) {
      created.add(await _store.createEnvelope(userId, seed));
    }
    return created;
  }

  /// Ensures every category has a linked budget envelope for the month,
  /// plus default income and savings buckets if missing.
  Future<List<Envelope>> _ensureCategoryEnvelopes({
    required String userId,
    required String currencyCode,
    required int year,
    required int month,
    required List<Category> categories,
    required List<Envelope> existing,
  }) async {
    final next = List<Envelope>.from(existing);

    if (!next.any((e) => e.type == EnvelopeType.income)) {
      next.add(
        await _store.createEnvelope(
          userId,
          NewEnvelope(
            year: year,
            month: month,
            name: 'Salary',
            type: EnvelopeType.income,
            budgeted: 0,
            currencyCode: currencyCode,
          ),
        ),
      );
    }

    final linkedIds = next
        .map((e) => e.categoryId)
        .whereType<String>()
        .toSet();
    for (final category in categories) {
      if (linkedIds.contains(category.id)) continue;
      next.add(
        await addCategoryBudget(
          userId: userId,
          category: category,
          year: year,
          month: month,
          currencyCode: currencyCode,
        ),
      );
    }

    if (!next.any((e) => e.type == EnvelopeType.savings)) {
      next.add(
        await _store.createEnvelope(
          userId,
          NewEnvelope(
            year: year,
            month: month,
            name: 'Emergency savings',
            type: EnvelopeType.savings,
            budgeted: 0,
            currencyCode: currencyCode,
          ),
        ),
      );
    }

    return next;
  }

  void _validateMonth(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be 1–12');
    }
  }
}
