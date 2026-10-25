import 'transaction_type.dart';

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String categoryId;
  final String accountId;
  final String? toAccountId; 
  final String? note;

  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    this.note,
  });

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      note: note ?? this.note,
    );
  }
}
