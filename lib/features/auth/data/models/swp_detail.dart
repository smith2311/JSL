
class SwpDetailModel {
  final int fundId;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final int? rating;
  final double amount;
  final double currentAmount;
  final String frequency;
  final String swpDate;
  final int successfulWithdrawals;
  final String bankName;
  final String accountNo;
  final String folioNo;
  final String swpId;
  final String endDate;
  final String nextWithdrawalDate;
  final String? previousWithdrawalDate;
  final String status;
  final String clientName;
  final String regDate;
  final String sxpType;

  SwpDetailModel({
    required this.fundId,
    required this.fundName,
    required this.fundCategory,
    required this.fundSubCategory,
    this.rating,
    required this.amount,
    required this.currentAmount,
    required this.frequency,
    required this.swpDate,
    required this.successfulWithdrawals,
    required this.bankName,
    required this.accountNo,
    required this.folioNo,
    required this.swpId,
    required this.endDate,
    required this.nextWithdrawalDate,
    this.previousWithdrawalDate,
    required this.status,
    required this.clientName,
    required this.regDate,
    required this.sxpType,
  });

  factory SwpDetailModel.fromJson(Map<String, dynamic> json) {
    return SwpDetailModel(
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      fundCategory: json['fund_category'] ?? '',
      fundSubCategory: json['fund_sub_category'] ?? '',
      rating: json['rating'],
      amount: (json['amount'] ?? 0).toDouble(),
      currentAmount: (json['current_amount'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? '',
      swpDate: json['swp_date'] ?? '',
      successfulWithdrawals: json['successful_withdrawals'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNo: json['account_no'] ?? '',
      folioNo: json['folio_no'] ?? '',
      swpId: json['swp_id'] ?? '',
      endDate: json['end_date'] ?? '',
      nextWithdrawalDate: json['next_withdrawal_date'] ?? '',
      previousWithdrawalDate: json['previous_withdrawal_date'],
      status: json['status'] ?? '',
      clientName: json['client_name'] ?? '',
      regDate: json['reg_date'] ?? '',
      sxpType: json['sxp_type'] ?? '',
    );
  }
}

class CancelReason {
  final int id;
  final String reason;

  CancelReason({
    required this.id,
    required this.reason,
  });

  factory CancelReason.fromJson(Map<String, dynamic> json) {
    // ✅ Handle both 'id' and 'value' fields, with safe null handling
    final idValue = json['id'] ?? json['value'];

    return CancelReason(
      id: (idValue is int) ? idValue : int.tryParse(idValue?.toString() ?? '0') ?? 0,
      reason: json['reason'] ?? json['label'] ?? '',
    );
  }
}