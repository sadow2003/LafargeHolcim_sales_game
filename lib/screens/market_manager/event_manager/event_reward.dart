class MoneyReward {
  final double amount;

  const MoneyReward({required this.amount});

  Map<String, dynamic> toMap() => {'amount': amount};

  static MoneyReward fromMap(Map<String, dynamic> m) =>
      MoneyReward(amount: ((m['amount'] as num?) ?? 0).toDouble());

  String get display {
    final n = amount;
    if (n == n.truncateToDouble()) {
      return '${n.toInt()} MAD';
    }
    return '$n MAD';
  }
}
