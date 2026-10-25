import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:finance_management/services/database_service.dart';
import 'package:finance_management/services/storage_service.dart';
import 'package:finance_management/models/account.dart';
import 'package:finance_management/models/transaction.dart';
import 'package:finance_management/models/transaction_type.dart';
import 'package:finance_management/models/transaction_category.dart';
import 'package:finance_management/state/finance_controller.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.mockDatabaseFactory = databaseFactoryFfi;
  });

  test('Test StorageService saveAll and loadAll with SQLite engine', () async {
    SharedPreferences.setMockInitialValues({});

    final acc = Account(
      id: 'acc_mbank',
      name: 'MBank',
      bankName: 'MBank',
      lastDigits: '4820',
      balance: 15400.0,
      currency: 'сом',
      type: AccountType.card,
      color: const Color(0xFF0A84FF),
    );

    final tx = Transaction(
      id: 'tx_1',
      title: 'Зарплата',
      amount: 45000.0,
      date: DateTime.now(),
      type: TransactionType.income,
      categoryId: 'cat_salary',
      accountId: 'acc_mbank',
      note: 'Аванс',
    );

    await StorageService.saveAll(
      accounts: [acc],
      transactions: [tx],
      categories: TransactionCategory.defaultCategories,
      budgets: [],
      savingsGoals: [],
      recurringPayments: [],
      shortcuts: [],
      noSpendStreak: 5,
      lastWinterCheckInDate: DateTime.now(),
      winterShields: 2,
    );

    final loaded = await StorageService.loadAll();
    expect(loaded, isNotNull);
    expect((loaded!['accounts'] as List).length, 1);
    expect((loaded['transactions'] as List).length, 1);
    expect(loaded['noSpendStreak'], 5);

    // Test JSON Backup Export & Import
    final backupJson = await StorageService.exportBackup();
    expect(backupJson.contains('ARC Finance Kyrgyzstan'), isTrue);
    expect(backupJson.contains('tx_1'), isTrue);

    // Wipe and restore
    await StorageService.clearAll();
    final emptyLoad = await StorageService.loadAll();
    expect(emptyLoad, isNull);

    // Import from JSON backup
    final importSuccess = await StorageService.importBackup(backupJson);
    expect(importSuccess, isTrue);

    final restored = await StorageService.loadAll();
    expect(restored, isNotNull);
    expect((restored!['transactions'] as List).length, 1);
    expect(restored['noSpendStreak'], 5);
  });

  test('Dual-Engine Fail-safe: Restores from SharedPreferences mirror if SQLite is wiped', () async {
    SharedPreferences.setMockInitialValues({});

    final acc = Account(
      id: 'acc_mbank',
      name: 'MBank',
      bankName: 'MBank',
      lastDigits: '4820',
      balance: 75000.0,
      currency: 'сом',
      type: AccountType.card,
      color: const Color(0xFF0A84FF),
    );

    await StorageService.saveAll(
      accounts: [acc],
      transactions: [],
      categories: TransactionCategory.defaultCategories,
      budgets: [],
      savingsGoals: [],
      recurringPayments: [],
      shortcuts: [],
      noSpendStreak: 12,
      lastWinterCheckInDate: DateTime.now(),
      winterShields: 3,
    );

    // Simulate unexpected SQLite table wipe or corruption while SharedPreferences remains intact
    await DatabaseService.instance.clearAll();

    // StorageService must automatically detect SQLite is empty and recover from mirror
    final recovered = await StorageService.loadAll();
    expect(recovered, isNotNull);
    final accounts = recovered!['accounts'] as List;
    expect(accounts.length, 1);
    expect((accounts.first as Account).balance, 75000.0);
    expect(recovered['noSpendStreak'], 12);
  });

  test('FinanceController rejects suspicious shadow scraped balance drops', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = FinanceController();
    await controller.loadFromStorage();
    controller.updateAccountBalance('acc_mbank', 50000.0);

    // Spurious scrape (e.g. 25 som from van button or 0 som from bonus banner)
    final rejected = controller.updateScrapedBankBalance('MBank', 25.0);
    expect(rejected, isFalse);
    expect(controller.getAccountById('acc_mbank')!.balance, 50000.0);

    // Legitimate scrape (e.g. 48500 som)
    final accepted = controller.updateScrapedBankBalance('MBank', 48500.0);
    expect(accepted, isTrue);
    expect(controller.getAccountById('acc_mbank')!.balance, 48500.0);
  });

  test('FinanceController deduplicates repeated addMBankAutoTransaction within short window', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await DatabaseService.instance.clearAll();
    final controller = FinanceController();
    await controller.loadFromStorage();
    final initialTxCount = controller.transactions.length;

    // First auto-transaction from push notification
    controller.addMBankAutoTransaction(
      title: 'Оплата Globus',
      amount: 500.0,
      type: TransactionType.expense,
      categoryId: 'cat_groceries',
    );
    expect(controller.transactions.length, initialTxCount + 1);

    // Second auto-transaction from screen capture or duplicate push notification
    controller.addMBankAutoTransaction(
      title: 'Оплата Globus',
      amount: 500.0,
      type: TransactionType.expense,
      categoryId: 'cat_groceries',
    );
    // Must NOT create a duplicate record
    expect(controller.transactions.length, initialTxCount + 1);
  });
}
