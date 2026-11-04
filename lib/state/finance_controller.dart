import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/currency_rate.dart';
import '../models/quick_payment_shortcut.dart';
import '../models/recurring_payment.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import '../models/workout_penalty.dart';
import '../services/merchant_memory_service.dart';
import '../services/storage_service.dart';
import '../services/widget_launch_service.dart';
import '../utils/formatters.dart';

enum PeriodFilter {
  all('Все время'),
  thisMonth('Этот месяц'),
  thisWeek('Эта неделя'),
  today('Сегодня');

  final String label;
  const PeriodFilter(this.label);
}

enum CapybaraMoodState { zenHappy, chillNormal, shockedSpending, bankruptSad }

class FinanceController extends ChangeNotifier {
  late List<Account> _accounts;
  late List<Transaction> _transactions;
  late List<TransactionCategory> _categories;
  late List<CategoryBudget> _budgets;
  late List<CurrencyRate> _currencyRates;
  late List<RecurringPayment> _recurringPayments;
  late List<QuickPaymentShortcut> _quickShortcuts;
  late List<SavingsGoal> _savingsGoals;
  int _noSpendStreak = 0;
  List<Transaction> _archivedTransactions = [];

  bool _smartRoundUpEnabled = false;
  int _smartRoundUpStep = 100;
  double? _lastRoundUpAmount;
  String? _lastRoundUpGoalTitle;
  bool _capybaraFilterEnabled = false;
  bool _floatingCapyEnabled = false;
  bool _capybaraWidgetEnabled = true;
  WorkoutPenalty? _activeWorkoutPenalty;

  PeriodFilter _selectedPeriod = PeriodFilter.thisMonth;
  TransactionType? _selectedTypeFilter;
  String _searchQuery = '';
  String? _selectedAccountId;
  bool _isLoading = false;

  FinanceController() {
    _initData();
  }

  // Getters
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Transaction> get archivedTransactions => List.unmodifiable(_archivedTransactions);
  int get archivedCount => _archivedTransactions.length;
  List<TransactionCategory> get categories => List.unmodifiable(_categories);
  List<CategoryBudget> get budgets => List.unmodifiable(_budgets);
  List<CurrencyRate> get currencyRates => List.unmodifiable(_currencyRates);
  List<RecurringPayment> get recurringPayments =>
      List.unmodifiable(_recurringPayments);
  List<QuickPaymentShortcut> get quickShortcuts =>
      List.unmodifiable(_quickShortcuts);

  /// Dynamically computes the 4 quick buttons for home screen widgets & previews,
  /// prioritizing the user's most recently entered payments and custom shortcuts.
  List<QuickPaymentShortcut> get quickButtonsForWidget {
    final List<QuickPaymentShortcut> result = [];
    final Set<String> seenTitles = {};

    // 1. Take quick shortcuts (user-configured or recently entered)
    for (final s in _quickShortcuts) {
      final normTitle = s.title.toLowerCase().trim();
      if (!seenTitles.contains(normTitle) && s.amount > 0) {
        seenTitles.add(normTitle);
        result.add(s);
      }
      if (result.length >= 4) return result;
    }

    // 2. Supplement with unique recent expense transactions
    for (final t in _transactions) {
      if (t.type != TransactionType.expense || t.amount <= 0 || t.title.trim().isEmpty) {
        continue;
      }
      final normTitle = t.title.toLowerCase().trim();
      if (!seenTitles.contains(normTitle)) {
        seenTitles.add(normTitle);
        final cat = getCategoryById(t.categoryId);
        result.add(
          QuickPaymentShortcut(
            id: 'q_recent_${t.id}',
            title: t.title.trim(),
            amount: t.amount,
            categoryId: t.categoryId,
            accountId: t.accountId,
            icon: cat?.icon ?? Icons.bolt_rounded,
            color: cat?.color ?? const Color(0xFFFF9F0A),
          ),
        );
      }
      if (result.length >= 4) return result;
    }

    // 3. Fallback to classic defaults if fewer than 4
    final defaults = [
      const QuickPaymentShortcut(
        id: 'q_default_marshrutka',
        title: 'Маршрутка',
        amount: 25.0,
        categoryId: 'cat_transport',
        accountId: 'acc_mbank',
        icon: Icons.airport_shuttle_rounded,
        color: Color(0xFF0A84FF),
      ),
      const QuickPaymentShortcut(
        id: 'q_default_coffee',
        title: 'Кофе',
        amount: 150.0,
        categoryId: 'cat_restaurants',
        accountId: 'acc_mbank',
        icon: Icons.coffee_rounded,
        color: Color(0xFFFF9F0A),
      ),
      const QuickPaymentShortcut(
        id: 'q_default_lunch',
        title: 'Обед',
        amount: 350.0,
        categoryId: 'cat_restaurants',
        accountId: 'acc_mbank',
        icon: Icons.restaurant_rounded,
        color: Color(0xFFFF453A),
      ),
      const QuickPaymentShortcut(
        id: 'q_default_taxi',
        title: 'Такси',
        amount: 180.0,
        categoryId: 'cat_transport',
        accountId: 'acc_mbank',
        icon: Icons.local_taxi_rounded,
        color: Color(0xFFFFD60A),
      ),
    ];

    for (final def in defaults) {
      final normTitle = def.title.toLowerCase().trim();
      if (!seenTitles.contains(normTitle)) {
        seenTitles.add(normTitle);
        result.add(def);
      }
      if (result.length >= 4) break;
    }

    return result;
  }

  List<SavingsGoal> get savingsGoals => List.unmodifiable(_savingsGoals);
  int get noSpendStreak => _noSpendStreak;
  bool get isLoading => _isLoading;

  bool get smartRoundUpEnabled => _smartRoundUpEnabled;
  int get smartRoundUpStep => _smartRoundUpStep;
  double? get lastRoundUpAmount => _lastRoundUpAmount;
  String? get lastRoundUpGoalTitle => _lastRoundUpGoalTitle;
  bool get capybaraFilterEnabled => _capybaraFilterEnabled;
  bool get floatingCapyEnabled => _floatingCapyEnabled;
  bool get capybaraWidgetEnabled => _capybaraWidgetEnabled;
  WorkoutPenalty? get activeWorkoutPenalty => _activeWorkoutPenalty;
  bool get isSocialBlockerActive => _activeWorkoutPenalty != null;

  PeriodFilter get selectedPeriod => _selectedPeriod;
  TransactionType? get selectedTypeFilter => _selectedTypeFilter;
  String get searchQuery => _searchQuery;
  String? get selectedAccountId => _selectedAccountId;

  void setPeriod(PeriodFilter period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  void setTypeFilter(TransactionType? type) {
    _selectedTypeFilter = type;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedAccount(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  Future<void> simulateLoading({
    Duration duration = const Duration(milliseconds: 900),
  }) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(duration);
    _isLoading = false;
    notifyListeners();
  }

  double get totalBalance {
    return _accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  double get activeBalance {
    if (_selectedAccountId != null) {
      final acc = getAccountById(_selectedAccountId!);
      if (acc != null) return acc.balance;
    }
    return totalBalance;
  }

  String get activeAccountLabel {
    if (_selectedAccountId != null) {
      final acc = getAccountById(_selectedAccountId!);
      if (acc != null) return acc.bankName;
    }
    return 'Общий баланс';
  }

  double get totalMonthlyRecurring {
    return _recurringPayments.where((r) => r.isActive).fold(0.0, (sum, r) {
      switch (r.frequency) {
        case RecurringFrequency.daily:
          return sum + (r.amount * 30);
        case RecurringFrequency.weekly:
          return sum + (r.amount * 4.33);
        case RecurringFrequency.monthly:
          return sum + r.amount;
        case RecurringFrequency.yearly:
          return sum + (r.amount / 12);
      }
    });
  }

  List<Transaction> get filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      if (_selectedTypeFilter != null && t.type != _selectedTypeFilter) {
        return false;
      }

      if (_selectedAccountId != null &&
          t.accountId != _selectedAccountId &&
          t.toAccountId != _selectedAccountId) {
        return false;
      }

      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final category = getCategoryById(t.categoryId);
        final matchesTitle = t.title.toLowerCase().contains(query);
        final matchesCategory =
            category?.name.toLowerCase().contains(query) ?? false;
        final matchesNote = t.note?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesCategory && !matchesNote) {
          return false;
        }
      }

      switch (_selectedPeriod) {
        case PeriodFilter.today:
          return t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day;
        case PeriodFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final beginningOfWeek = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          return t.date.isAfter(
            beginningOfWeek.subtract(const Duration(seconds: 1)),
          );
        case PeriodFilter.thisMonth:
          return t.date.year == now.year && t.date.month == now.month;
        case PeriodFilter.all:
          return true;
      }
    }).toList();
  }

  double get periodIncome {
    return filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get periodExpense {
    return filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get periodCashFlow => periodIncome - periodExpense;

  TransactionCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Account? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  double getCategorySpending(String categoryId, {PeriodFilter? period}) {
    final targetPeriod = period ?? _selectedPeriod;
    final now = DateTime.now();

    return _transactions
        .where((t) {
          if (t.categoryId != categoryId || t.type != TransactionType.expense) {
            return false;
          }

          switch (targetPeriod) {
            case PeriodFilter.today:
              return t.date.year == now.year &&
                  t.date.month == now.month &&
                  t.date.day == now.day;
            case PeriodFilter.thisWeek:
              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              final beginningOfWeek = DateTime(
                startOfWeek.year,
                startOfWeek.month,
                startOfWeek.day,
              );
              return t.date.isAfter(
                beginningOfWeek.subtract(const Duration(seconds: 1)),
              );
            case PeriodFilter.thisMonth:
              return t.date.year == now.year && t.date.month == now.month;
            case PeriodFilter.all:
              return true;
          }
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<TransactionCategory, double> getCategoryExpensesBreakdown({
    PeriodFilter? period,
  }) {
    final Map<TransactionCategory, double> map = {};
    for (final category in _categories.where(
      (c) => c.type == TransactionType.expense,
    )) {
      final spent = getCategorySpending(category.id, period: period);
      if (spent > 0) {
        map[category] = spent;
      }
    }
    return map;
  }

  // Currency Converter calculation
  double convertCurrency({
    required double amount,
    required String fromCode,
    required String toCode,
  }) {
    if (fromCode == toCode) return amount;

    double amountInKgs = amount;
    if (fromCode != 'KGS') {
      final rate = _currencyRates.firstWhere(
        (r) => r.code == fromCode,
        orElse: () => _currencyRates.first,
      );
      amountInKgs = amount * rate.officialRate;
    }

    if (toCode == 'KGS') {
      return amountInKgs;
    } else {
      final rate = _currencyRates.firstWhere(
        (r) => r.code == toCode,
        orElse: () => _currencyRates.first,
      );
      return amountInKgs / rate.officialRate;
    }
  }

  // Transactions Actions
  static int _txCounter = 0;
  static String _generateTxId() =>
      'tx_${DateTime.now().microsecondsSinceEpoch}_${_txCounter++}';

  void addTransaction({
    required String title,
    required double amount,
    required DateTime date,
    required TransactionType type,
    required String categoryId,
    required String accountId,
    String? toAccountId,
    String? note,
    bool isAutoBank = false,
  }) {
    final newTransaction = Transaction(
      id: _generateTxId(),
      title: title,
      amount: amount,
      date: date,
      type: type,
      categoryId: categoryId,
      accountId: accountId,
      toAccountId: toAccountId,
      note: note,
    );

    // Update account balances
    final accIndex = _accounts.indexWhere((a) => a.id == accountId);
    if (accIndex != -1) {
      if (type == TransactionType.expense) {
        _accounts[accIndex].balance -= amount;
      } else if (type == TransactionType.income) {
        _accounts[accIndex].balance += amount;
      } else if (type == TransactionType.transfer && toAccountId != null) {
        _accounts[accIndex].balance -= amount;
        final toAccIndex = _accounts.indexWhere((a) => a.id == toAccountId);
        if (toAccIndex != -1) {
          _accounts[toAccIndex].balance += amount;
        }
      }
    }

    _transactions.insert(0, newTransaction);

    // Streetlifting Workout Penalty trigger for Entertainment limit breach
    if (type == TransactionType.expense &&
        categoryId == 'cat_entertainment') {
      final budget = _budgets.firstWhere(
        (b) => b.categoryId == 'cat_entertainment',
        orElse: () => const CategoryBudget(
          categoryId: 'cat_entertainment',
          monthlyLimit: 5000.0,
        ),
      );
      final spent = getCategorySpending('cat_entertainment');
      if (budget.monthlyLimit > 0 && spent > budget.monthlyLimit) {
        final excess = spent - budget.monthlyLimit;
        _activeWorkoutPenalty = WorkoutPenalty(
          id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
          title: '25 подтягиваний',
          reps: 25,
          exercise: 'подтягиваний',
          reason: 'Превышен лимит на «Развлечения»',
          excessAmount: excess,
          timestamp: DateTime.now(),
        );
      }
    }

    // Dynamically update quick buttons with latest entered expense
    if (type == TransactionType.expense && amount > 0 && title.trim().isNotEmpty) {
      _updateQuickShortcutsWithRecentExpense(
        title: title,
        amount: amount,
        categoryId: categoryId,
        accountId: accountId,
      );
    }

    // Intelligently learn merchant -> category association for future auto-categorization
    if (title.trim().isNotEmpty && categoryId.isNotEmpty) {
      MerchantMemoryService.learnMerchant(title, categoryId);
    }

    invalidateCapybaraHealthCache();
    HapticFeedback.mediumImpact();
    _saveToStorage();
    notifyListeners();
  }

  /// Recategorizes an existing transaction and immediately learns the merchant mapping
  void updateTransactionCategory(String transactionId, String newCategoryId) {
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx != -1) {
      final tx = _transactions[idx];
      _transactions[idx] = tx.copyWith(categoryId: newCategoryId);
      // Permanently remember that this merchant maps to this new category!
      MerchantMemoryService.learnMerchant(tx.title, newCategoryId);
      invalidateCapybaraHealthCache();
      _saveToStorage();
      notifyListeners();
    }
  }

  void toggleSmartRoundUp(bool value) {
    _smartRoundUpEnabled = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('arc_smart_round_up_enabled', value);
      prefs.setBool('rounding_enabled', value);
    }).catchError((_) {});
    _saveToStorage();
    notifyListeners();
  }

  void toggleCapybaraFilter(bool value) {
    _capybaraFilterEnabled = value;
    final dreamGoal = _savingsGoals.isNotEmpty ? _savingsGoals.first.title : 'MacBook Pro M3';
    final remaining = _savingsGoals.isNotEmpty
        ? (_savingsGoals.first.targetAmount - _savingsGoals.first.currentAmount).clamp(0.0, 99999999.0)
        : 120000.0;
    WidgetLaunchService.syncCapybaraFilterConfig(
      enabled: value,
      threshold: 500.0,
      dreamGoal: dreamGoal,
      remainingGoal: remaining,
    );
    _saveToStorage();
    notifyListeners();
  }

  void toggleFloatingCapy(bool value) {
    _floatingCapyEnabled = value;
    WidgetLaunchService.syncFloatingCapyConfig(enabled: value);
    _saveToStorage();
    notifyListeners();
  }

  void toggleCapybaraWidget(bool value) {
    _capybaraWidgetEnabled = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('arc_capybara_widget_enabled', value);
    }).catchError((_) {});
    _saveToStorage();
    notifyListeners();
  }

  void setSmartRoundUpStep(int step) {
    _smartRoundUpStep = step;
    _saveToStorage();
    notifyListeners();
  }

  void clearLastRoundUp() {
    _lastRoundUpAmount = null;
    _lastRoundUpGoalTitle = null;
    notifyListeners();
  }

  void completeWorkoutPenalty() {
    if (_activeWorkoutPenalty != null) {
      _winterShields++;
      _activeWorkoutPenalty = null;
      HapticFeedback.heavyImpact();
      _saveToStorage();
      WidgetLaunchService.syncSocialBlockerConfig(
        enabled: true,
        isBlocked: false,
      );
      notifyListeners();
    }
  }

  void dismissWorkoutPenalty() {
    _activeWorkoutPenalty = null;
    WidgetLaunchService.syncSocialBlockerConfig(
      enabled: true,
      isBlocked: false,
    );
    notifyListeners();
  }

  void deleteTransaction(String id, {bool moveToArchive = true}) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final tx = _transactions[index];

    final accIndex = _accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIndex != -1) {
      if (tx.type == TransactionType.expense) {
        _accounts[accIndex].balance += tx.amount;
      } else if (tx.type == TransactionType.income) {
        _accounts[accIndex].balance -= tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.toAccountId != null) {
        _accounts[accIndex].balance += tx.amount;
        final toAccIndex = _accounts.indexWhere((a) => a.id == tx.toAccountId);
        if (toAccIndex != -1) {
          _accounts[toAccIndex].balance -= tx.amount;
        }
      }
    }

    _transactions.removeAt(index);
    if (moveToArchive) {
      _archivedTransactions.removeWhere((t) => t.id == tx.id);
      _archivedTransactions.insert(0, tx);
    }
    HapticFeedback.mediumImpact();
    _saveToStorage();
    notifyListeners();
  }

  /// Restores an archived/deleted transaction back to active history,
  /// re-applying its financial balance change to the corresponding account.
  void restoreTransaction(String id) {
    final index = _archivedTransactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final tx = _archivedTransactions[index];

    // Find account to re-apply balance impact
    int accIndex = _accounts.indexWhere((a) => a.id == tx.accountId);
    if (accIndex == -1 && _accounts.isNotEmpty) {
      accIndex = 0; // fallback if account was removed
    }

    if (accIndex != -1) {
      if (tx.type == TransactionType.expense) {
        _accounts[accIndex].balance -= tx.amount;
      } else if (tx.type == TransactionType.income) {
        _accounts[accIndex].balance += tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.toAccountId != null) {
        _accounts[accIndex].balance -= tx.amount;
        final toAccIndex = _accounts.indexWhere((a) => a.id == tx.toAccountId);
        if (toAccIndex != -1) {
          _accounts[toAccIndex].balance += tx.amount;
        }
      }
    }

    _archivedTransactions.removeAt(index);
    _transactions.add(tx);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    HapticFeedback.mediumImpact();
    _saveToStorage();
    notifyListeners();
  }

  /// Permanently removes a transaction from archive (cannot be restored)
  void permanentlyDeleteTransaction(String id) {
    _archivedTransactions.removeWhere((t) => t.id == id);
    HapticFeedback.selectionClick();
    _saveToStorage();
    notifyListeners();
  }

  /// Completely empties the archive of deleted transactions
  void clearArchive() {
    _archivedTransactions.clear();
    HapticFeedback.heavyImpact();
    _saveToStorage();
    notifyListeners();
  }

  // Savings Goals & Winter Arc Streak Actions
  bool depositToGoal({
    required String goalId,
    required double amount,
    required String fromAccountId,
  }) {
    final goalIndex = _savingsGoals.indexWhere((g) => g.id == goalId);
    final accIndex = _accounts.indexWhere((a) => a.id == fromAccountId);
    if (goalIndex == -1 || accIndex == -1) return false;

    // Check if account has sufficient funds
    if (_accounts[accIndex].balance < amount) {
      HapticFeedback.heavyImpact();
      return false;
    }

    _accounts[accIndex].balance -= amount;
    final current = _savingsGoals[goalIndex];
    _savingsGoals[goalIndex] = current.copyWith(
      currentAmount: current.currentAmount + amount,
    );

    _transactions.insert(
      0,
      Transaction(
        id: _generateTxId(),
        title: 'Копилка: ${current.title}',
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_savings',
        accountId: fromAccountId,
        note: 'Пополнение цели',
      ),
    );

    HapticFeedback.mediumImpact();
    _saveToStorage();
    notifyListeners();
    return true;
  }

  void addSavingsGoal({
    required String title,
    required double targetAmount,
    required IconData icon,
    required Color color,
  }) {
    _savingsGoals.add(
      SavingsGoal(
        id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        targetAmount: targetAmount,
        currentAmount: 0.0,
        icon: icon,
        color: color,
        targetDate: DateTime.now().add(const Duration(days: 60)),
      ),
    );
    HapticFeedback.mediumImpact();
    _saveToStorage();
    notifyListeners();
  }

  void incrementStreak() => checkInWinterDay(force: true);

  void duplicateTransaction(Transaction tx) {
    addTransaction(
      title: tx.title,
      amount: tx.amount,
      date: DateTime.now(),
      type: tx.type,
      categoryId: tx.categoryId,
      accountId: tx.accountId,
      toAccountId: tx.toAccountId,
      note: tx.note,
    );
  }

  String getBudgetWarningMessage(
    String categoryId,
    double spent,
    double limit,
  ) {
    if (limit <= 0) return '';
    final pct = spent / limit;
    if (pct < 0.70) return '';
    if (pct <= 1.0) {
      return 'Потрачено ${(pct * 100).toInt()}% месячного лимита. До зарплаты держи темп!';
    }

    // Humorous alert triggers over 100% (Zero emojis rule)
    if (categoryId == 'cat_restaurants') {
      return '«Ормон, хорош заказывать фастфуд, до зарплаты еще далеко!»';
    } else if (categoryId == 'cat_entertainment') {
      return '«Ормон, тусовки подождут — лимит уже трещит по швам!»';
    } else if (categoryId == 'cat_transport') {
      return '«Ормон, пересаживайся на велики или пешком, лимит на такси сгорел!»';
    } else {
      return '«Ормон, лимит превышен! Притормози с лишними тратами!»';
    }
  }

  void executeShortcut(QuickPaymentShortcut shortcut) {
    addTransaction(
      title: shortcut.title,
      amount: shortcut.amount,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: shortcut.categoryId,
      accountId: shortcut.accountId,
      note: 'Быстрый 1-тап платеж',
    );
  }

  // Custom Categories Management
  void addCategory({
    required String name,
    required IconData icon,
    required Color color,
    required TransactionType type,
  }) {
    final newCategory = TransactionCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      color: color,
      type: type,
    );
    _categories.add(newCategory);
    _saveToStorage();
    notifyListeners();
  }

  void deleteCategory(String id) {
    _categories.removeWhere((c) => c.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void _updateQuickShortcutsWithRecentExpense({
    required String title,
    required double amount,
    required String categoryId,
    required String accountId,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty || amount <= 0) return;

    final existingIdx = _quickShortcuts.indexWhere(
      (s) => s.title.toLowerCase().trim() == cleanTitle.toLowerCase(),
    );

    final cat = getCategoryById(categoryId);
    final icon = cat?.icon ?? Icons.bolt_rounded;
    final color = cat?.color ?? const Color(0xFFFF9F0A);

    if (existingIdx != -1) {
      final existing = _quickShortcuts.removeAt(existingIdx);
      _quickShortcuts.insert(
        0,
        existing.copyWith(
          amount: amount,
          categoryId: categoryId,
          accountId: accountId,
          icon: icon,
          color: color,
        ),
      );
    } else {
      _quickShortcuts.insert(
        0,
        QuickPaymentShortcut(
          id: 'q_last_${DateTime.now().millisecondsSinceEpoch}',
          title: cleanTitle,
          amount: amount,
          categoryId: categoryId,
          accountId: accountId,
          icon: icon,
          color: color,
        ),
      );
      if (_quickShortcuts.length > 10) {
        _quickShortcuts = _quickShortcuts.sublist(0, 10);
      }
    }
  }

  // Quick Payment Shortcuts Actions
  void addQuickShortcut({
    required String title,
    required double amount,
    required String categoryId,
    required String accountId,
    required IconData icon,
    required Color color,
  }) {
    final shortcut = QuickPaymentShortcut(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      categoryId: categoryId,
      accountId: accountId,
      icon: icon,
      color: color,
    );
    _quickShortcuts.insert(0, shortcut);
    _saveToStorage();
    notifyListeners();
  }

  void deleteQuickShortcut(String id) {
    _quickShortcuts.removeWhere((q) => q.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void executeQuickShortcut(QuickPaymentShortcut shortcut) {
    addTransaction(
      title: shortcut.title,
      amount: shortcut.amount,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: shortcut.categoryId,
      accountId: shortcut.accountId,
      note: 'Быстрый 1-тап платеж',
    );
  }

  // Recurring Payments Actions
  void addRecurringPayment({
    required String title,
    required double amount,
    required RecurringFrequency frequency,
    required String categoryId,
    required String accountId,
    required DateTime nextDueDate,
    String? note,
    IconData? icon,
  }) {
    final payment = RecurringPayment(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      amount: amount,
      frequency: frequency,
      categoryId: categoryId,
      accountId: accountId,
      nextDueDate: nextDueDate,
      note: note,
      customIcon: icon,
    );
    _recurringPayments.add(payment);
    _saveToStorage();
    notifyListeners();
  }

  void toggleRecurringPayment(String id) {
    final index = _recurringPayments.indexWhere((r) => r.id == id);
    if (index != -1) {
      _recurringPayments[index].isActive = !_recurringPayments[index].isActive;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteRecurringPayment(String id) {
    _recurringPayments.removeWhere((r) => r.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void payRecurringNow(String id) {
    final index = _recurringPayments.indexWhere((r) => r.id == id);
    if (index == -1) return;

    final item = _recurringPayments[index];

    addTransaction(
      title: 'Регулярный платеж: ${item.title}',
      amount: item.amount,
      date: DateTime.now(),
      type: TransactionType.expense,
      categoryId: item.categoryId,
      accountId: item.accountId,
      note: 'Оплата подписки (${item.frequency.label})',
    );

    item.nextDueDate = item.frequency.computeNextDate(item.nextDueDate);
    _saveToStorage();
    notifyListeners();
  }

  // Account & Bank Actions
  void updateAccountBalance(String id, double newBalance) {
    final index = _accounts.indexWhere((a) => a.id == id);
    if (index != -1) {
      _accounts[index].balance = newBalance;
      _saveToStorage();
      notifyListeners();
    }
  }

  void addAccount({
    required String name,
    String bankName = 'Банк',
    String? lastDigits,
    required double initialBalance,
    required AccountType type,
    required Color color,
    String currency = 'сом',
  }) {
    final newAcc = Account(
      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      bankName: bankName,
      lastDigits: lastDigits,
      balance: initialBalance,
      currency: currency,
      type: type,
      color: color,
    );
    _accounts.add(newAcc);
    _saveToStorage();
    notifyListeners();
  }

  void updateBudget(String categoryId, double limit) {
    final index = _budgets.indexWhere((b) => b.categoryId == categoryId);
    if (index != -1) {
      _budgets[index] = _budgets[index].copyWith(monthlyLimit: limit);
    } else {
      _budgets.add(CategoryBudget(categoryId: categoryId, monthlyLimit: limit));
    }
    _saveToStorage();
    notifyListeners();
  }

  // Winter Arc Protocol Logic
  DateTime? _lastWinterCheckInDate;
  int _winterShields = 1;

  DateTime? get lastWinterCheckInDate => _lastWinterCheckInDate;
  int get winterShields => _winterShields;
  int get winterArcTargetDays => 90;
  double get winterArcProgress => (_noSpendStreak / 90.0).clamp(0.0, 1.0);

  bool get isWinterCheckedToday {
    if (_lastWinterCheckInDate == null) return false;
    final now = DateTime.now();
    return _lastWinterCheckInDate!.year == now.year &&
        _lastWinterCheckInDate!.month == now.month &&
        _lastWinterCheckInDate!.day == now.day;
  }

  String get winterArcRankTitle {
    if (_noSpendStreak < 8) return 'Искра (Arc Initiate)';
    if (_noSpendStreak < 22) return 'Холодный фокус (Cold Focus)';
    if (_noSpendStreak < 61) return 'Железная воля (Iron Discipline)';
    return 'Владыка Севера (Winter Master)';
  }

  void checkInWinterDay({bool force = false}) {
    if (force || !isWinterCheckedToday) {
      _noSpendStreak++;
      _lastWinterCheckInDate = DateTime.now();
      _saveToStorage();
      notifyListeners();
    }
  }

  void useWinterShield() {
    if (_winterShields > 0) {
      _winterShields--;
      _lastWinterCheckInDate = DateTime.now();
      _saveToStorage();
      notifyListeners();
    }
  }

  void resetWinterStreak() {
    _noSpendStreak = 0;
    _lastWinterCheckInDate = null;
    HapticFeedback.heavyImpact();
    _saveToStorage();
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _transactions = [];
    _initData();
    _noSpendStreak = 0;
    _lastWinterCheckInDate = null;
    _savingsGoals = [];
    await StorageService.clearAll();
    _saveToStorage();
    notifyListeners();
  }

  // Daily 2-Step Discipline Habit Tracker
  int _dailyDisciplineSteps = 0;
  DateTime? _dailyDisciplineDate;

  int get dailyDisciplineSteps {
    final now = DateTime.now();
    if (_dailyDisciplineDate == null ||
        _dailyDisciplineDate!.year != now.year ||
        _dailyDisciplineDate!.month != now.month ||
        _dailyDisciplineDate!.day != now.day) {
      return 0;
    }
    return _dailyDisciplineSteps;
  }

  bool get isDailyDisciplineComplete => dailyDisciplineSteps >= 2;

  int completeNextDisciplineStep() {
    final now = DateTime.now();
    if (_dailyDisciplineDate == null ||
        _dailyDisciplineDate!.year != now.year ||
        _dailyDisciplineDate!.month != now.month ||
        _dailyDisciplineDate!.day != now.day) {
      _dailyDisciplineSteps = 0;
      _dailyDisciplineDate = now;
    }

    if (_dailyDisciplineSteps < 2) {
      _dailyDisciplineSteps++;
      _dailyDisciplineDate = now;
      if (_dailyDisciplineSteps == 2) {
        checkInWinterDay();
      }
      _saveToStorage();
      notifyListeners();
    }
    return _dailyDisciplineSteps;
  }

  // Capybara Health & Spending-Dependent States (Optimized with high-performance memoization)
  int? _cachedCapybaraHealth;
  DateTime? _lastCapybaraHealthCalcTime;

  void invalidateCapybaraHealthCache() {
    _cachedCapybaraHealth = null;
    _lastCapybaraHealthCalcTime = null;
  }

  int get capybaraHealth {
    final now = DateTime.now();
    if (_cachedCapybaraHealth != null &&
        _lastCapybaraHealthCalcTime != null &&
        now.difference(_lastCapybaraHealthCalcTime!).inMilliseconds < 1500) {
      return _cachedCapybaraHealth!;
    }

    int score = 80;
    // 1. Balance impact
    if (totalBalance <= 0) {
      score -= 45;
    } else if (totalBalance < 1000) {
      score -= 20;
    } else if (totalBalance > 20000) {
      score += 15;
    }

    // 2. Period cash flow (income vs expense)
    if (periodExpense > periodIncome && periodExpense > 0) {
      score -= 25;
    } else if (periodIncome > periodExpense && periodIncome > 0) {
      score += 15;
    }

    // 3. Today's rapid spending impact (single pass, early exit)
    int todayExpenseCount = 0;
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day) {
        todayExpenseCount++;
        if (todayExpenseCount >= 3) {
          score -= 15;
          break;
        }
      }
    }

    // 4. Exceeded category budgets
    if (_budgets.isNotEmpty) {
      for (final b in _budgets) {
        if (b.monthlyLimit <= 0) continue;
        final spent = getCategorySpending(b.categoryId);
        if (spent > b.monthlyLimit) {
          score -= 20;
          break;
        }
      }
    }

    // 5. Discipline & streak bonus
    if (isDailyDisciplineComplete || isWinterCheckedToday) {
      score += 15;
    }
    if (_noSpendStreak >= 7) {
      score += 10;
    }

    final computed = score.clamp(5, 100);
    _cachedCapybaraHealth = computed;
    _lastCapybaraHealthCalcTime = now;
    return computed;
  }

  CapybaraMoodState get capybaraMood {
    final h = capybaraHealth;
    if (h >= 75) return CapybaraMoodState.zenHappy;
    if (h >= 50) return CapybaraMoodState.chillNormal;
    if (h >= 25) return CapybaraMoodState.shockedSpending;
    return CapybaraMoodState.bankruptSad;
  }

  bool get isCapybaraAlertState {
    return capybaraMood == CapybaraMoodState.shockedSpending ||
        capybaraMood == CapybaraMoodState.bankruptSad;
  }

  String get capybaraMoodImagePath {
    switch (capybaraMood) {
      case CapybaraMoodState.zenHappy:
        return 'assets/images/capy_happy.jpg';
      case CapybaraMoodState.chillNormal:
        return 'assets/images/capy_chill.jpg';
      case CapybaraMoodState.shockedSpending:
        return 'assets/images/capy_shocked.jpg';
      case CapybaraMoodState.bankruptSad:
        return 'assets/images/capy_sad.jpg';
    }
  }

  String get capybaraMoodTitle {
    switch (capybaraMood) {
      case CapybaraMoodState.zenHappy:
        return 'Цветущий Дзен';
      case CapybaraMoodState.chillNormal:
        return 'Спокойный Чилл';
      case CapybaraMoodState.shockedSpending:
        return 'В шоке от трат';
      case CapybaraMoodState.bankruptSad:
        return 'Критический дефицит';
    }
  }

  String get capybaraMoodComment {
    switch (capybaraMood) {
      case CapybaraMoodState.zenHappy:
        return 'Баланс в норме, доходы радуют глаз! Капибара вальяжно пьет горный чай в Чон-Кемине и откладывает соточку на мечту.';
      case CapybaraMoodState.chillNormal:
        return 'Финансы стабильны. Капибара напоминает: 25 сом на маршрутке сберегли, теперь главное — не вызвать такси за 260 сом.';
      case CapybaraMoodState.shockedSpending:
        return 'Кто заказал ночной босо-лагман и набрал корзину на маркетплейсе? Капибара в ужасе смотрит на чек и прячет твою карту в морозилку!';
      case CapybaraMoodState.bankruptSad:
        return 'На счетах 0 сом! Капибара питается чистым горным воздухом и тихо спрашивает: где деньги? Срочно закинь на баланс MBank!';
    }
  }

  // Dream Savings ("Деньги на мечту")
  void depositToDreamGoal(double amount, {String? accountId}) {
    if (_savingsGoals.isEmpty) {
      final now = DateTime.now();
      _savingsGoals.add(
        SavingsGoal(
          id: 'goal_dream',
          title: 'Моя мечта',
          targetAmount: 50000.0,
          currentAmount: 0.0,
          icon: Icons.star_rounded,
          color: const Color(0xFF0A84FF),
          targetDate: DateTime(now.year, now.month + 3, 1),
        ),
      );
    }

    final targetAccId =
        accountId ?? (_accounts.isNotEmpty ? _accounts.first.id : '');
    final goal = _savingsGoals.first;
    final updated = goal.copyWith(currentAmount: goal.currentAmount + amount);
    _savingsGoals[0] = updated;

    if (targetAccId.isNotEmpty) {
      addTransaction(
        title: 'Отложено на мечту: ${goal.title}',
        amount: amount,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_other',
        accountId: targetAccId,
        note: 'Пополнение копилки мечты',
      );
    }
    notifyListeners();
  }

  void _initData() {
    _categories = List.from(TransactionCategory.defaultCategories);
    _currencyRates = List.from(CurrencyRate.defaultRates);

    // Initial Banks / Accounts (clean start requested by user)
    _accounts = [
      Account(
        id: 'acc_mbank',
        name: 'MBank',
        bankName: 'MBank',
        lastDigits: '4820',
        balance: 0.0,
        currency: 'сом',
        type: AccountType.card,
        color: const Color(0xFF0A84FF),
      ),
    ];

    // Quick Payment Shortcuts
    _quickShortcuts = [
      const QuickPaymentShortcut(
        id: 'q_transport_van',
        title: 'Маршрутка',
        amount: 25.0,
        categoryId: 'cat_transport',
        accountId: 'acc_mbank',
        icon: Icons.airport_shuttle_rounded,
        color: Color(0xFF0A84FF),
      ),
      const QuickPaymentShortcut(
        id: 'q_coffee',
        title: 'Кофе',
        amount: 150.0,
        categoryId: 'cat_restaurants',
        accountId: 'acc_mbank',
        icon: Icons.coffee_rounded,
        color: Color(0xFFFF9F0A),
      ),
    ];

    _budgets = [
      const CategoryBudget(categoryId: 'cat_groceries', monthlyLimit: 30000.0),
      const CategoryBudget(
        categoryId: 'cat_restaurants',
        monthlyLimit: 15000.0,
      ),
      const CategoryBudget(categoryId: 'cat_transport', monthlyLimit: 5000.0),
    ];

    final now = DateTime.now();

    _savingsGoals = [
      SavingsGoal(
        id: 'goal_dream',
        title: 'Моя мечта',
        targetAmount: 50000.0,
        currentAmount: 0.0,
        icon: Icons.star_rounded,
        color: const Color(0xFF0A84FF),
        targetDate: DateTime(now.year, now.month + 3, 1),
      ),
    ];

    // Recurring payments / Subscriptions
    _recurringPayments = [
      RecurringPayment(
        id: 'rec_yandex',
        title: 'Яндекс',
        amount: 200.0,
        frequency: RecurringFrequency.monthly,
        categoryId: 'cat_entertainment',
        accountId: 'acc_mbank',
        nextDueDate: DateTime(now.year, now.month, now.day + 15),
      ),
    ];

    // Clean transactions list to start from scratch
    _transactions = [];
    _archivedTransactions = [];
  }

  bool _isStorageLoaded = false;
  bool get isStorageLoaded => _isStorageLoaded;

  Future<void> loadFromStorage() async {
    final data = await StorageService.loadAll();
    if (data != null) {
      if (data['accounts'] != null && (data['accounts'] as List).isNotEmpty) {
        _accounts = List<Account>.from(data['accounts']);
      }
      if (data['transactions'] != null) {
        _transactions = List<Transaction>.from(data['transactions']);
      }
      if (data['archivedTransactions'] != null) {
        _archivedTransactions = List<Transaction>.from(data['archivedTransactions']);
      }
      if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
        _categories = List<TransactionCategory>.from(data['categories']);
      }
      if (data['budgets'] != null && (data['budgets'] as List).isNotEmpty) {
        _budgets = List<CategoryBudget>.from(data['budgets']);
      }
      if (data['savingsGoals'] != null &&
          (data['savingsGoals'] as List).isNotEmpty) {
        _savingsGoals = List<SavingsGoal>.from(data['savingsGoals']);
      }
      if (data['recurringPayments'] != null &&
          (data['recurringPayments'] as List).isNotEmpty) {
        _recurringPayments = List<RecurringPayment>.from(
          data['recurringPayments'],
        );
      }
      if (data['shortcuts'] != null && (data['shortcuts'] as List).isNotEmpty) {
        _quickShortcuts = List<QuickPaymentShortcut>.from(data['shortcuts']);
      }
      if (data['noSpendStreak'] != null) {
        _noSpendStreak = data['noSpendStreak'] as int;
      }
      if (data.containsKey('lastWinterCheckInDate')) {
        _lastWinterCheckInDate = data['lastWinterCheckInDate'] as DateTime?;
      }
      if (data['winterShields'] != null) {
        _winterShields = data['winterShields'] as int;
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _smartRoundUpEnabled = prefs.getBool('arc_smart_round_up_enabled') ??
          prefs.getBool('rounding_enabled') ??
          false;
      _smartRoundUpStep = prefs.getInt('arc_smart_round_up_step') ?? 100;
      _capybaraFilterEnabled = prefs.getBool('arc_capybara_filter_enabled') ?? false;
      _floatingCapyEnabled = prefs.getBool('arc_floating_capy_enabled') ?? false;
      _capybaraWidgetEnabled = prefs.getBool('arc_capybara_widget_enabled') ?? true;
    } catch (_) {}

    _isStorageLoaded = true;
    notifyListeners();

    // If initial first boot on fresh device, persist default data
    if (data == null) {
      _saveToStorage();
    }

    // Immediately keep Android native widgets up to date with loaded data
    WidgetLaunchService.syncBalanceToWidget(
      totalBalance,
      streak: _noSpendStreak,
      isWinterChecked: isWinterCheckedToday,
      accountName: activeAccountLabel,
      todaySpent: todaySpentLabel,
      quickButtons: quickButtonsForWidget,
    );
  }

  double get todayExpense {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            t.date.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  String get todaySpentLabel {
    final exp = todayExpense;
    if (exp <= 0.0) {
      return 'Сегодня: без спонтанных трат';
    }
    return 'Сегодня: −${CurrencyFormatter.format(exp)}';
  }

  bool addMBankAutoTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    String? categoryId,
    String? note,
    double? balanceAfter,
    bool isBalanceOnly = false,
  }) {
    // Find MBank account or first card account
    final mbankIndex = _accounts.indexWhere(
      (a) => a.bankName.toLowerCase().contains('mbank') || a.id == 'acc_mbank',
    );
    final String targetAccountId = mbankIndex != -1
        ? _accounts[mbankIndex].id
        : (_accounts.isNotEmpty ? _accounts.first.id : 'acc_mbank');

    // Если это информационный пуш/экран только с балансом (без операции)
    if (isBalanceOnly) {
      if (balanceAfter != null && balanceAfter > 0 && mbankIndex != -1) {
        final currentBal = _accounts[mbankIndex].balance;
        if ((currentBal - balanceAfter).abs() > 0.01) {
          _accounts[mbankIndex] = _accounts[mbankIndex].copyWith(balance: balanceAfter);
          invalidateCapybaraHealthCache();
          _saveToStorage();
          notifyListeners();
          debugPrint('[FinanceController] Balance-only update: $balanceAfter сом (было $currentBal)');
        }
      }
      return false;
    }

    // Игнорируем нулевые или ошибочные суммы из истории/экрана
    if (amount <= 0) {
      debugPrint('[FinanceController] Skipped zero-amount bank notification: $title');
      if (balanceAfter != null && balanceAfter > 0 && mbankIndex != -1) {
        _accounts[mbankIndex] = _accounts[mbankIndex].copyWith(balance: balanceAfter);
        _saveToStorage();
        notifyListeners();
      }
      return false;
    }

    // Защита от дубликатов (например экран чека + пуш)
    final now = DateTime.now();
    final hasRecentDuplicate = _transactions.any((tx) {
      final isSameAmount = (tx.amount - amount).abs() < 0.01;
      final isSameType = tx.type == type;
      if (!isSameAmount || !isSameType) return false;

      if (now.difference(tx.date).inSeconds.abs() < 3600) {
        return true;
      }

      final isSameDay = tx.date.year == now.year &&
          tx.date.month == now.month &&
          tx.date.day == now.day;
      if (isSameDay) {
        final t1 = tx.title.toLowerCase().trim();
        final t2 = title.toLowerCase().trim();
        if (t1 == t2 ||
            t1.contains(t2) ||
            t2.contains(t1) ||
            (tx.note?.contains('MBank') == true && (note?.contains('MBank') == true))) {
          return true;
        }
      }
      return false;
    });

    if (hasRecentDuplicate) {
      debugPrint('[FinanceController] Deduplication: ignored duplicate bank transaction: $title ($amount сом)');
      if (balanceAfter != null && balanceAfter > 0 && mbankIndex != -1) {
        _accounts[mbankIndex] = _accounts[mbankIndex].copyWith(balance: balanceAfter);
        _saveToStorage();
        notifyListeners();
      }
      return false;
    }

    final catId = categoryId ??
        (type == TransactionType.income ? 'cat_salary' : 'cat_other');

    addTransaction(
      title: title,
      amount: amount,
      date: DateTime.now(),
      type: type,
      categoryId: catId,
      accountId: targetAccountId,
      note: note ?? 'Автоматически из уведомления MBank',
      isAutoBank: true,
    );

    // Если банк четко указал остаток на счете, он является источником правды
    if (balanceAfter != null && balanceAfter > 0) {
      final targetIdx = mbankIndex != -1 ? mbankIndex : (_accounts.isNotEmpty ? 0 : -1);
      if (targetIdx != -1) {
        _accounts[targetIdx] = _accounts[targetIdx].copyWith(balance: balanceAfter);
        invalidateCapybaraHealthCache();
        _saveToStorage();
        notifyListeners();
      }
    }
    return true;
  }
  bool updateScrapedBankBalance(String bankName, double newBalance) {
    if (!_isStorageLoaded) return false;
    if (newBalance <= 0) return false;
    final lower = bankName.toLowerCase();
    int idx = _accounts.indexWhere((a) => a.bankName.toLowerCase().contains(lower));
    if (idx == -1 && lower.contains('mbank')) {
      idx = _accounts.indexWhere((a) => a.id == 'acc_mbank');
    }
    // Fallback: If bank is MBank/primary card and user renamed account, use primary card account
    if (idx == -1 && _accounts.isNotEmpty) {
      final cardIdx = _accounts.indexWhere((a) => a.type == AccountType.card);
      idx = cardIdx != -1 ? cardIdx : 0;
    }
    if (idx == -1) return false;

    // Update account balance directly with authoritative balance from bank screen
    _accounts[idx] = _accounts[idx].copyWith(balance: newBalance);
    _saveToStorage();
    WidgetLaunchService.syncBalanceToWidget(
      totalBalance,
      streak: _noSpendStreak,
      isWinterChecked: isWinterCheckedToday,
      accountName: activeAccountLabel,
      todaySpent: todaySpentLabel,
      quickButtons: quickButtonsForWidget,
    );
    notifyListeners();
    return true;
  }

  Future<void> saveToStorage() async {
    _saveToStorage();
  }

  Timer? _saveDebounceTimer;

  void _saveToStorage({bool immediate = false}) {
    if (!_isStorageLoaded) {
      debugPrint('[FinanceController] Skipping saveToStorage: storage not loaded yet');
      return;
    }

    void executeSave() {
      try {
        StorageService.saveAll(
          accounts: _accounts,
          transactions: _transactions,
          archivedTransactions: _archivedTransactions,
          categories: _categories,
          budgets: _budgets,
          savingsGoals: _savingsGoals,
          recurringPayments: _recurringPayments,
          shortcuts: _quickShortcuts,
          noSpendStreak: _noSpendStreak,
          lastWinterCheckInDate: _lastWinterCheckInDate,
          winterShields: _winterShields,
        );
        WidgetLaunchService.syncBalanceToWidget(
          totalBalance,
          streak: noSpendStreak,
          isWinterChecked: isWinterCheckedToday,
          accountName: activeAccountLabel,
          todaySpent: todaySpentLabel,
          quickButtons: quickButtonsForWidget,
        );

        // Sync active dream goal & threshold to Android Capybara Pre-Transaction filter
        final dreamGoal = _savingsGoals.isNotEmpty ? _savingsGoals.first.title : 'MacBook Pro M3';
        final remaining = _savingsGoals.isNotEmpty
            ? (_savingsGoals.first.targetAmount - _savingsGoals.first.currentAmount).clamp(0.0, 99999999.0)
            : 120000.0;
        WidgetLaunchService.syncCapybaraFilterConfig(
          enabled: _capybaraFilterEnabled,
          threshold: 500.0,
          dreamGoal: dreamGoal,
          remainingGoal: remaining,
        );
        WidgetLaunchService.syncFloatingCapyConfig(
          enabled: _floatingCapyEnabled,
        );

        final hasActivePenalty = _activeWorkoutPenalty != null && !_activeWorkoutPenalty!.isCompleted;
        WidgetLaunchService.syncSocialBlockerConfig(
          enabled: true,
          isBlocked: hasActivePenalty,
          dreamGoal: dreamGoal,
          pullupsRequired: 20,
        );

        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('arc_smart_round_up_enabled', _smartRoundUpEnabled);
          prefs.setBool('rounding_enabled', _smartRoundUpEnabled);
          prefs.setInt('arc_smart_round_up_step', _smartRoundUpStep);
          prefs.setBool('arc_capybara_filter_enabled', _capybaraFilterEnabled);
          prefs.setBool('arc_floating_capy_enabled', _floatingCapyEnabled);
          prefs.setBool('arc_capybara_widget_enabled', _capybaraWidgetEnabled);
        }).catchError((_) {});
      } catch (e) {
        debugPrint('[FinanceController] Error saving to storage: $e');
      }
    }

    if (immediate) {
      _saveDebounceTimer?.cancel();
      executeSave();
    } else {
      _saveDebounceTimer?.cancel();
      // 90ms micro-debounce frees the current UI animation frame completely!
      _saveDebounceTimer = Timer(const Duration(milliseconds: 90), executeSave);
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }
}
