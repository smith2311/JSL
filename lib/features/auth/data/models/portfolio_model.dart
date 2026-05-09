import 'package:intl/intl.dart';

DateTime parseApiDate(String dateStr) {
  try {
    // Your API format: "3 Sep 2025"
    final formatter = DateFormat('d MMM yyyy');
    return formatter.parse(dateStr);
  } catch (_) {
    return DateTime.now(); // fallback
  }
}

class OrderModel {
  final int orderId;
  final String orderStatus;
  final String clientName;
  final String fundName;
  final int investedAmount; // 👈 changed to int
  final DateTime investmentDate;
  final String orderType;
  final String bseId;

  OrderModel({
    required this.orderId,
    required this.orderStatus,
    required this.clientName,
    required this.fundName,
    required this.investedAmount,
    required this.investmentDate,
    required this.orderType,
    required this.bseId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['investment_date'] as String;
    DateTime parsedDate;
    try {
      parsedDate = DateFormat('d MMM yyyy').parse(dateStr);
    } catch (_) {
      parsedDate = DateTime.now(); // fallback
    }

    return OrderModel(
      orderId: json['order_id'] as int,
      orderStatus: json['order_status'] as String,
      clientName: json['client_name'] as String,
      fundName: json['fund_name'] as String,
      investedAmount: (json['invested_amount'] as num? ?? 0).toInt(), // 👈 safe conversion
      investmentDate: parsedDate,
      orderType: json['order_type'] as String,
      bseId: json['bse_id'] as String,
    );
  }
}