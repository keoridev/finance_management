import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_management/main.dart';
import 'package:finance_management/models/app_notification.dart';
import 'package:finance_management/models/transaction_type.dart';
import 'package:finance_management/screens/dashboard_screen.dart';
import 'package:finance_management/screens/main_navigation_screen.dart';
import 'package:finance_management/screens/recurring_payments_screen.dart';
import 'package:finance_management/screens/settings_screen.dart';
import 'package:finance_management/state/finance_controller.dart';
import 'package:finance_management/state/notification_controller.dart';
import 'package:finance_management/utils/formatters.dart';
import 'package:finance_management/widgets/account_card.dart';
import 'package:finance_management/widgets/add_transaction_modal.dart';
import 'package:finance_management/widgets/animated_currency_text.dart';
import 'package:finance_management/widgets/balance_card.dart';
import 'package:finance_management/widgets/dashboard_subscriptions_card.dart';
import 'package:finance_management/widgets/financial_alert_banner.dart';
import 'package:finance_management/widgets/interactive_home_widget.dart';
import 'package:finance_management/widgets/ios_home_widget_preview.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:finance_management/services/database_service.dart';
import 'package:finance_management/services/storage_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    DatabaseService.mockDatabaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseService.instance.close();
  });
  testWidgets('FinanceApp loads SplashScreen and navigates to MainNavigationScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const FinanceApp());
    await tester.pump(const Duration(milliseconds: 100));

    // Verify SplashScreen is loaded with modern Apple branding
    expect(find.text('ARC FINANCE'), findsOneWidget);
    expect(find.text('Открыть кошелек'), findsOneWidget);

    // Tap Enter to navigate to MainNavigationScreen
    await tester.tap(find.text('Открыть кошелек'));
    await tester.pumpAndSettle();

    // Verify MainNavigationScreen is loaded with Kyrgyz Som and iOS elements
    expect(find.text('Финансы'), findsOneWidget);
    expect(find.text('Обзор'), findsOneWidget);
    expect(find.text('Операции'), findsOneWidget);
    expect(find.text('Аналитика'), findsOneWidget);
    expect(find.text('Профиль'), findsWidgets);
    expect(find.text('Мои банки и счета'), findsOneWidget);
    expect(find.text('Последние операции'), findsOneWidget);
  });

  testWidgets('Directly renders MainNavigationScreen with all tabs and FAB', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add_rounded), findsWidgets);
    expect(find.text('Общий баланс'), findsOneWidget);
    expect(find.text('Мои банки и счета'), findsOneWidget);
    expect(find.text('Последние операции'), findsOneWidget);
  });

  testWidgets('Account selection switches balance title and filters active account', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    // Initially "Общий баланс"
    expect(find.text('Общий баланс'), findsOneWidget);

    // Tap on the first AccountCard
    expect(find.byType(AccountCard), findsWidgets);
    await tester.ensureVisible(find.byType(AccountCard).first);
    await tester.tap(find.byType(AccountCard).first);
    await tester.pumpAndSettle();

    // Title changes to MBank and controller updates
    expect(controller.selectedAccountId, 'acc_mbank');
    expect(controller.activeAccountLabel, 'MBank');

    // Tap again to deselect
    await tester.ensureVisible(find.byType(AccountCard).first);
    await tester.tap(find.byType(AccountCard).first);
    await tester.pumpAndSettle();
    expect(controller.selectedAccountId, isNull);
    expect(controller.activeAccountLabel, 'Общий баланс');
  });

  testWidgets('AnimatedCurrencyText counts up from zero smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnimatedCurrencyText(
            amount: 50000.0,
            duration: Duration(milliseconds: 300),
          ),
        ),
      ),
    );

    // Initial frame starts at 0 before advancing time
    expect(find.text(CurrencyFormatter.format(0)), findsOneWidget);

    // Settle to final
    await tester.pumpAndSettle();
    expect(find.text(CurrencyFormatter.format(50000.0)), findsOneWidget);
  });

  testWidgets('Small compact screen (320x568) renders without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Общий баланс'), findsOneWidget);
  });

  testWidgets('SettingsScreen houses Widget Configurator and Currency Rates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Настройки и Инструменты'), findsOneWidget);
    expect(find.text('Курсы валют (НБКР)'), findsOneWidget);
    expect(find.text('Виджеты на рабочий стол'), findsOneWidget);
    expect(find.text('Банки и счета'), findsOneWidget);
  });

  testWidgets('AddTransactionModal renders clean input and compact bank chips without duplicate plus', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AddTransactionModal.show(context, controller),
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap button to open bottom sheet
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Verify header "Готово" button and clean labels
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('Новый платеж'), findsOneWidget);
    expect(find.text('Добавить банк'), findsOneWidget);
    expect(find.text('Создать категорию'), findsOneWidget);
    expect(find.textContaining('+ +'), findsNothing);
  });

  test('NotificationController triggers hourly, winter arc, and dream savings notifications', () {
    final controller = NotificationController();
    expect(controller.hourlyReminderEnabled, isTrue);
    expect(controller.winterArcReminderEnabled, isTrue);
    expect(controller.dreamSavingsReminderEnabled, isTrue);
    expect(controller.activeBannerNotification, isNull);

    // 1. Hourly reminder
    controller.triggerHourlyExpenseReminder();
    expect(controller.activeBannerNotification, isNotNull);
    expect(controller.activeBannerNotification!.title, 'Ничего не забыли записать?');

    // 2. Winter Arc reminder
    controller.triggerWinterArcReminder();
    expect(controller.activeBannerNotification!.title, 'Winter Arc: Дисциплина под угрозой!');

    // 3. Dream Savings reminder
    controller.triggerDreamSavingsReminder();
    expect(controller.activeBannerNotification!.title, 'Пора отложить на мечту!');

    // 4. Capybara Zen notification
    controller.triggerCapybaraZenNotification();
    expect(controller.activeBannerNotification!.type, NotificationType.capybaraZen);
    expect(controller.activeBannerNotification!.title.isNotEmpty, isTrue);

    controller.dismissActiveNotification();
    expect(controller.activeBannerNotification, isNull);
    controller.dispose();
  });

  test('Winter Arc logic tracks 90-day progress, ranks, and daily check-ins', () {
    final finance = FinanceController();
    expect(finance.winterArcTargetDays, 90);
    expect(finance.noSpendStreak, 0);
    expect(finance.winterArcRankTitle, 'Искра (Arc Initiate)');

    finance.checkInWinterDay(force: true);
    expect(finance.noSpendStreak, 1);
    expect(finance.isWinterCheckedToday, isTrue);

    finance.resetWinterStreak();
    expect(finance.noSpendStreak, 0);
  });

  testWidgets('Swiping left on MainNavigationScreen flips to next page (Operations)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: MainNavigationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    // Verify PageView exists
    expect(find.byType(PageView), findsOneWidget);

    // Swipe left to advance from Dashboard (index 0) to Transactions (index 1)
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify TransactionsScreen elements are now visible
    expect(find.text('История операций'), findsOneWidget);
  });

  test('Savings goal deposit rejects when funds are insufficient and succeeds when funds exist', () {
    final finance = FinanceController();
    final firstAcc = finance.accounts.first;
    final goal = finance.savingsGoals.first;
    final initialGoalAmount = goal.currentAmount;

    // 1. Initial balance is 0.0, deposit of 500 must fail
    expect(firstAcc.balance, 0.0);
    final zeroBalanceResult = finance.depositToGoal(
      goalId: goal.id,
      amount: 500.0,
      fromAccountId: firstAcc.id,
    );
    expect(zeroBalanceResult, isFalse);
    expect(finance.getAccountById(firstAcc.id)!.balance, 0.0);
    expect(finance.savingsGoals.first.currentAmount, initialGoalAmount);

    // 2. Fund the account with 5,000 сом
    finance.addTransaction(
      title: 'Зарплата',
      amount: 5000.0,
      date: DateTime.now(),
      type: TransactionType.income,
      categoryId: 'cat_salary',
      accountId: firstAcc.id,
    );
    expect(finance.getAccountById(firstAcc.id)!.balance, 5000.0);

    // 3. Excessive deposit (10,000 сом > 5,000 сом) must fail
    final excessiveResult = finance.depositToGoal(
      goalId: goal.id,
      amount: 10000.0,
      fromAccountId: firstAcc.id,
    );
    expect(excessiveResult, isFalse);
    expect(finance.getAccountById(firstAcc.id)!.balance, 5000.0);

    // 4. Valid deposit (1,500 сом <= 5,000 сом) must succeed
    final validResult = finance.depositToGoal(
      goalId: goal.id,
      amount: 1500.0,
      fromAccountId: firstAcc.id,
    );
    expect(validResult, isTrue);
    expect(finance.getAccountById(firstAcc.id)!.balance, 3500.0);
    expect(finance.savingsGoals.first.currentAmount, initialGoalAmount + 1500.0);
  });

  test('Capybara health changes dynamically based on expenses and deposits', () {
    final finance = FinanceController();

    // 1. Initial health (zero balance triggers deficit/shock penalty as requested)
    final initialHealth = finance.capybaraHealth;
    expect(initialHealth, inInclusiveRange(20, 50));
    expect(finance.capybaraMoodImagePath, isNotEmpty);
    expect(finance.capybaraMoodTitle, isNotEmpty);
    expect(finance.capybaraMoodComment, isNotEmpty);

    // 2. Add income to boost health
    finance.addTransaction(
      title: 'Большой доход',
      amount: 60000.0,
      date: DateTime.now(),
      type: TransactionType.income,
      categoryId: 'cat_salary',
      accountId: finance.accounts.first.id,
    );

    expect(finance.capybaraHealth, greaterThanOrEqualTo(80));
    expect(finance.capybaraMood, CapybaraMoodState.zenHappy);
    expect(finance.capybaraMoodImagePath, 'assets/images/capy_happy.jpg');

    // 3. Add heavy expenses to cause financial shock
    for (int i = 0; i < 4; i++) {
      finance.addTransaction(
        title: 'Спонтанная покупка $i',
        amount: 25000.0,
        date: DateTime.now(),
        type: TransactionType.expense,
        categoryId: 'cat_entertainment',
        accountId: finance.accounts.first.id,
      );
    }

    // Health drops and mood transitions to shocked or sad
    expect(finance.capybaraHealth, lessThan(80));
    expect(finance.capybaraMoodTitle, anyOf(equals('В шоке от трат'), equals('Критический дефицит')));
  });

  test('2-Step Daily Discipline counts until completion (2 steps) and awards praise', () {
    final finance = FinanceController();

    // Starts at step 0
    expect(finance.dailyDisciplineSteps, 0);
    expect(finance.isDailyDisciplineComplete, isFalse);

    // Step 1
    final step1 = finance.completeNextDisciplineStep();
    expect(step1, 1);
    expect(finance.dailyDisciplineSteps, 1);
    expect(finance.isDailyDisciplineComplete, isFalse);

    // Step 2 completes habit and checks in day
    final step2 = finance.completeNextDisciplineStep();
    expect(step2, 2);
    expect(finance.dailyDisciplineSteps, 2);
    expect(finance.isDailyDisciplineComplete, isTrue);
    expect(finance.isWinterCheckedToday, isTrue);

    // Calling again does not exceed 2
    final step3 = finance.completeNextDisciplineStep();
    expect(step3, 2);
  });

  testWidgets('DashboardScreen is clean and decluttered: no fake widget, mascot alert only on shock/deficit, subscriptions on separate page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardScreen(
            controller: controller,
            onSeeAllTransactions: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Core overview blocks are present
    expect(find.byType(BalanceCard), findsOneWidget);
    expect(find.text('Мои банки и счета'), findsOneWidget);
    expect(find.text('Последние операции'), findsOneWidget);

    // 2. All clutter, interactive widgets, subscriptions, and mascot alerts are REMOVED from Overview
    expect(find.byType(FinancialAlertBanner), findsNothing);
    expect(find.byType(InteractiveHomeWidget), findsNothing);
    expect(find.byType(DashboardSubscriptionsCard), findsNothing);
    expect(find.text('В шоке от трат'), findsNothing);
    expect(find.text('Спокойный Чилл'), findsNothing);

    // 3. Subscriptions render properly on their own dedicated screen
    await tester.pumpWidget(
      MaterialApp(
        home: RecurringPaymentsScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Повторные платежи и подписки'), findsOneWidget);
    expect(find.text('Яндекс'), findsOneWidget);
    expect(find.text('Оплатить сейчас'), findsWidgets);
  });

  testWidgets('IosHomeWidgetPreview allows switching between Winter Arc and Capybara Predictions and has 1-tap Pin button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final controller = FinanceController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: IosHomeWidgetPreview(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Initial mode is Winter Arc
    expect(find.text('WINTER ARC'), findsOneWidget);
    expect(find.text('Установить Winter Arc на рабочий стол'), findsOneWidget);
    expect(find.text('Пн'), findsOneWidget);
    expect(find.text('Вс'), findsOneWidget);

    // 2. Switch to Capybara mode
    await tester.tap(find.text('Капибара 2×2'));
    await tester.pumpAndSettle();

    expect(find.text('КАПИБАРА'), findsOneWidget);
    expect(find.text('Установить Предсказания Капибары'), findsOneWidget);
    expect(find.text('Новая мысль'), findsOneWidget);

    // 3. Cycle quote
    await tester.tap(find.text('Новая мысль'));
    await tester.pumpAndSettle();
    expect(find.text('КАПИБАРА'), findsOneWidget);
  });

  test('Winter Arc streak persists across controller reloads', () async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.clearAll();
    final controller1 = FinanceController();
    await controller1.loadFromStorage();

    controller1.checkInWinterDay(force: true);
    expect(controller1.noSpendStreak, 1);
    expect(controller1.isWinterCheckedToday, true);

    await Future.delayed(const Duration(milliseconds: 50));

    // Simulate relaunch
    final controller2 = FinanceController();
    await controller2.loadFromStorage();

    expect(controller2.noSpendStreak, 1);
    expect(controller2.isWinterCheckedToday, true);
  });
}


