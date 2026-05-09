// lib/features/auth/data/models/transaction_history_item.dart

class TransactionHistoryItem {
  final String date;
  final double amount;
  final String status;
  final bool isUnits;

  TransactionHistoryItem({
    required this.date,
    required this.amount,
    required this.status,
    required this.isUnits,
  });

  factory TransactionHistoryItem.fromJson(Map<String, dynamic> json) {
    return TransactionHistoryItem(
      date: json['transaction_date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
      isUnits: json['is_units'] ?? false,
    );
  }
}