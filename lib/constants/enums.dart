enum TransactionType {
  got('Got'),
  gave('Gave'),
  toReceive('To Receive'),
  toGive('To Give');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromValue(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.got,
    );
  }
}

enum PartyType {
  customer('Customer'),
  supplier('Supplier');

  final String value;
  const PartyType(this.value);

  static PartyType fromValue(String value) {
    return PartyType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PartyType.customer,
    );
  }
}

enum PaymentMode {
  none('None'),
  cash('Cash'),
  bank('Bank');

  final String value;
  const PaymentMode(this.value);

  static PaymentMode fromValue(String value) {
    return PaymentMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMode.none,
    );
  }
}
