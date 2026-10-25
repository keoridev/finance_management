import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/quick_payment_shortcut.dart';
import '../models/recurring_payment.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';
import 'database_service.dart';

class StorageService {
  static const String _keyAccounts = 'arc_accounts_v1';
  static const String _keyTransactions = 'arc_transactions_v1';
  static const String _keyCategories = 'arc_categories_v1';
  static const String _keyBudgets = 'arc_budgets_v1';
  static const String _keySavingsGoals = 'arc_savings_goals_v1';
  static const String _keyRecurring = 'arc_recurring_v1';
  static const String _keyShortcuts = 'arc_shortcuts_v1';
  static const String _keyWinterArc = 'arc_winter_protocol_v1';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save all financial state asynchronously to SQLite with ACID transaction,
  /// and mirror summary flags to SharedPreferences for Android Home Widgets.
  static Future<void> saveAll({
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<TransactionCategory> categories,
    required List<CategoryBudget> budgets,
    required List<SavingsGoal> savingsGoals,
    required List<RecurringPayment> recurringPayments,
    required List<QuickPaymentShortcut> shortcuts,
    required int noSpendStreak,
    required DateTime? lastWinterCheckInDate,
    required int winterShields,
  }) async {
    try {
      // 1. Primary persistence: ACID SQLite WAL database
      await DatabaseService.instance.saveFullState(
        accounts: accounts,
        transactions: transactions,
        categories: categories,
        budgets: budgets,
        savingsGoals: savingsGoals,
        recurringPayments: recurringPayments,
        shortcuts: shortcuts,
        noSpendStreak: noSpendStreak,
        lastWinterCheckInDate: lastWinterCheckInDate,
        winterShields: winterShields,
      );

      // 2. Secondary fail-safe mirror: Real-time mirror to SharedPreferences
      try {
        final prefs = await _getPrefs();
        final accList = accounts.map((a) => {
          'id': a.id,
          'name': a.name,
          'bankName': a.bankName,
          'lastDigits': a.lastDigits,
          'balance': a.balance,
          'currency': a.currency,
          'type': a.type.index,
          'color': a.color.toARGB32(),
        }).toList();

        final txList = transactions.map((t) => {
          'id': t.id,
          'title': t.title,
          'amount': t.amount,
          'date': t.date.toIso8601String(),
          'type': t.type.index,
          'categoryId': t.categoryId,
          'accountId': t.accountId,
          'toAccountId': t.toAccountId,
          'note': t.note,
        }).toList();

        final catList = categories.map((c) => {
          'id': c.id,
          'name': c.name,
          'icon': c.icon.codePoint,
          'color': c.color.toARGB32(),
          'type': c.type.index,
        }).toList();

        final budList = budgets.map((b) => {
          'categoryId': b.categoryId,
          'monthlyLimit': b.monthlyLimit,
        }).toList();

        final goalList = savingsGoals.map((g) => {
          'id': g.id,
          'title': g.title,
          'targetAmount': g.targetAmount,
          'currentAmount': g.currentAmount,
          'icon': g.icon.codePoint,
          'color': g.color.toARGB32(),
          'targetDate': g.targetDate.toIso8601String(),
        }).toList();

        final recList = recurringPayments.map((r) => {
          'id': r.id,
          'title': r.title,
          'amount': r.amount,
          'frequency': r.frequency.index,
          'categoryId': r.categoryId,
          'accountId': r.accountId,
          'nextDueDate': r.nextDueDate.toIso8601String(),
          'isActive': r.isActive,
          'note': r.note,
        }).toList();

        final shortList = shortcuts.map((s) => {
          'id': s.id,
          'title': s.title,
          'amount': s.amount,
          'categoryId': s.categoryId,
          'accountId': s.accountId,
          'icon': s.icon.codePoint,
          'color': s.color.toARGB32(),
        }).toList();

        await prefs.setString(_keyAccounts, jsonEncode(accList));
        await prefs.setString(_keyTransactions, jsonEncode(txList));
        await prefs.setString(_keyCategories, jsonEncode(catList));
        await prefs.setString(_keyBudgets, jsonEncode(budList));
        await prefs.setString(_keySavingsGoals, jsonEncode(goalList));
        await prefs.setString(_keyRecurring, jsonEncode(recList));
        await prefs.setString(_keyShortcuts, jsonEncode(shortList));
        await prefs.setInt('arc_widget_winter_streak', noSpendStreak);
        await prefs.setString(_keyWinterArc, jsonEncode({
          'noSpendStreak': noSpendStreak,
          'lastCheckIn': lastWinterCheckInDate?.toIso8601String(),
          'winterShields': winterShields,
        }));
        await prefs.setInt('arc_winter_shields_v1', winterShields);
        if (lastWinterCheckInDate != null) {
          await prefs.setString('arc_winter_last_checkin_v1', lastWinterCheckInDate.toIso8601String());
        }

        final isToday = lastWinterCheckInDate != null &&
            lastWinterCheckInDate.year == DateTime.now().year &&
            lastWinterCheckInDate.month == DateTime.now().month &&
            lastWinterCheckInDate.day == DateTime.now().day;
        await prefs.setBool('arc_widget_winter_checked', isToday);
      } catch (e) {
        debugPrint('[StorageService] SharedPreferences mirror warning: $e');
      }
    } catch (e) {
      debugPrint('[StorageService] Critical error in saveAll: $e');
    }
  }

  /// Load state from SQLite. If SQLite is empty, check and migrate legacy SharedPreferences.
  static Future<Map<String, dynamic>?> loadAll() async {
    try {
      // 1. Try loading from SQLite first
      final dbState = await DatabaseService.instance.loadFullState();
      if (dbState != null &&
          ((dbState['accounts'] != null && (dbState['accounts'] as List).isNotEmpty) ||
           (dbState['transactions'] != null && (dbState['transactions'] as List).isNotEmpty) ||
           dbState.containsKey('noSpendStreak'))) {
        return dbState;
      }

      // 2. If SQLite is brand new, check if legacy SharedPreferences has data to migrate
      final legacyData = await _loadLegacySharedPreferences();
      if (legacyData != null) {
        debugPrint('[StorageService] Migrating legacy SharedPreferences data to SQLite...');
        await DatabaseService.instance.saveFullState(
          accounts: List<Account>.from(legacyData['accounts'] ?? []),
          transactions: List<Transaction>.from(legacyData['transactions'] ?? []),
          categories: List<TransactionCategory>.from(legacyData['categories'] ?? []),
          budgets: List<CategoryBudget>.from(legacyData['budgets'] ?? []),
          savingsGoals: List<SavingsGoal>.from(legacyData['savingsGoals'] ?? []),
          recurringPayments: List<RecurringPayment>.from(legacyData['recurringPayments'] ?? []),
          shortcuts: List<QuickPaymentShortcut>.from(legacyData['shortcuts'] ?? []),
          noSpendStreak: legacyData['noSpendStreak'] as int? ?? 0,
          lastWinterCheckInDate: legacyData['lastWinterCheckInDate'] as DateTime?,
          winterShields: legacyData['winterShields'] as int? ?? 1,
        );
        return legacyData;
      }

      return null; // Truly first launch, controller will use fresh defaults
    } catch (e) {
      debugPrint('[StorageService] Critical error in loadAll: $e');
      return await _loadLegacySharedPreferences();
    }
  }

  /// Internal loader for migrating older SharedPreferences data
  static Future<Map<String, dynamic>?> _loadLegacySharedPreferences() async {
    try {
      final prefs = await _getPrefs();
      if (!prefs.containsKey(_keyAccounts) &&
          !prefs.containsKey(_keyTransactions) &&
          !prefs.containsKey(_keyWinterArc) &&
          !prefs.containsKey('arc_widget_winter_streak')) {
        return null;
      }

      final result = <String, dynamic>{};

      // Accounts
      final accountsRaw = prefs.getString(_keyAccounts);
      if (accountsRaw != null && accountsRaw.isNotEmpty) {
        final List list = jsonDecode(accountsRaw);
        result['accounts'] = list.map((m) {
          final typeIndex = (m['type'] as num?)?.toInt() ?? 0;
          final colorInt = (m['color'] as num?)?.toInt() ?? 0xFF0A84FF;
          return Account(
            id: m['id'] as String? ?? 'acc_mbank',
            name: m['name'] as String? ?? 'MBank',
            bankName: m['bankName'] as String? ?? 'MBank',
            lastDigits: m['lastDigits'] as String?,
            balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
            currency: m['currency'] as String? ?? 'сом',
            type: AccountType.values[typeIndex.clamp(0, AccountType.values.length - 1)],
            color: Color(colorInt),
          );
        }).toList();
      }

      // Transactions
      final txRaw = prefs.getString(_keyTransactions);
      if (txRaw != null && txRaw.isNotEmpty) {
        final List list = jsonDecode(txRaw);
        result['transactions'] = list.map((m) {
          final typeIndex = (m['type'] as num?)?.toInt() ?? 0;
          DateTime txDate = DateTime.now();
          if (m['date'] is int) {
            txDate = DateTime.fromMillisecondsSinceEpoch(m['date'] as int);
          } else if (m['date'] is String) {
            txDate = DateTime.tryParse(m['date'] as String) ?? DateTime.now();
          }
          return Transaction(
            id: m['id'] as String? ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
            title: m['title'] as String? ?? 'Операция',
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            date: txDate,
            type: TransactionType.values[typeIndex.clamp(0, TransactionType.values.length - 1)],
            categoryId: m['categoryId'] as String? ?? 'cat_other',
            accountId: m['accountId'] as String? ?? 'acc_mbank',
            toAccountId: m['toAccountId'] as String?,
            note: m['note'] as String?,
          );
        }).toList();
      }

      // Categories
      final catRaw = prefs.getString(_keyCategories);
      if (catRaw != null && catRaw.isNotEmpty) {
        final List list = jsonDecode(catRaw);
        result['categories'] = list.map((m) {
          final typeIndex = (m['type'] as num?)?.toInt() ?? 0;
          final iconCode = (m['icon'] as num?)?.toInt() ?? 0xe577;
          final colorInt = (m['color'] as num?)?.toInt() ?? 0xFF0A84FF;
          return TransactionCategory(
            id: m['id'] as String? ?? 'cat_custom',
            name: m['name'] as String? ?? 'Категория',
            icon: DatabaseService.iconFromCode(iconCode),
            color: Color(colorInt),
            type: TransactionType.values[typeIndex.clamp(0, TransactionType.values.length - 1)],
          );
        }).toList();
      }

      // Budgets
      final budgetRaw = prefs.getString(_keyBudgets);
      if (budgetRaw != null && budgetRaw.isNotEmpty) {
        final List list = jsonDecode(budgetRaw);
        result['budgets'] = list.map((m) => CategoryBudget(
          categoryId: m['categoryId'] as String? ?? '',
          monthlyLimit: (m['monthlyLimit'] as num?)?.toDouble() ?? 0.0,
        )).toList();
      }

      // Savings Goals
      final savingsRaw = prefs.getString(_keySavingsGoals);
      if (savingsRaw != null && savingsRaw.isNotEmpty) {
        final List list = jsonDecode(savingsRaw);
        result['savingsGoals'] = list.map((m) {
          final iconCode = (m['icon'] as num?)?.toInt() ?? 0xe577;
          final colorInt = (m['color'] as num?)?.toInt() ?? 0xFF0A84FF;
          DateTime gDate = DateTime.now();
          if (m['targetDate'] is int) {
            gDate = DateTime.fromMillisecondsSinceEpoch(m['targetDate'] as int);
          } else if (m['targetDate'] is String) {
            gDate = DateTime.tryParse(m['targetDate'] as String) ?? DateTime.now();
          }
          return SavingsGoal(
            id: m['id'] as String? ?? 'goal_dream',
            title: m['title'] as String? ?? 'Моя цель',
            targetAmount: (m['targetAmount'] as num?)?.toDouble() ?? 10000.0,
            currentAmount: (m['currentAmount'] as num?)?.toDouble() ?? 0.0,
            icon: DatabaseService.iconFromCode(iconCode),
            color: Color(colorInt),
            targetDate: gDate,
          );
        }).toList();
      }

      // Recurring
      final recRaw = prefs.getString(_keyRecurring);
      if (recRaw != null && recRaw.isNotEmpty) {
        final List list = jsonDecode(recRaw);
        result['recurringPayments'] = list.map((m) {
          final freqIndex = (m['frequency'] as num?)?.toInt() ?? 2;
          DateTime rDate = DateTime.now();
          if (m['nextDueDate'] is int) {
            rDate = DateTime.fromMillisecondsSinceEpoch(m['nextDueDate'] as int);
          } else if (m['nextDueDate'] is String) {
            rDate = DateTime.tryParse(m['nextDueDate'] as String) ?? DateTime.now();
          }
          return RecurringPayment(
            id: m['id'] as String? ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
            title: m['title'] as String? ?? 'Подписка',
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            frequency: RecurringFrequency.values[freqIndex.clamp(0, RecurringFrequency.values.length - 1)],
            categoryId: m['categoryId'] as String? ?? 'cat_entertainment',
            accountId: m['accountId'] as String? ?? 'acc_mbank',
            nextDueDate: rDate,
            isActive: m['isActive'] as bool? ?? true,
            note: m['note'] as String?,
          );
        }).toList();
      }

      // Shortcuts
      final shortRaw = prefs.getString(_keyShortcuts);
      if (shortRaw != null && shortRaw.isNotEmpty) {
        final List list = jsonDecode(shortRaw);
        result['shortcuts'] = list.map((m) {
          final iconCode = (m['icon'] as num?)?.toInt() ?? 0xe577;
          final colorInt = (m['color'] as num?)?.toInt() ?? 0xFFFF9F0A;
          return QuickPaymentShortcut(
            id: m['id'] as String? ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
            title: m['title'] as String? ?? 'Быстрый платеж',
            amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
            categoryId: m['categoryId'] as String? ?? 'cat_transport',
            accountId: m['accountId'] as String? ?? 'acc_mbank',
            icon: DatabaseService.iconFromCode(iconCode),
            color: Color(colorInt),
          );
        }).toList();
      }

      // Winter Arc
      final winterVal = prefs.get(_keyWinterArc);
      if (winterVal is String && winterVal.isNotEmpty) {
        try {
          final Map<String, dynamic> map = jsonDecode(winterVal);
          result['noSpendStreak'] = (map['noSpendStreak'] as num?)?.toInt() ?? 0;
          final lastStr = map['lastCheckIn'] as String?;
          result['lastWinterCheckInDate'] = lastStr != null ? DateTime.tryParse(lastStr) : null;
          result['winterShields'] = (map['winterShields'] as num?)?.toInt() ?? 1;
        } catch (_) {
          result['noSpendStreak'] = int.tryParse(winterVal) ?? 0;
        }
      } else if (winterVal is int) {
        result['noSpendStreak'] = winterVal;
      } else {
        final legacyStreak = prefs.getInt('arc_widget_winter_streak');
        if (legacyStreak != null) {
          result['noSpendStreak'] = legacyStreak;
          final legacyChecked = prefs.getBool('arc_widget_winter_checked') ?? false;
          if (legacyChecked) {
            result['lastWinterCheckInDate'] = DateTime.now();
          }
        }
      }

      if (prefs.containsKey('arc_winter_shields_v1')) {
        result['winterShields'] = prefs.getInt('arc_winter_shields_v1') ?? 1;
      }
      if (prefs.containsKey('arc_winter_last_checkin_v1')) {
        final str = prefs.getString('arc_winter_last_checkin_v1');
        if (str != null) {
          result['lastWinterCheckInDate'] = DateTime.tryParse(str);
        }
      }

      return result;
    } catch (e) {
      debugPrint('[StorageService] Error loading legacy preferences: $e');
      return null;
    }
  }

  /// Export complete data backup to JSON
  static Future<String> exportBackup() async {
    return await DatabaseService.instance.exportBackupJson();
  }

  /// Import complete data backup from JSON
  static Future<bool> importBackup(String jsonString) async {
    return await DatabaseService.instance.importBackupJson(jsonString);
  }

  /// Total recorded transactions
  static Future<int> getTransactionCount() async {
    return await DatabaseService.instance.getTransactionCount();
  }

  /// Database size in bytes
  static Future<int> getDatabaseSizeBytes() async {
    return await DatabaseService.instance.getDatabaseSizeBytes();
  }

  /// Reset all stored data across SQLite and SharedPreferences
  static Future<void> clearAll() async {
    try {
      await DatabaseService.instance.clearAll();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTransactions);
      await prefs.remove(_keyAccounts);
      await prefs.remove(_keyCategories);
      await prefs.remove(_keyBudgets);
      await prefs.remove(_keySavingsGoals);
      await prefs.remove(_keyRecurring);
      await prefs.remove(_keyShortcuts);
      await prefs.remove(_keyWinterArc);
      await prefs.remove('arc_widget_balance');
      await prefs.remove('arc_widget_winter_streak');
      await prefs.remove('arc_widget_winter_checked');
    } catch (_) {}
  }
}
