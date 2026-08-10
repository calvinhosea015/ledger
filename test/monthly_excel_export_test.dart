import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/catalog/models.dart';
import 'package:ledger/domain/envelope_ledger/envelope_ledger.dart';
import 'package:ledger/domain/export/monthly_excel_export.dart';
import 'package:ledger/domain/spend_summary/spend_summary.dart';

void main() {
  group('MonthRange', () {
    test('covers 1st through last day inclusive', () {
      final feb = MonthRange(2026, 2);
      expect(feb.start, DateTime(2026, 2, 1));
      expect(feb.end, DateTime(2026, 2, 28));
      expect(feb.contains(DateTime(2026, 2, 1)), true);
      expect(feb.contains(DateTime(2026, 2, 28)), true);
      expect(feb.contains(DateTime(2026, 1, 31)), false);
      expect(feb.contains(DateTime(2026, 3, 1)), false);
    });
  });

  group('MonthlyExcelExport', () {
    test('builds workbook bytes for a month', () {
      const export = MonthlyExcelExport();
      final bytes = export.buildBytes(
        year: 2026,
        month: 8,
        purchases: [
          Purchase(
            id: '1',
            userId: 'u',
            name: 'Milk',
            categoryId: 'c1',
            price: 20,
            currencyCode: 'IDR',
            purchasedAt: DateTime(2026, 8, 5),
            expectedFinishAt: DateTime(2026, 8, 12),
          ),
          Purchase(
            id: '2',
            userId: 'u',
            name: 'Old',
            categoryId: 'c1',
            price: 5,
            currencyCode: 'IDR',
            purchasedAt: DateTime(2026, 7, 30),
          ),
        ],
        categories: const [
          Category(id: 'c1', userId: 'u', name: 'Groceries'),
        ],
        budget: const MonthEnvelopeView(
          year: 2026,
          month: 8,
          lines: [],
          incomeActual: 100,
          expenseActual: 20,
          expenseBudgeted: 50,
          net: 80,
          remaining: 30,
        ),
        spend: const MonthSpendSummary(
          year: 2026,
          month: 8,
          total: 20,
          byCategory: [
            CategorySpend(
              categoryId: 'c1',
              categoryName: 'Groceries',
              total: 20,
            ),
          ],
        ),
      );
      expect(bytes, isNotEmpty);
      // xlsx zip magic
      expect(bytes[0], 0x50); // P
      expect(bytes[1], 0x4B); // K
    });
  });
}
