class PortfolioFundDetailModel {
  final int fundId;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final double rating;
  final double returns;
  final double returnPercentage;
  final double current;
  final double invested;
  final double oneDayReturn;
  final double oneDayReturnPercentage;
  final double xirr;
  final double balanceUnits;
  final double averageNav;
  final String folioNo;
  final String type;
  final String investedDate;
  final String holdingPattern;
  final String jointHolder;
  final int clientId;
  final String? bankName;
  final String? accountNo;

  PortfolioFundDetailModel({
    required this.fundId,
    required this.fundName,
    required this.fundCategory,
    required this.fundSubCategory,
    required this.rating,
    required this.returns,
    required this.returnPercentage,
    required this.current,
    required this.invested,
    required this.oneDayReturn,
    required this.oneDayReturnPercentage,
    required this.xirr,
    required this.balanceUnits,
    required this.averageNav,
    required this.folioNo,
    required this.type,
    required this.investedDate,
    required this.holdingPattern,
    required this.jointHolder,
    required this.clientId,
    this.bankName,
    this.accountNo,
  });

  factory PortfolioFundDetailModel.fromJson(Map<String, dynamic> json) {
    return PortfolioFundDetailModel(
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      fundCategory: json['fund_category'] ?? '',
      fundSubCategory: json['fund_sub_category'] ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      returns: (json['returns'] ?? 0).toDouble(),
      returnPercentage: (json['return_percentage'] ?? 0).toDouble(),
      current: (json['current'] ?? 0).toDouble(),
      invested: (json['invested'] ?? 0).toDouble(),
      oneDayReturn: (json['one_day_return'] ?? 0).toDouble(),
      oneDayReturnPercentage: (json['one_day_return_percentage'] ?? 0).toDouble(),
      xirr: (json['xirr'] ?? 0).toDouble(),
      balanceUnits: (json['balance_units'] ?? 0).toDouble(),
      averageNav: (json['average_nav'] ?? 0).toDouble(),
      folioNo: json['folio_no'] ?? '',
      type: json['type'] ?? '',
      investedDate: json['invested_date'] ?? '',
      holdingPattern: json['holding_pattern'] ?? '',
      jointHolder: json['joint_holder'] ?? '',
      clientId: json['client_id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNo: json['account_no'] ?? '',
    );
  }
}