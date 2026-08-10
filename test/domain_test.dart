import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/adapters/fake/fake_adapters.dart';
import 'package:ledger/catalog/models.dart';
import 'package:ledger/core/money.dart';
import 'package:ledger/domain/envelope_ledger/envelope_ledger.dart';
import 'package:ledger/domain/purchase_lifecycle/purchase_lifecycle.dart';
import 'package:ledger/domain/spend_summary/spend_summary.dart';

Purchase _p({
  required DateTime purchasedAt,
  required DateTime expectedFinishAt,
  DateTime? expiresAt,
  DateTime? finishedAt,
  double price = 10,
  String categoryId = 'c1',
  String currencyCode = 'IDR',
}) {
  return Purchase(
    id: '1',
    userId: 'u1',
    name: 'Milk',
    categoryId: categoryId,
    price: price,
    currencyCode: currencyCode,
    purchasedAt: purchasedAt,
    expectedFinishAt: expectedFinishAt,
    expiresAt: expiresAt,
    finishedAt: finishedAt,
  );
}

void main() {
  const lifecycle = PurchaseLifecycle(soonWindowDays: 7);
  final today = DateTime(2026, 8, 10);

  group('PurchaseLifecycle', () {
    test('finished when finishedAt set', () {
      final p = _p(
        purchasedAt: DateTime(2026, 8, 1),
        expectedFinishAt: DateTime(2026, 8, 20),
        finishedAt: DateTime(2026, 8, 5),
      );
      expect(lifecycle.statusOf(p, today: today), ItemStatus.finished);
    });

    test('overdue when expected finish is past', () {
      final p = _p(
        purchasedAt: DateTime(2026, 8, 1),
        expectedFinishAt: DateTime(2026, 8, 5),
      );
      expect(lifecycle.statusOf(p, today: today), ItemStatus.overdue);
    });

    test('finishingSoon within window', () {
      final p = _p(
        purchasedAt: DateTime(2026, 8, 1),
        expectedFinishAt: DateTime(2026, 8, 14),
      );
      expect(lifecycle.statusOf(p, today: today), ItemStatus.finishingSoon);
    });

    test('expiringSoon preferred when both soon', () {
      final p = _p(
        purchasedAt: DateTime(2026, 8, 1),
        expectedFinishAt: DateTime(2026, 8, 14),
        expiresAt: DateTime(2026, 8, 12),
      );
      expect(lifecycle.statusOf(p, today: today), ItemStatus.expiringSoon);
    });

    test('markFinished sets finishedAt', () {
      final p = _p(
        purchasedAt: DateTime(2026, 8, 1),
        expectedFinishAt: DateTime(2026, 8, 20),
      );
      final next = lifecycle.markFinished(p, at: today);
      expect(next.finishedAt, today);
      expect(lifecycle.statusOf(next, today: today), ItemStatus.finished);
    });

    test('all filter excludes finished', () {
      final active = _p(
        purchasedAt: DateTime(2026, 8, 1),
        expectedFinishAt: DateTime(2026, 9, 1),
      );
      final done = lifecycle.markFinished(active, at: today);
      expect(lifecycle.matchesFilter(active, HomeFilter.all, today: today), true);
      expect(lifecycle.matchesFilter(done, HomeFilter.all, today: today), false);
      expect(
        lifecycle.matchesFilter(done, HomeFilter.finished, today: today),
        true,
      );
    });
  });

  group('SpendSummary', () {
    test('aggregates by category for month', () {
      const summary = SpendSummary();
      final result = summary.forMonth(
        year: 2026,
        month: 8,
        categories: const [
          Category(id: 'c1', userId: 'u', name: 'Groceries'),
          Category(id: 'c2', userId: 'u', name: 'Household'),
        ],
        purchases: [
          _p(
            purchasedAt: DateTime(2026, 8, 2),
            expectedFinishAt: DateTime(2026, 8, 9),
            price: 12,
            categoryId: 'c1',
          ),
          _p(
            purchasedAt: DateTime(2026, 8, 5),
            expectedFinishAt: DateTime(2026, 8, 12),
            price: 8,
            categoryId: 'c1',
          ),
          _p(
            purchasedAt: DateTime(2026, 7, 30),
            expectedFinishAt: DateTime(2026, 8, 5),
            price: 50,
            categoryId: 'c2',
          ),
          _p(
            purchasedAt: DateTime(2026, 8, 8),
            expectedFinishAt: DateTime(2026, 8, 15),
            price: 20,
            categoryId: 'c2',
          ),
        ],
      );

      expect(result.total, 40);
      expect(result.byCategory.length, 2);
      expect(result.byCategory.first.categoryName, 'Groceries');
      expect(result.byCategory.first.total, 20);
      expect(result.byCategory.last.total, 20);
    });
  });

  group('money', () {
    test('normalizeCurrencyCode rejects bad input', () {
      expect(() => normalizeCurrencyCode('id'), throwsArgumentError);
      expect(normalizeCurrencyCode('idr'), 'IDR');
    });
  });

  group('EnvelopeLedger', () {
    test('rolls up purchase actuals and differences', () async {
      final store = FakeCatalogStore();
      final ledger = EnvelopeLedger(store: store);
      const userId = 'u1';

      final groceries = await store.createCategory(
        userId,
        const NewCategory(name: 'Groceries'),
      );
      await store.createCategory(userId, const NewCategory(name: 'Household'));

      await store.createPurchase(
        userId,
        NewPurchase(
          name: 'Milk',
          categoryId: groceries.id,
          price: 30,
          currencyCode: 'IDR',
          purchasedAt: DateTime(2026, 8, 5),
          expectedFinishAt: DateTime(2026, 8, 12),
        ),
      );

      final view = await ledger.resolveMonth(
        userId: userId,
        year: 2026,
        month: 8,
        purchases: await store.listPurchases(userId),
        categories: await store.listCategories(userId),
        currencyCode: 'IDR',
      );

      expect(view.lines.length, 4);
      final groceryLine = view.lines.firstWhere(
        (l) => l.envelope.name == 'Groceries',
      );
      expect(groceryLine.resolvedActual, 30);

      await ledger.saveEnvelope(
        groceryLine.envelope.copyWith(budgeted: 100),
      );
      final income = view.lines.firstWhere(
        (l) => l.envelope.type == EnvelopeType.income,
      );
      await ledger.saveEnvelope(income.envelope.copyWith(actual: 500));

      final again = await ledger.resolveMonth(
        userId: userId,
        year: 2026,
        month: 8,
        purchases: await store.listPurchases(userId),
        categories: await store.listCategories(userId),
        currencyCode: 'IDR',
      );

      final g2 = again.lines.firstWhere((l) => l.envelope.name == 'Groceries');
      expect(g2.difference, 70);
      expect(again.incomeActual, 500);
      expect(again.expenseActual, 30);
      expect(again.net, 470);
    });
  });
}
