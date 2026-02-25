class Profile {
  final String id;
  final String businessName;
  final double cashInHand;
  final double bankBalance;

  Profile({
    required this.id,
    required this.businessName,
    required this.cashInHand,
    required this.bankBalance,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? 'My Business',
      cashInHand: (json['cash_in_hand'] as num?)?.toDouble() ?? 0.0,
      bankBalance: (json['bank_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static Profile empty() {
    return Profile(
      id: '',
      businessName: 'My Business',
      cashInHand: 0.0,
      bankBalance: 0.0,
    );
  }
}
