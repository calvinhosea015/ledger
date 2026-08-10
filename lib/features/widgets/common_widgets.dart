import 'package:flutter/material.dart';

import '../../catalog/models.dart';
import '../../core/theme.dart';
import '../../domain/purchase_lifecycle/purchase_lifecycle.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ItemStatus.finishingSoon => (
          LedgerColors.paleYellowBg,
          LedgerColors.paleYellowFg,
        ),
      ItemStatus.expiringSoon => (
          LedgerColors.paleBlueBg,
          LedgerColors.paleBlueFg,
        ),
      ItemStatus.overdue => (LedgerColors.paleRedBg, LedgerColors.paleRedFg),
      ItemStatus.finished => (
          LedgerColors.paleGreenBg,
          LedgerColors.paleGreenFg,
        ),
      ItemStatus.active => (LedgerColors.hairline, LedgerColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}

class PurchaseRow extends StatelessWidget {
  const PurchaseRow({
    super.key,
    required this.purchase,
    required this.categoryName,
    required this.status,
    required this.priceLabel,
    required this.subtitle,
    this.onTap,
  });

  final Purchase purchase;
  final String categoryName;
  final ItemStatus status;
  final String priceLabel;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mono = Theme.of(context).extension<LedgerTypeExt>()?.mono;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$categoryName · $subtitle',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (status != ItemStatus.active) ...[
                    const SizedBox(height: 6),
                    StatusBadge(status: status),
                  ],
                ],
              ),
            ),
            Text(priceLabel, style: mono),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LedgerColors.muted,
                ),
          ),
        ],
      ),
    );
  }
}
