import 'package:ledgerly_app/constants/enums.dart';

class Party {
  final String id;
  final String name;
  final String avatarText;
  final double amount;
  final PartyType partyType;
  final DateTime? dueDate;
  final DateTime createdAt;

  Party({
    required this.id,
    required this.name,
    required this.avatarText,
    required this.amount,
    required this.partyType,
    this.dueDate,
    required this.createdAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarText: json['avatar_text'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      partyType: PartyType.fromValue(json['party_type'] as String? ?? 'Customer'),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatar_text': avatarText,
      'amount': amount,
      'party_type': partyType.value,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCustomer => partyType == PartyType.customer;
}
