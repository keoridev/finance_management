import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction_type.dart';
import '../state/finance_controller.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/glass_container.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/transaction_success_overlay.dart';

class TransactionsScreen extends StatefulWidget {
  final FinanceController controller;

  const TransactionsScreen({super.key, required this.controller});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = widget.controller.filteredTransactions;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'История операций',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Добавить операцию',
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF9F0A), size: 24),
            onPressed: () =>
                AddTransactionModal.show(context, widget.controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              borderRadius: BorderRadius.circular(16),
              surfaceColor: const Color(0xFF1C1C1E).withValues(alpha: 0.6),
              borderColor: Colors.white.withValues(alpha: 0.1),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Поиск по названию или категории...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            _searchController.clear();
                            widget.controller.setSearchQuery('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  widget.controller.setSearchQuery(val);
                  setState(() {});
                },
              ),
            ),
          ),

          // Type Segmented Filters (Apple White Fill, No Blue Noise)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildTypeChip('Все', null),
                const SizedBox(width: 8),
                _buildTypeChip('Расходы', TransactionType.expense),
                const SizedBox(width: 8),
                _buildTypeChip('Доходы', TransactionType.income),
              ],
            ),
          ),

          // Period Filters
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: PeriodFilter.values.map((period) {
                final isSelected = widget.controller.selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.controller.setPeriod(period);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF9F0A)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF9F0A)
                              : Colors.white.withValues(alpha: 0.1),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        period.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF161412)
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // Transactions List
          Expanded(
            child: transactions.isEmpty
                ? EmptyStateView(
                    icon: Icons.receipt_long_rounded,
                    title: 'Пока чисто, как в коде после рефакторинга',
                    subtitle:
                        'Нет операций за выбранный период. Кошелек в полной безопасности!',
                    actionLabel: 'Добавить операцию',
                    onAction: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            AddTransactionModal(controller: widget.controller),
                      );
                    },
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 100,
                    ),
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final category = widget.controller.getCategoryById(
                        tx.categoryId,
                      );
                      final account = widget.controller.getAccountById(
                        tx.accountId,
                      );
                      return TransactionTile(
                        transaction: tx,
                        category: category,
                        account: account,
                        onDelete: () =>
                            widget.controller.deleteTransaction(tx.id),
                        onDuplicate: () {
                          widget.controller.duplicateTransaction(tx);
                          TransactionSuccessOverlay.show(
                            context,
                            title: 'Операция повторена',
                            amount: tx.amount,
                            bankName: account?.bankName ?? '',
                            isIncome: tx.type == TransactionType.income,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, TransactionType? type) {
    final isSelected = widget.controller.selectedTypeFilter == type;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.controller.setTypeFilter(type);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9F0A)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9F0A)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF161412)
                : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}
