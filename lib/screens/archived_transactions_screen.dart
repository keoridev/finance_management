import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/glass_container.dart';

/// Screen displaying all archived (deleted) transactions with 1-tap restore capabilities.
class ArchivedTransactionsScreen extends StatelessWidget {
  final FinanceController controller;

  const ArchivedTransactionsScreen({super.key, required this.controller});

  void _confirmClearArchive(BuildContext context) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.expense, size: 24),
            SizedBox(width: 10),
            Text(
              'Очистить весь архив?',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Все удалённые транзакции будут стёрты навсегда без возможности восстановления. Балансы счетов не изменятся.',
          style: TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Отмена', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.clearArchive();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF1C1C1E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: const Text('Архив полностью очищен', style: TextStyle(color: Colors.white)),
                ),
              );
            },
            child: const Text('Очистить', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePermanently(BuildContext context, Transaction tx) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: const Text(
          'Удалить навсегда?',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Операция «${tx.title}» (${CurrencyFormatter.format(tx.amount)} сом) будет удалена навсегда.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Отмена', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.permanentlyDeleteTransaction(tx.id);
            },
            child: const Text('Удалить', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBackgroundScaffold(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Архив операций',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                if (controller.archivedTransactions.isEmpty) return const SizedBox.shrink();
                return TextButton.icon(
                  onPressed: () => _confirmClearArchive(context),
                  icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.expense, size: 18),
                  label: const Text(
                    'Очистить',
                    style: TextStyle(
                      color: AppColors.expense,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final archived = controller.archivedTransactions;

            if (archived.isEmpty) {
              return const Center(
                child: EmptyStateView(
                  icon: Icons.inventory_2_outlined,
                  title: 'Архив пуст',
                  subtitle: 'Сюда попадают транзакции, удалённые свайпом или вручную. '
                      'Вы всегда сможете вернуть их обратно в один тап.',
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF9F0A).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.restore_page_rounded,
                        color: Color(0xFFFF9F0A),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'В архиве: ${archived.length} ${archived.length == 1 ? "операция" : "операций"}',
                              style: const TextStyle(
                                color: Color(0xFFFF9F0A),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'При удалении свайпом сумма вернулась на баланс счета. '
                              'Нажмите «Вернуть», чтобы вернуть запись в историю с автоматическим пересчетом баланса.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Transactions List
                ...archived.map((tx) => _buildArchivedTile(context, tx)),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildArchivedTile(BuildContext context, Transaction tx) {
    final category = controller.getCategoryById(tx.categoryId);
    final account = controller.getAccountById(tx.accountId);
    final isExpense = tx.type == TransactionType.expense;
    final catColor = category?.color ?? AppColors.iosBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(18),
        surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.65),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                // Category Icon
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: catColor.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: Icon(
                    category?.icon ?? Icons.category_rounded,
                    color: catColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (account != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                account.bankName,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${AppDateFormatter.formatShortDate(tx.date)}, ${AppDateFormatter.formatTime(tx.date)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Text(
                  '${isExpense ? "−" : "+"}${CurrencyFormatter.format(tx.amount)} сом',
                  style: TextStyle(
                    color: isExpense ? AppColors.expense : AppColors.income,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Permanent Delete
                TextButton.icon(
                  onPressed: () => _confirmDeletePermanently(context, tx),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 16),
                  label: const Text(
                    'Удалить',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),

                // Restore Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF30D158).withValues(alpha: 0.18),
                    foregroundColor: const Color(0xFF30D158),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF30D158), width: 0.8),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    controller.restoreTransaction(tx.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: const Color(0xFF1C1C1E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF30D158), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '«${tx.title}» успешно возвращена в историю',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restore_from_trash_rounded, size: 17),
                  label: const Text(
                    'Восстановить',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
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
