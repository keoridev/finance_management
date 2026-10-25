import 'package:flutter_test/flutter_test.dart';
import 'package:finance_management/services/mbank_parser_service.dart';
import 'package:finance_management/models/transaction_type.dart';

void main() {
  group('MBankParserService Tests', () {
    test('Parses Salary Income with Som', () {
      final text = 'MBank: Зачисление зарплаты 45 000 сом. Баланс: 52 300 сом';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 45000.0);
      expect(parsed.type, TransactionType.income);
      expect(parsed.isSalary, true);
      expect(parsed.categoryId, 'cat_salary');
      expect(parsed.balanceAfter, 52300.0);
    });

    test('Parses Incoming Transfer with KGS', () {
      final text = 'Пополнение на 12 500.50 KGS. Карта *4820. Доступно: 24 100.50 KGS';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 12500.50);
      expect(parsed.type, TransactionType.income);
      expect(parsed.cardLastDigits, '4820');
      expect(parsed.balanceAfter, 24100.50);
    });

    test('Parses Grocery Store Expense', () {
      final text = 'MBank: Оплата покупки 1 250 сом, Globus. Доступно: 18 000 сом';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1250.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.categoryId, 'cat_groceries');
    });

    test('Parses Taxi / Transport Expense', () {
      final text = 'Списание 180 KGS. Яндекс Такси. Баланс: 4 200 KGS';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 180.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.categoryId, 'cat_transport');
    });

    test('Parses Latin Translit SMS', () {
      final text = 'Karta *4820 popolnena na 30000.00 KGS. Ostatok: 35000.00 KGS';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 30000.0);
      expect(parsed.type, TransactionType.income);
      expect(parsed.cardLastDigits, '4820');
    });

    test('Parses Cafe Faiza as Restaurant Category', () {
      final text = 'Оплата: Фаиза 650 сом. Чек №4819. Баланс: 42 100 сом';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 650.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.categoryId, 'cat_restaurants');
    });

    test('Parses Hypermarket Frunze as Groceries Category', () {
      final text = 'Оплата Фрунзе 1 420 сом проведена успешно. Остаток: 40 680 сом';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 1420.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.categoryId, 'cat_groceries');
    });

    test('Parses Wildberries as Shopping Category', () {
      final text = 'Чек: Оплата Wildberries 3 500 сом выполнено. Доступно: 36 950 сом';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 3500.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.categoryId, 'cat_shopping');
    });

    test('Parses Neman Pharmacy as Health Category', () {
      final text = 'Квитанция: Аптека Неман 850 сом. Оплата прошла. Баланс: 36 100 сом';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 850.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.categoryId, 'cat_health');
    });

    test('Parses NFC push with store name at end: Оплата 125 с. Баланс 469 с. Кафе Фаиза', () {
      final text = 'Оплата 125 с. Баланс 469 с. Кафе Фаиза';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 125.0);
      expect(parsed.balanceAfter, 469.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.title, 'Кафе Фаиза');
      expect(parsed.categoryId, 'cat_restaurants');
    });

    test('Parses unlisted grocery store: Оплата 340 с. Баланс 1200 с. Магазин Байэль', () {
      final text = 'Оплата 340 с. Баланс 1200 с. Магазин Байэль';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 340.0);
      expect(parsed.balanceAfter, 1200.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.title, 'Магазин Байэль');
      expect(parsed.categoryId, 'cat_groceries');
    });

    test('Parses Google Pay NFC notification: 220 KGS в Sierra Coffee', () {
      final text = 'Google Pay: 220 KGS в Sierra Coffee';
      final parsed = MBankParserService.parse(text);

      expect(parsed, isNotNull);
      expect(parsed!.amount, 220.0);
      expect(parsed.type, TransactionType.expense);
      expect(parsed.title, 'Sierra Coffee');
      expect(parsed.categoryId, 'cat_restaurants');
    });
  });
}
