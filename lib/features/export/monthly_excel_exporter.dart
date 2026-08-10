import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../catalog/models.dart';
import '../../domain/envelope_ledger/envelope_ledger.dart';
import '../../domain/export/monthly_excel_export.dart';
import '../../domain/spend_summary/spend_summary.dart';

/// Builds and saves a monthly Excel export via the system save dialog.
class MonthlyExcelExporter {
  MonthlyExcelExporter({
    MonthlyExcelExport builder = const MonthlyExcelExport(),
    SpendSummary spendSummary = const SpendSummary(),
  })  : _builder = builder,
        _spendSummary = spendSummary;

  final MonthlyExcelExport _builder;
  final SpendSummary _spendSummary;

  /// Returns the saved file path, or null if the user cancelled.
  Future<String?> exportMonth({
    required int year,
    required int month,
    required List<Purchase> purchases,
    required List<Category> categories,
    required MonthEnvelopeView budget,
  }) async {
    final range = MonthRange(year, month);
    final spend = _spendSummary.forMonth(
      purchases: purchases,
      categories: categories,
      year: year,
      month: month,
    );

    final bytes = _builder.buildBytes(
      year: year,
      month: month,
      purchases: purchases,
      categories: categories,
      budget: budget,
      spend: spend,
    );

    final fileName = 'ledger-${range.fileLabel}.xlsx';
    final location = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Excel',
          extensions: ['xlsx'],
        ),
      ],
    );
    if (location == null) return null;

    final path = location.path.endsWith('.xlsx')
        ? location.path
        : '${location.path}.xlsx';

    await File(path).writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return path;
  }
}
