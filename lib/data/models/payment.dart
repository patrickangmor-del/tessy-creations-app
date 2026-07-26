class Payment {
  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.date,
  });

  final String id;
  final String orderId;
  final double amount;

  /// ISO yyyy-MM-dd — payments are tracked by day, not time.
  final String date;

  Map<String, Object?> toMap() {
    return {'id': id, 'orderId': orderId, 'amount': amount, 'date': date};
  }

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
    );
  }
}
