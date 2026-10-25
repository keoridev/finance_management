import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../models/account.dart';
import '../models/category_budget.dart';
import '../models/quick_payment_shortcut.dart';
import '../models/recurring_payment.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/transaction_category.dart';
import '../models/transaction_type.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  static const String dbName = 'arc_finance_v2.db';
  static const int dbVersion = 1;

  Database? _db;

  /// In-memory DB hook specifically for headless unit tests
  static DatabaseFactory? mockDatabaseFactory;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      if (mockDatabaseFactory != null) {
        return await mockDatabaseFactory!.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(
            version: dbVersion,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
          ),
        );
      }

      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, dbName);

      return await openDatabase(
        path,
        version: dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    } catch (e) {
      debugPrint('[DatabaseService] Failed to open standard DB, falling back to memory DB: $e');
      return await openDatabase(
        inMemoryDatabasePath,
        version: dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      );
    }
  }

  static Future<void> _onConfigure(Database db) async {
    try {
      // Enable WAL (Write-Ahead Logging) for lightning fast commits and durability
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (_) {}
  }

  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Accounts Table
    batch.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        last_digits TEXT,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'сом',
        type INTEGER NOT NULL DEFAULT 0,
        color INTEGER NOT NULL DEFAULT 4278854911
      )
    ''');

    // 2. Transactions Table
    batch.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        type INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        note TEXT
      )
    ''');
    batch.execute('CREATE INDEX idx_tx_date ON transactions(date DESC)');
    batch.execute('CREATE INDEX idx_tx_account ON transactions(account_id)');
    batch.execute('CREATE INDEX idx_tx_category ON transactions(category_id)');

    // 3. Categories Table
    batch.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL,
        type INTEGER NOT NULL
      )
    ''');

    // 4. Budgets Table
    batch.execute('''
      CREATE TABLE budgets (
        category_id TEXT PRIMARY KEY,
        monthly_limit REAL NOT NULL
      )
    ''');

    // 5. Savings Goals Table
    batch.execute('''
      CREATE TABLE savings_goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0.0,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL,
        target_date INTEGER NOT NULL
      )
    ''');

    // 6. Recurring Payments Table
    batch.execute('''
      CREATE TABLE recurring_payments (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        frequency INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        next_due_date INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        note TEXT
      )
    ''');

    // 7. Quick Shortcuts Table
    batch.execute('''
      CREATE TABLE shortcuts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        icon INTEGER NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    // 8. Key-Value Meta Store (Winter Arc streak, timestamps, flags)
    batch.execute('''
      CREATE TABLE meta_kv (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await batch.commit(noResult: true);
  }

  // Helper icon converter
  static IconData iconFromCode(int code) {
    switch (code) {
      case 0xe577:
      case 0xf016e:
        return Icons.savings_rounded;
      case 0xe1d7:
      case 0xe227:
        return Icons.directions_car_rounded;
      case 0xe2a8:
        return Icons.flight_takeoff_rounded;
      case 0xe35b:
        return Icons.home_rounded;
      case 0xe3af:
        return Icons.laptop_mac_rounded;
      case 0xe4d8:
        return Icons.phone_iphone_rounded;
      case 0xe25b:
        return Icons.favorite_rounded;
      case 0xe5f9:
        return Icons.star_rounded;
      case 0xe072:
        return Icons.airport_shuttle_rounded;
      case 0xe188:
        return Icons.coffee_rounded;
      case 0xe59c:
        return Icons.shopping_bag_rounded;
      case 0xe3c6:
        return Icons.local_grocery_store_rounded;
      case 0xe25a:
        return Icons.fastfood_rounded;
      case 0xe506:
        return Icons.receipt_long_rounded;
      case 0xe144:
        return Icons.school_rounded;
      case 0xe28e:
        return Icons.fitness_center_rounded;
      case 0xe43f:
        return Icons.medical_services_rounded;
      case 0xe0b2:
        return Icons.beach_access_rounded;
      case 0xe060:
        return Icons.account_balance_wallet_rounded;
      case 0xe19f:
        return Icons.credit_card_rounded;
      case 0xe481:
        return Icons.payments_rounded;
      case 0xe679:
        return Icons.trending_up_rounded;
      default:
        for (final cat in TransactionCategory.defaultCategories) {
          if (cat.icon.codePoint == code) return cat.icon;
        }
        return Icons.category_rounded;
    }
  }

  /// Atomic full save with SQLite batch transaction
  Future<void> saveFullState({
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
    final db = await database;

    await db.transaction((txn) async {
      // 1. Accounts
      await txn.delete('accounts');
      final batchAcc = txn.batch();
      for (final a in accounts) {
        batchAcc.insert('accounts', {
          'id': a.id,
          'name': a.name,
          'bank_name': a.bankName,
          'last_digits': a.lastDigits,
          'balance': a.balance,
          'currency': a.currency,
          'type': a.type.index,
          'color': a.color.toARGB32(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchAcc.commit(noResult: true);

      // 2. Transactions
      await txn.delete('transactions');
      final batchTx = txn.batch();
      for (final t in transactions) {
        batchTx.insert('transactions', {
          'id': t.id,
          'title': t.title,
          'amount': t.amount,
          'date': t.date.millisecondsSinceEpoch,
          'type': t.type.index,
          'category_id': t.categoryId,
          'account_id': t.accountId,
          'to_account_id': t.toAccountId,
          'note': t.note,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchTx.commit(noResult: true);

      // 3. Categories
      await txn.delete('categories');
      final batchCat = txn.batch();
      for (final c in categories) {
        batchCat.insert('categories', {
          'id': c.id,
          'name': c.name,
          'icon': c.icon.codePoint,
          'color': c.color.toARGB32(),
          'type': c.type.index,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchCat.commit(noResult: true);

      // 4. Budgets
      await txn.delete('budgets');
      final batchB = txn.batch();
      for (final b in budgets) {
        batchB.insert('budgets', {
          'category_id': b.categoryId,
          'monthly_limit': b.monthlyLimit,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchB.commit(noResult: true);

      // 5. Savings Goals
      await txn.delete('savings_goals');
      final batchG = txn.batch();
      for (final g in savingsGoals) {
        batchG.insert('savings_goals', {
          'id': g.id,
          'title': g.title,
          'target_amount': g.targetAmount,
          'current_amount': g.currentAmount,
          'icon': g.icon.codePoint,
          'color': g.color.toARGB32(),
          'target_date': g.targetDate.millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchG.commit(noResult: true);

      // 6. Recurring Payments
      await txn.delete('recurring_payments');
      final batchR = txn.batch();
      for (final r in recurringPayments) {
        batchR.insert('recurring_payments', {
          'id': r.id,
          'title': r.title,
          'amount': r.amount,
          'frequency': r.frequency.index,
          'category_id': r.categoryId,
          'account_id': r.accountId,
          'next_due_date': r.nextDueDate.millisecondsSinceEpoch,
          'is_active': r.isActive ? 1 : 0,
          'note': r.note,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchR.commit(noResult: true);

      // 7. Shortcuts
      await txn.delete('shortcuts');
      final batchS = txn.batch();
      for (final s in shortcuts) {
        batchS.insert('shortcuts', {
          'id': s.id,
          'title': s.title,
          'amount': s.amount,
          'category_id': s.categoryId,
          'account_id': s.accountId,
          'icon': s.icon.codePoint,
          'color': s.color.toARGB32(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batchS.commit(noResult: true);

      // 8. Meta KV (Winter Arc & App Status)
      final batchM = txn.batch();
      batchM.insert(
        'meta_kv',
        {'key': 'no_spend_streak', 'value': noSpendStreak.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (lastWinterCheckInDate != null) {
        batchM.insert(
          'meta_kv',
          {'key': 'last_check_in', 'value': lastWinterCheckInDate.toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      batchM.insert(
        'meta_kv',
        {'key': 'winter_shields', 'value': winterShields.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      batchM.insert(
        'meta_kv',
        {'key': 'last_saved_at', 'value': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await batchM.commit(noResult: true);
    });
  }

  /// Load full state from SQLite
  Future<Map<String, dynamic>?> loadFullState() async {
    final db = await database;

    final accountsRaw = await db.query('accounts');
    final txRaw = await db.query('transactions', orderBy: 'date DESC');
    final catRaw = await db.query('categories');
    final budgetRaw = await db.query('budgets');
    final goalsRaw = await db.query('savings_goals');
    final recRaw = await db.query('recurring_payments');
    final shortRaw = await db.query('shortcuts');
    final metaRaw = await db.query('meta_kv');

    if (accountsRaw.isEmpty && txRaw.isEmpty && metaRaw.isEmpty) {
      return null; // Database is completely empty, trigger first run default seeding
    }

    final result = <String, dynamic>{};

    // 1. Accounts
    result['accounts'] = accountsRaw.map((m) {
      final typeIndex = (m['type'] as num?)?.toInt() ?? 0;
      final colorInt = (m['color'] as num?)?.toInt() ?? 0xFF0A84FF;
      return Account(
        id: m['id'] as String? ?? 'acc_mbank',
        name: m['name'] as String? ?? 'MBank',
        bankName: m['bank_name'] as String? ?? 'MBank',
        lastDigits: m['last_digits'] as String?,
        balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
        currency: m['currency'] as String? ?? 'сом',
        type: AccountType.values[typeIndex.clamp(0, AccountType.values.length - 1)],
        color: Color(colorInt),
      );
    }).toList();

    // 2. Transactions
    result['transactions'] = txRaw.map((m) {
      final typeIndex = (m['type'] as num?)?.toInt() ?? 0;
      final dateMs = (m['date'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
      return Transaction(
        id: m['id'] as String? ?? 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: m['title'] as String? ?? 'Операция',
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.fromMillisecondsSinceEpoch(dateMs),
        type: TransactionType.values[typeIndex.clamp(0, TransactionType.values.length - 1)],
        categoryId: m['category_id'] as String? ?? 'cat_other',
        accountId: m['account_id'] as String? ?? 'acc_mbank',
        toAccountId: m['to_account_id'] as String?,
        note: m['note'] as String?,
      );
    }).toList();

    // 3. Categories
    result['categories'] = catRaw.map((m) {
      final typeIndex = (m['type'] as num?)?.toInt() ?? 0;
      final iconCode = (m['icon'] as num?)?.toInt() ?? 0xe577;
      final colorInt = (m['color'] as num?)?.toInt() ?? 0xFF0A84FF;
      return TransactionCategory(
        id: m['id'] as String? ?? 'cat_custom',
        name: m['name'] as String? ?? 'Категория',
        icon: iconFromCode(iconCode),
        color: Color(colorInt),
        type: TransactionType.values[typeIndex.clamp(0, TransactionType.values.length - 1)],
      );
    }).toList();

    // 4. Budgets
    result['budgets'] = budgetRaw.map((m) => CategoryBudget(
      categoryId: m['category_id'] as String? ?? '',
      monthlyLimit: (m['monthly_limit'] as num?)?.toDouble() ?? 0.0,
    )).toList();

    // 5. Savings Goals
    result['savingsGoals'] = goalsRaw.map((m) {
      final iconCode = (m['icon'] as num?)?.toInt() ?? 0xe577;
      final colorInt = (m['color'] as num?)?.toInt() ?? 0xFF0A84FF;
      final dateMs = (m['target_date'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
      return SavingsGoal(
        id: m['id'] as String? ?? 'goal_dream',
        title: m['title'] as String? ?? 'Моя цель',
        targetAmount: (m['target_amount'] as num?)?.toDouble() ?? 10000.0,
        currentAmount: (m['current_amount'] as num?)?.toDouble() ?? 0.0,
        icon: iconFromCode(iconCode),
        color: Color(colorInt),
        targetDate: DateTime.fromMillisecondsSinceEpoch(dateMs),
      );
    }).toList();

    // 6. Recurring Payments
    result['recurringPayments'] = recRaw.map((m) {
      final freqIndex = (m['frequency'] as num?)?.toInt() ?? 2;
      final dateMs = (m['next_due_date'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
      return RecurringPayment(
        id: m['id'] as String? ?? 'rec_${DateTime.now().millisecondsSinceEpoch}',
        title: m['title'] as String? ?? 'Подписка',
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        frequency: RecurringFrequency.values[freqIndex.clamp(0, RecurringFrequency.values.length - 1)],
        categoryId: m['category_id'] as String? ?? 'cat_entertainment',
        accountId: m['account_id'] as String? ?? 'acc_mbank',
        nextDueDate: DateTime.fromMillisecondsSinceEpoch(dateMs),
        isActive: (m['is_active'] as num?)?.toInt() == 1,
        note: m['note'] as String?,
      );
    }).toList();

    // 7. Shortcuts
    result['shortcuts'] = shortRaw.map((m) {
      final iconCode = (m['icon'] as num?)?.toInt() ?? 0xe577;
      final colorInt = (m['color'] as num?)?.toInt() ?? 0xFFFF9F0A;
      return QuickPaymentShortcut(
        id: m['id'] as String? ?? 'q_${DateTime.now().millisecondsSinceEpoch}',
        title: m['title'] as String? ?? 'Быстрый платеж',
        amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
        categoryId: m['category_id'] as String? ?? 'cat_transport',
        accountId: m['account_id'] as String? ?? 'acc_mbank',
        icon: iconFromCode(iconCode),
        color: Color(colorInt),
      );
    }).toList();

    // 8. Meta KV (Winter Arc)
    final metaMap = {for (final row in metaRaw) row['key'] as String: row['value'] as String};
    if (metaMap.containsKey('no_spend_streak')) {
      result['noSpendStreak'] = int.tryParse(metaMap['no_spend_streak'] ?? '0') ?? 0;
    }
    if (metaMap.containsKey('last_check_in')) {
      result['lastWinterCheckInDate'] = DateTime.tryParse(metaMap['last_check_in'] ?? '');
    }
    if (metaMap.containsKey('winter_shields')) {
      result['winterShields'] = int.tryParse(metaMap['winter_shields'] ?? '1') ?? 1;
    }

    return result;
  }

  /// Export complete SQLite state to formatted JSON string
  Future<String> exportBackupJson() async {
    final db = await database;
    final payload = <String, dynamic>{
      'version': '2.4.0',
      'app': 'ARC Finance Kyrgyzstan',
      'exported_at': DateTime.now().toIso8601String(),
      'accounts': await db.query('accounts'),
      'transactions': await db.query('transactions'),
      'categories': await db.query('categories'),
      'budgets': await db.query('budgets'),
      'savings_goals': await db.query('savings_goals'),
      'recurring_payments': await db.query('recurring_payments'),
      'shortcuts': await db.query('shortcuts'),
      'meta_kv': await db.query('meta_kv'),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Import complete state from JSON string with validation & ACID rollback on failure
  Future<bool> importBackupJson(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      if (!data.containsKey('accounts') && !data.containsKey('transactions')) {
        return false;
      }

      final db = await database;
      await db.transaction((txn) async {
        // Clear all tables
        await txn.delete('accounts');
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('budgets');
        await txn.delete('savings_goals');
        await txn.delete('recurring_payments');
        await txn.delete('shortcuts');
        await txn.delete('meta_kv');

        // Restore accounts
        if (data['accounts'] is List) {
          for (final row in data['accounts']) {
            await txn.insert('accounts', Map<String, dynamic>.from(row));
          }
        }

        // Restore transactions
        if (data['transactions'] is List) {
          for (final row in data['transactions']) {
            await txn.insert('transactions', Map<String, dynamic>.from(row));
          }
        }

        // Restore categories
        if (data['categories'] is List) {
          for (final row in data['categories']) {
            await txn.insert('categories', Map<String, dynamic>.from(row));
          }
        }

        // Restore budgets
        if (data['budgets'] is List) {
          for (final row in data['budgets']) {
            await txn.insert('budgets', Map<String, dynamic>.from(row));
          }
        }

        // Restore savings goals
        if (data['savings_goals'] is List) {
          for (final row in data['savings_goals']) {
            await txn.insert('savings_goals', Map<String, dynamic>.from(row));
          }
        }

        // Restore recurring
        if (data['recurring_payments'] is List) {
          for (final row in data['recurring_payments']) {
            await txn.insert('recurring_payments', Map<String, dynamic>.from(row));
          }
        }

        // Restore shortcuts
        if (data['shortcuts'] is List) {
          for (final row in data['shortcuts']) {
            await txn.insert('shortcuts', Map<String, dynamic>.from(row));
          }
        }

        // Restore meta_kv
        if (data['meta_kv'] is List) {
          for (final row in data['meta_kv']) {
            await txn.insert('meta_kv', Map<String, dynamic>.from(row));
          }
        }
      });
      return true;
    } catch (e) {
      debugPrint('[DatabaseService] Error during importBackupJson: $e');
      return false;
    }
  }

  /// Diagnostics: total number of recorded transactions
  Future<int> getTransactionCount() async {
    try {
      final db = await database;
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM transactions'),
      );
      return count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Diagnostics: database file size in bytes
  Future<int> getDatabaseSizeBytes() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, dbName);
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Completely wipe SQLite database
  Future<void> clearAll() async {
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('accounts');
        await txn.delete('transactions');
        await txn.delete('categories');
        await txn.delete('budgets');
        await txn.delete('savings_goals');
        await txn.delete('recurring_payments');
        await txn.delete('shortcuts');
        await txn.delete('meta_kv');
      });
    } catch (e) {
      debugPrint('[DatabaseService] Error in clearAll: $e');
    }
  }
}
