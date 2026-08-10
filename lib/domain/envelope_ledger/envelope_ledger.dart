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
    String? categoryIdNamed(String name) {
      for (final c in categories) {
        if (c.name.toLowerCase() == name.toLowerCase()) return c.id;
      }
      return categories.isEmpty ? null : categories.first.id;
    }

    final seeds = <NewEnvelope>[
      NewEnvelope(
        year: year,
        month: month,
        name: 'Salary',
        type: EnvelopeType.income,
        budgeted: 0,
        currencyCode: currencyCode,
      ),
      NewEnvelope(
        year: year,
        month: month,
        name: 'Rent',
        type: EnvelopeType.fixed,
        budgeted: 0,
        currencyCode: currencyCode,
        categoryId: categoryIdNamed('Household'),
      ),
      NewEnvelope(
        year: year,
        month: month,
        name: 'Groceries',
        type: EnvelopeType.variable,
        budgeted: 0,
        currencyCode: currencyCode,
        categoryId: categoryIdNamed('Groceries'),
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

  void _validateMonth(int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be 1–12');
    }
  }
}
