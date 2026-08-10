import '../../catalog/models.dart';

/// Derived status of a [Purchase] for filtering and badges.
enum ItemStatus {
  active,
  finishingSoon,
  expiringSoon,
  overdue,
  finished,
}

/// Deep domain module: purchase lifecycle rules.
///
/// Owns status derivation and mark-finished semantics. No backend SDK types.
class PurchaseLifecycle {
  const PurchaseLifecycle({this.soonWindowDays = 7});

  final int soonWindowDays;

  ItemStatus statusOf(Purchase purchase, {DateTime? today}) {
    final now = _dateOnly(today ?? DateTime.now());
    if (purchase.finishedAt != null) return ItemStatus.finished;

    final finish = _dateOnly(purchase.expectedFinishAt);
    if (finish.isBefore(now)) return ItemStatus.overdue;

    final expires = purchase.expiresAt == null
        ? null
        : _dateOnly(purchase.expiresAt!);
    final soonEnd = now.add(Duration(days: soonWindowDays));

    final finishingSoon =
        !finish.isAfter(soonEnd) && !finish.isBefore(now);
    final expiringSoon = expires != null &&
        !expires.isAfter(soonEnd) &&
        !expires.isBefore(now);

    if (expiringSoon) return ItemStatus.expiringSoon;
    if (finishingSoon) return ItemStatus.finishingSoon;
    return ItemStatus.active;
  }

  /// Sets [Purchase.finishedAt] to [at] (defaults to now).
  Purchase markFinished(Purchase purchase, {DateTime? at}) {
    if (purchase.finishedAt != null) return purchase;
    return purchase.copyWith(finishedAt: at ?? DateTime.now());
  }

  bool matchesFilter(Purchase purchase, HomeFilter filter, {DateTime? today}) {
    final status = statusOf(purchase, today: today);
    switch (filter) {
      case HomeFilter.all:
        return status != ItemStatus.finished;
      case HomeFilter.finishingSoon:
        return status == ItemStatus.finishingSoon ||
            status == ItemStatus.overdue;
      case HomeFilter.expiringSoon:
        return status == ItemStatus.expiringSoon;
      case HomeFilter.finished:
        return status == ItemStatus.finished;
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

enum HomeFilter { all, finishingSoon, expiringSoon, finished }

extension ItemStatusLabel on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.active:
        return 'Active';
      case ItemStatus.finishingSoon:
        return 'Finishing soon';
      case ItemStatus.expiringSoon:
        return 'Expiring soon';
      case ItemStatus.overdue:
        return 'Overdue';
      case ItemStatus.finished:
        return 'Finished';
    }
  }
}
