import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:finance_management/models/transaction.dart';
import 'package:finance_management/models/transaction_type.dart';
import 'package:finance_management/services/ai_roast_service.dart';
import 'package:finance_management/services/clipboard_parser_service.dart';
import 'package:finance_management/services/database_service.dart';
import 'package:finance_management/services/geoshame_service.dart';
import 'package:finance_management/services/receipt_vision_service.dart';
import 'package:finance_management/services/widget_launch_service.dart';
import 'package:finance_management/state/finance_controller.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.mockDatabaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ClipboardParserService Tests', () {
    test('Parses meal payment request from friend', () {
      final res = ClipboardParserService.parseText('Закинь 1200 сом за обед в Фаизе');
      expect(res, isNotNull);
      expect(res!.amount, 1200.0);
      expect(res.categoryId, 'cat_restaurants');
      expect(res.categoryName, 'Кафе и еда');
    });

    test('Parses taxi share transfer', () {
      final res = ClipboardParserService.parseText('Скинь 350 сом за такси');
      expect(res, isNotNull);
      expect(res!.amount, 350.0);
      expect(res.categoryId, 'cat_transport');
    });

    test('Parses grocery share transfer', () {
      final res = ClipboardParserService.parseText('Переведи 840 сом за продукты в Глобусе');
      expect(res, isNotNull);
      expect(res!.amount, 840.0);
      expect(res.categoryId, 'cat_groceries');
    });

    test('Ignores casual messages without payment keywords', () {
      final res = ClipboardParserService.parseText('Привет, встретимся в 18:00');
      expect(res, isNull);
    });
  });

  group('GeoshameService Tests', () {
    test('Calculates geodesic distance correctly', () {
      final d = GeoshameService.calculateDistance(42.8519, 74.6148, 42.8519, 74.6148);
      expect(d, 0.0);

      // Distance between Faiza and Dordoi Plaza (~3 km)
      final d2 = GeoshameService.calculateDistance(42.8519, 74.6148, 42.8752, 74.6163);
      expect(d2, greaterThan(2000.0));
      expect(d2, lessThan(4000.0));
    });

    test('Proximity detection flags Faiza danger zone', () {
      final zone = GeoshameService.checkProximity(42.8519, 74.6148);
      expect(zone, isNotNull);
      expect(zone!.id, 'dz_faiza');
      expect(zone.toxicWarning.contains('Mac M3'), isTrue);
    });
  });

  group('Smart Round-Up in FinanceController', () {
    test('340 сом expense rounds up to 400 сом and deposits 60 сом to goal', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 5000.0);

      // Verify dream goal exists
      expect(controller.savingsGoals, isNotEmpty);
      final initialGoalAmount = controller.savingsGoals.first.currentAmount;

      // Add 340 сом expense for coffee
      controller.addTransaction(
        title: 'Кофе в кофейне',
        amount: 340.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_restaurants',
        accountId: 'acc_mbank',
      );

      // Remainder = 60 сом (rounded to nearest 100 som)
      expect(controller.lastRoundUpAmount, 60.0);
      expect(controller.savingsGoals.first.currentAmount, initialGoalAmount + 60.0);

      // Account should be deducted by 340 + 60 = 400
      final acc = controller.getAccountById('acc_mbank')!;
      expect(acc.balance, 4600.0);

      // Should have companion transaction
      final roundUpTx = controller.transactions.firstWhere(
        (t) => t.title.contains('Умное округление'),
      );
      expect(roundUpTx.amount, 60.0);
      expect(roundUpTx.categoryId, 'cat_savings');
    });
  });

  group('Workout Penalty in FinanceController', () {
    test('Entertainment spending exceeding budget triggers 25 pull-ups penalty', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 20000.0);

      // Monthly entertainment limit is 5000.0
      controller.updateBudget('cat_entertainment', 2000.0);

      // Add expense exceeding 2000 som
      controller.addTransaction(
        title: 'Караоке и клуб',
        amount: 3200.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_entertainment',
        accountId: 'acc_mbank',
      );

      expect(controller.activeWorkoutPenalty, isNotNull);
      expect(controller.activeWorkoutPenalty!.reps, 25);
      expect(controller.activeWorkoutPenalty!.exercise, 'подтягиваний');
      expect(controller.activeWorkoutPenalty!.excessAmount, greaterThan(0));

      final initialShields = controller.winterShields;
      controller.completeWorkoutPenalty();
      expect(controller.activeWorkoutPenalty, isNull);
      expect(controller.winterShields, initialShields + 1);
    });
  });

  group('AIRoastService Tests', () {
    test('Offline local roast flags excessive taxi spending', () async {
      final txList = [
        Transaction(
          id: 'tx_taxi_1',
          title: 'Яндекс Такси Комфорт',
          amount: 450.0,
          date: DateTime.now(),
          type: TransactionType.expense,
          categoryId: 'cat_transport',
          accountId: 'acc_mbank',
        ),
        Transaction(
          id: 'tx_taxi_2',
          title: 'Яндекс Такси Ночь',
          amount: 520.0,
          date: DateTime.now(),
          type: TransactionType.expense,
          categoryId: 'cat_transport',
          accountId: 'acc_mbank',
        ),
      ];

      final roast = await AIRoastService.generateRoast(
        transactions: txList,
        totalBalance: 12000.0,
        streak: 5,
        dreamGoal: 'MacBook Pro M3',
        remainingGoal: 100000.0,
      );

      expect(roast.verdict, 'ТАКСИ-ОЛИГАРХ');
      expect(roast.roastText.contains('Яндекс'), isTrue);
      expect(roast.toxicityScore, greaterThan(80));
    });

    test('Offline local roast praises zero spending as Cold Discipline', () async {
      final roast = await AIRoastService.generateRoast(
        transactions: [],
        totalBalance: 12000.0,
        streak: 14,
        dreamGoal: 'MacBook Pro M3',
        remainingGoal: 100000.0,
      );

      expect(roast.verdict, 'ХОЛОДНЫЙ КРЕМЕНЬ');
      expect(roast.toxicityScore, lessThan(40));
    });
  });

  group('ReceiptVisionService Tests', () {
    test('Frunze preset identifies energy drinks and outputs Capybara alert', () {
      final receipt = ReceiptVisionService.getPreset('Фрунзе', dreamGoal: 'Mac M3');
      expect(receipt.merchant, 'Гипермаркет «Фрунзе»');
      expect(receipt.totalAmount, greaterThan(400.0));

      final energyDrink = receipt.items.firstWhere((i) => i.name.contains('Flash Up'));
      expect(energyDrink.isImpulseOrJunk, isTrue);
      expect(
        energyDrink.capybaraComment,
        contains('Опять энергетики? Отдалил себя от Mac M3 на 140 сом'),
      );
    });

    test('Local OCR parser flags energy drinks and calculates total correctly', () {
      const sampleText = '''
        Супермаркет Народный
        Энергетик Red Bull 200
        Хлеб бородинский 45
        Сыр плавленый 120
        ИТОГО: 365
      ''';

      final parsed = ReceiptVisionService.parseRawText(sampleText, dreamGoal: 'Mac M3');
      expect(parsed.items.length, 3);
      expect(parsed.totalAmount, 365.0);

      final junkItem = parsed.items.firstWhere((i) => i.isImpulseOrJunk);
      expect(junkItem.name, contains('Red Bull'));
      expect(junkItem.price, 200.0);
      expect(
        junkItem.capybaraComment,
        contains('Опять энергетики? Отдалил себя от Mac M3 на 200 сом'),
      );
    });

    test('Local OCR parser accepts non-junk groceries without warnings', () {
      const cleanText = '''
        Магазин у дома
        Молоко 85
        Кефир 70
        ИТОГО: 155
      ''';

      final parsed = ReceiptVisionService.parseRawText(cleanText, dreamGoal: 'Mac M3');
      expect(parsed.items.length, 2);
      expect(parsed.items.every((i) => !i.isImpulseOrJunk), isTrue);
      expect(parsed.totalAmount, 155.0);
    });
  });

  group('Hardcore Social Blocker (Dictator Mode) Tests', () {
    test('Overspending triggers workout penalty and activates social blocker', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 50000.0);
      controller.updateBudget('cat_entertainment', 1000.0);

      expect(controller.isSocialBlockerActive, isFalse);

      // Violate entertainment budget by 2500 сом
      controller.addTransaction(
        title: 'Кальян и коктейли',
        amount: 3500.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_entertainment',
        accountId: 'acc_mbank',
      );

      // Social blocker is now ACTIVE (blocking Instagram, TikTok, YouTube)
      expect(controller.isSocialBlockerActive, isTrue);
      expect(controller.activeWorkoutPenalty, isNotNull);
      expect(controller.activeWorkoutPenalty!.reps, 25);

      // Completing workout unlocks social media
      controller.completeWorkoutPenalty();
      expect(controller.isSocialBlockerActive, isFalse);
      expect(controller.activeWorkoutPenalty, isNull);
    });

    test('syncSocialBlockerConfig runs without errors', () async {
      // Verifies platform channel invocation doesn't crash test runner
      await WidgetLaunchService.syncSocialBlockerConfig(
        enabled: true,
        isBlocked: true,
        dreamGoal: 'Mac M3',
        pullupsRequired: 20,
      );
      expect(true, isTrue);
    });
  });
}
