import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:finance_management/models/transaction.dart';
import 'package:finance_management/models/transaction_type.dart';
import 'package:finance_management/services/ai_roast_service.dart';
import 'package:finance_management/services/clipboard_parser_service.dart';
import 'package:finance_management/services/database_service.dart';
import 'package:finance_management/services/geoshame_service.dart';
import 'package:finance_management/services/merchant_memory_service.dart';
import 'package:finance_management/services/mbank_parser_service.dart';
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

  group('Smart Round-Up Removed: Exact amounts always preserved', () {
    test('340 сом expense leaves account deducted by exactly 340 сом with zero round-up distortion', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 5000.0);

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

      // Account must be deducted by exactly 340 som
      final acc = controller.getAccountById('acc_mbank')!;
      expect(acc.balance, 4660.0);
      expect(controller.savingsGoals.first.currentAmount, initialGoalAmount);
      expect(controller.transactions.any((t) => t.title.contains('Умное округление')), isFalse);
    });

    test('addMBankAutoTransaction leaves account deducted by exact transaction amount', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 5000.0);

      controller.addMBankAutoTransaction(
        title: 'Оплата в Бублике',
        amount: 70.0,
        type: TransactionType.expense,
        categoryId: 'cat_restaurants',
      );

      final acc = controller.getAccountById('acc_mbank')!;
      // Must be EXACTLY 5000 - 70 = 4930, NOT 4900
      expect(acc.balance, 4930.0);
      expect(controller.transactions.any((t) => t.title.contains('Умное округление')), isFalse);
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

    test('AIRoastService reads fresh API key from disk across all key aliases (api_key, gemini_api_key, arc_ai_roast_api_key)', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', 'AIzaSy_GenericKey_999');
      
      final key = await AIRoastService.getApiKey();
      expect(key, 'AIzaSy_GenericKey_999');

      await AIRoastService.saveApiKey('AIzaSy_UpdatedKey_888');
      expect(prefs.getString('api_key'), 'AIzaSy_UpdatedKey_888');
      expect(prefs.getString('gemini_api_key'), 'AIzaSy_UpdatedKey_888');
      expect(prefs.getString('arc_ai_roast_api_key'), 'AIzaSy_UpdatedKey_888');
      expect(await AIRoastService.getApiKey(), 'AIzaSy_UpdatedKey_888');
    });

    test('Strictly strips Gemini markdown backticks ```json ... ``` without crashing jsonDecode', () {
      const rawGeminiResponse = '''
      ```json
      {
        "merchant": "Куликовский",
        "items": [
          {
            "name": "Торт Красный бархат",
            "price": 650.0,
            "categoryId": "cat_restaurants",
            "categoryName": "Кафе",
            "isImpulseOrJunk": true,
            "capybaraComment": "Снова торт? Отдалил себя от цели на 650 сом"
          }
        ],
        "total": 650.0,
        "mainAlert": "Торт за 650 сом"
      }
      ```
      ''';

      final cleanedJson = rawGeminiResponse.replaceAll(RegExp(r'```(?:json)?|```'), '').trim();
      final firstBrace = cleanedJson.indexOf('{');
      final lastBrace = cleanedJson.lastIndexOf('}');
      final jsonSubstr = cleanedJson.substring(firstBrace, lastBrace + 1);
      final Map<String, dynamic> parsed = Map<String, dynamic>.from(jsonDecode(jsonSubstr) as Map);

      expect(parsed['merchant'], 'Куликовский');
      expect(parsed['total'], 650.0);
      expect(parsed['items'], isNotEmpty);
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

  group('Dynamic Quick Widget Buttons Tests', () {
    test('Entering expenses automatically updates quick buttons with user entries first', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 50000.0);

      // User enters custom expense 1: Донер 220 сом
      controller.addTransaction(
        title: 'Донер',
        amount: 220.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_restaurants',
        accountId: 'acc_mbank',
      );

      // User enters custom expense 2: Бензин 1000 сом
      controller.addTransaction(
        title: 'Бензин',
        amount: 1000.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_transport',
        accountId: 'acc_mbank',
      );

      final buttons = controller.quickButtonsForWidget;
      expect(buttons.length, 4);

      // Latest entered expense is at index 0
      expect(buttons[0].title, 'Бензин');
      expect(buttons[0].amount, 1000.0);

      // Second latest entered expense is at index 1
      expect(buttons[1].title, 'Донер');
      expect(buttons[1].amount, 220.0);

      // When user enters another Донер with new price 240, it moves back to index 0
      controller.addTransaction(
        title: 'Донер',
        amount: 240.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_restaurants',
        accountId: 'acc_mbank',
      );

      final updatedButtons = controller.quickButtonsForWidget;
      expect(updatedButtons[0].title, 'Донер');
      expect(updatedButtons[0].amount, 240.0);
      expect(updatedButtons[1].title, 'Бензин');
      expect(updatedButtons[1].amount, 1000.0);
    });
  });

  group('MerchantMemoryService & Auto-Categorization Tests', () {
    test('Identifies medical tests, clinics, and labs as cat_health', () async {
      await MerchantMemoryService.init();

      // Pre-seeded medical keywords & Bishkek clinics
      expect(MerchantMemoryService.getCategoryForTextSync('Лаборатория Бонецкого'), 'cat_health');
      expect(MerchantMemoryService.getCategoryForTextSync('Оплата за анализы крови'), 'cat_health');
      expect(MerchantMemoryService.getCategoryForTextSync('Аквалаб Бишкек'), 'cat_health');
      expect(MerchantMemoryService.getCategoryForTextSync('Инвитро Клиника'), 'cat_health');
      expect(MerchantMemoryService.getCategoryForTextSync('Анализ мочи в Юрфа'), 'cat_health');
    });

    test('Learns user merchant corrections and applies them dynamically', () async {
      await MerchantMemoryService.init();

      // Initially unknown merchant
      final initial = MerchantMemoryService.getCategoryForTextSync('Магазин Улыбка Радость');
      expect(initial, isNull);

      // User adds transaction or changes category to cat_shopping
      await MerchantMemoryService.learnMerchant('Магазин Улыбка Радость', 'cat_shopping');

      // Now it's recognized instantly
      expect(MerchantMemoryService.getCategoryForTextSync('Магазин Улыбка Радость'), 'cat_shopping');
      expect(MerchantMemoryService.getCategoryForTextSync('Покупка в магазине Улыбка'), 'cat_shopping');
    });

    test('MBankParserService integrates MerchantMemoryService for auto-categorization', () async {
      await MerchantMemoryService.init();

      // Parse medical test notification
      final parsed = MBankParserService.parse(
        'MBank: Списание 1450 сом. Лаборатория Бонецкого. Доступно 12000 сом',
      );
      expect(parsed, isNotNull);
      expect(parsed!.amount, 1450.0);
      expect(parsed.categoryId, 'cat_health');
    });
  });

  group('Bank Auto-Deduplication Tests', () {
    test('Prevents duplicate payment deduction within 60 minutes for same amount', () {
      final controller = FinanceController();
      controller.updateAccountBalance('acc_mbank', 10000.0);

      final initialBalance = controller.getAccountById('acc_mbank')!.balance;

      // 1. First event: screen receipt capture for medical tests 1800 som
      final success1 = controller.addMBankAutoTransaction(
        title: 'Лаборатория Бонецкого (Экран)',
        amount: 1800.0,
        type: TransactionType.expense,
        categoryId: 'cat_health',
      );
      expect(success1, isTrue);
      expect(controller.getAccountById('acc_mbank')!.balance, initialBalance - 1800.0);

      // 2. Second event: push notification arrives 5 minutes later with same amount
      final success2 = controller.addMBankAutoTransaction(
        title: 'MBank: Оплата 1800 сом в Бонецкого',
        amount: 1800.0,
        type: TransactionType.expense,
        categoryId: 'cat_health',
      );

      // Must be rejected as duplicate, balance must NOT decrease twice!
      expect(success2, isFalse);
      expect(controller.getAccountById('acc_mbank')!.balance, initialBalance - 1800.0);
    });
  });
}


