import 'package:ledgerly_app/constants/enums.dart';

class Transaction {
  final String id;
  final String userId;
  final String partyId;
  final double amount;
  final String description;
  final TransactionType transactionType;
  final PaymentMode paymentMode;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.partyId,
    required this.amount,
    required this.description,
    required this.transactionType,
    required this.paymentMode,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      partyId: json['party_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      transactionType: TransactionType.fromValue(json['transaction_type'] as String),
      paymentMode: PaymentMode.fromValue(json['payment_mode'] as String? ?? 'None'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get defaultTitle {
    switch (transactionType) {
      case TransactionType.got:
        return 'Received Amount';
      case TransactionType.gave:
        return 'Given Amount';
      case TransactionType.toReceive:
        return 'Amount to be Received';
      case TransactionType.toGive:
        return 'Amount to be Given';
    }
  }

  String get displayTitle =>
      description.isNotEmpty ? description : defaultTitle;

  String get amountPrefix {
    switch (transactionType) {
      case TransactionType.got:
      case TransactionType.toReceive:
        return '+';
      case TransactionType.gave:
      case TransactionType.toGive:
        return '-';
    }
  }

  bool get isPositive =>
      transactionType == TransactionType.got ||
      transactionType == TransactionType.toReceive;
}
