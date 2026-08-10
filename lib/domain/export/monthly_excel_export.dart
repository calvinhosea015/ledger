import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../../catalog/models.dart';
import '../envelope_ledger/envelope_ledger.dart';
import '../spend_summary/spend_summary.dart';

/// Calendar bounds for a month: 1st → last day (inclusive).
class MonthRange {
  MonthRange(this.year, this.month)
      : start = DateTime(year, month, 1),
        end = DateTime(year, month + 1, 0);

  final int year;
  final int month;
  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  String get fileLabel => DateFormat('yyyy-MM').format(start);

  String get displayLabel => DateFormat.yMMMM().format(start);
}

/// Builds a monthly Ledger workbook (Purchases + Budget + Summary).
class MonthlyExcelExport {
  const MonthlyExcelExport();

  List<int> buildBytes({
    required int year,
    required int month,
    required List<Purchase> purchases,
    required List<Category> categories,
    required MonthEnvelopeView budget,
    required MonthSpendSummary spend,
  }) {
    final range = MonthRange(year, month);
    final catNames = {for (final c in categories) c.id: c.name};
    final dateFmt = DateFormat('yyyy-MM-dd');

    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Purchases');

    _writePurchases(
      excel['Purchases'],
      purchases.where((p) => range.contains(p.purchasedAt)).toList()
        ..sort((a, b) => a.purchasedAt.compareTo(b.purchasedAt)),
      catNames,
      dateFmt,
    );

    final budgetSheet = excel['Budget'];
    _writeBudget(budgetSheet, budget);

    final summarySheet = excel['Summary'];
    _writeSummary(summarySheet, range, budget, spend);

    final bytes = excel.encode();
    if (bytes == null) {
      throw StateError('Failed to encode Excel workbook');
    }
    return bytes;
  }

  void _writePurchases(
    Sheet sheet,
    List<Purchase> purchases,
    Map<String, String> catNames,
    DateFormat dateFmt,
  ) {
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Category'),
      TextCellValue('Price'),
      TextCellValue('Currency'),
      TextCellValue('Purchased'),
      TextCellValue('Expected date'),
      TextCellValue('Expiry'),
      TextCellValue('Finished'),
      TextCellValue('Notes'),
    ]);

    for (final p in purchases) {
      sheet.appendRow([
        TextCellValue(p.name),
        TextCellValue(catNames[p.categoryId] ?? ''),
        DoubleCellValue(p.price),
        TextCellValue(p.currencyCode),
        TextCellValue(dateFmt.format(p.purchasedAt)),
        TextCellValue(
          p.expectedFinishAt == null ? '' : dateFmt.format(p.expectedFinishAt!),
        ),
        TextCellValue(
          p.expiresAt == null ? '' : dateFmt.format(p.expiresAt!),
        ),
        TextCellValue(
          p.finishedAt == null ? '' : dateFmt.format(p.finishedAt!),
        ),
        TextCellValue(p.notes ?? ''),
      ]);
    }
  }

  void _writeBudget(Sheet sheet, MonthEnvelopeView budget) {
    sheet.appendRow([
      TextCellValue('Name'),
      TextCellValue('Type'),
      TextCellValue('Budgeted'),
      TextCellValue('Actual'),
      TextCellValue('Difference'),
      TextCellValue('Currency'),
    ]);

    for (final line in budget.lines) {
      sheet.appendRow([
        TextCellValue(line.envelope.name),
        TextCellValue(line.envelope.type.wire),
        DoubleCellValue(line.envelope.budgeted),
        DoubleCellValue(line.resolvedActual),
        DoubleCellValue(line.difference),
        TextCellValue(line.envelope.currencyCode),
      ]);
    }
  }

  void _writeSummary(
    Sheet sheet,
    MonthRange range,
    MonthEnvelopeView budget,
    MonthSpendSummary spend,
  ) {
    final dateFmt = DateFormat('yyyy-MM-dd');
    sheet.appendRow([
      TextCellValue('Period start'),
      TextCellValue(dateFmt.format(range.start)),
    ]);
    sheet.appendRow([
      TextCellValue('Period end'),
      TextCellValue(dateFmt.format(range.end)),
    ]);
    sheet.appendRow([TextCellValue(''), TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Income actual'),
      DoubleCellValue(budget.incomeActual),
    ]);
    sheet.appendRow([
      TextCellValue('Expense actual'),
      DoubleCellValue(budget.expenseActual),
    ]);
    sheet.appendRow([
      TextCellValue('Expense budgeted'),
      DoubleCellValue(budget.expenseBudgeted),
    ]);
    sheet.appendRow([
      TextCellValue('Net'),
      DoubleCellValue(budget.net),
    ]);
    sheet.appendRow([
      TextCellValue('Remaining'),
      DoubleCellValue(budget.remaining),
    ]);
    sheet.appendRow([TextCellValue(''), TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Purchase spend total'),
      DoubleCellValue(spend.total),
    ]);
    sheet.appendRow([TextCellValue(''), TextCellValue('')]);
    sheet.appendRow([
      TextCellValue('Category'),
      TextCellValue('Spend'),
    ]);
    for (final row in spend.byCategory) {
      sheet.appendRow([
        TextCellValue(row.categoryName),
        DoubleCellValue(row.total),
      ]);
    }
  }
}
