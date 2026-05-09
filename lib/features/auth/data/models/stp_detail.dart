// Add this to your swp_detail.dart file

class StpDetailModel {
  final int fundIdFrom;
  final String fundNameFrom;
  final int fundIdTo;
  final String fundNameTo;
  final String fundCategoryFrom;
  final String fundSubCategoryFrom;
  final String fundCategoryTo;
  final String fundSubCategoryTo;
  final int? ratingFrom;
  final int? ratingTo;
  final double amount;
  final double currentAmount;
  final String frequency;
  final int noOfInstallments;
  final int successfulInvestments;
  final String bankName;
  final String accountNo;
  final String folioNo;
  final String stpId;
  final String startDate;
  final String endDate;
  final String registrationDate;
  final String nextInstallmentDate;
  final String status;
  final String clientName;
  final String sxpType;

  StpDetailModel({
    required this.fundIdFrom,
    required this.fundNameFrom,
    required this.fundIdTo,
    required this.fundNameTo,
    required this.fundCategoryFrom,
    required this.fundSubCategoryFrom,
    required this.fundCategoryTo,
    required this.fundSubCategoryTo,
    this.ratingFrom,
    this.ratingTo,
    required this.amount,
    required this.currentAmount,
    required this.frequency,
    required this.noOfInstallments,
    required this.successfulInvestments,
    required this.bankName,
    required this.accountNo,
    required this.folioNo,
    required this.stpId,
    required this.startDate,
    required this.endDate,
    required this.registrationDate,
    required this.nextInstallmentDate,
    required this.status,
    required this.clientName,
    required this.sxpType,
  });

  factory StpDetailModel.fromJson(Map<String, dynamic> json) {
    return StpDetailModel(
      fundIdFrom: json['fund_id_from'] ?? 0,
      fundNameFrom: json['fund_name_from'] ?? '',
      fundIdTo: json['fund_id_to'] ?? 0,
      fundNameTo: json['fund_name_to'] ?? '',
      fundCategoryFrom: json['fund_category_from'] ?? '',
      fundSubCategoryFrom: json['fund_sub_category_from'] ?? '',
      fundCategoryTo: json['fund_category_to'] ?? '',
      fundSubCategoryTo: json['fund_sub_category_to'] ?? '',
      ratingFrom: json['rating_from'],
      ratingTo: json['rating_to'],
      amount: (json['amount'] ?? 0).toDouble(),
      currentAmount: (json['current_amount'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? '',
      noOfInstallments: json['no_of_installments'] ?? 0,
      successfulInvestments: json['successful_investments'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNo: json['account_no'] ?? '',
      folioNo: json['folio_no'] ?? '',
      stpId: json['stp_id'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      registrationDate: json['registration_date'] ?? '',
      nextInstallmentDate: json['next_installment_date'] ?? '',
      status: json['status'] ?? '',
      clientName: json['client_name'] ?? '',
      sxpType: json['sxp_type'] ?? '',
    );
  }
}