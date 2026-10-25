import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'glass_container.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final TransactionCategory? category;
  final Account? account;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.account,
    this.onDelete,
    this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final isIncome = transaction.type == TransactionType.income;
    final catColor = category?.color ?? AppColors.catOther;
    final catIcon = category?.icon ?? Icons.category_rounded;

    // Strict color differentiation: Income strictly green, expenses neutral white
    final amountColor = isExpense
        ? Colors.white
        : isIncome
            ? AppColors.income
            : AppColors.iosBlue;

    final canDelete = onDelete != null;
    final canDuplicate = onDuplicate != null;

    final dismissDirection = canDelete && canDuplicate
        ? DismissDirection.horizontal
        : canDelete
            ? DismissDirection.endToStart
            : canDuplicate
                ? DismissDirection.startToEnd
                : DismissDirection.none;

    return Dismissible(
      key: ValueKey('tx_${transaction.id}'),
      direction: dismissDirection,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right: Quick repeat / duplicate
          HapticFeedback.heavyImpact();
          onDuplicate?.call();
          return false; // Snap back smoothly after trigger
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left: Delete
          if (!canDelete) return false;
          HapticFeedback.mediumImpact();
          return true; // Allow dismiss animation
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete?.call();
        }
      },
      // Swipe Right Background (Repeat / Duplicate)
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.income.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.income.withValues(alpha: 0.35), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay_rounded, color: AppColors.income, size: 22),
            SizedBox(width: 8),
            Text(
              'Повторить',
              style: TextStyle(
                color: AppColors.income,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      // Swipe Left Background (Delete)
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.expense.withValues(alpha: 0.35), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Удалить',
              style: TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 22),
          ],
        ),
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.55),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle Hierarchy
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        category?.name ?? 'Категория',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.50),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (account != null) ...[
                        Text(
                          ' • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            account!.bankName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.50),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Amount & Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(
                    isIncome ? transaction.amount : -transaction.amount,
                    showSign: true,
                    currency: 'сом',
                  ),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppDateFormatter.formatShortDate(transaction.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.40),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
