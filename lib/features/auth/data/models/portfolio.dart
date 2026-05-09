// models/portfolio_model.dart

class PortfolioModel {
  final double totalInvestment;
  final double currentValue;
  final double totalReturn;
  final double returnPercentage;
  final double? oneDayReturn;
  final double? oneDayReturnPercentage;
  final double? xirr; // optional XIRR

  PortfolioModel({
    required this.totalInvestment,
    required this.currentValue,
    required this.totalReturn,
    required this.returnPercentage,
    this.oneDayReturn,
    this.oneDayReturnPercentage,
    this.xirr,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) {
    return PortfolioModel(
      totalInvestment: (json['total_investment'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      totalReturn: (json['total_return'] ?? 0).toDouble(),
      returnPercentage: (json['return_percentage'] ?? 0).toDouble(),
      oneDayReturn: json['1_day_return'] != null
          ? (json['1_day_return'] as num).toDouble()
          : null,
      oneDayReturnPercentage: json['1_day_return_percentage'] != null
          ? (json['1_day_return_percentage'] as num).toDouble()
          : null,
      xirr: json['xirr'] != null ? (json['xirr'] as num).toDouble() : null,
    );
  }
}

class FundModel {
  final int fundId;
  final String fundName;
  final String fundType;
  final String fundSubType;
  final double current;
  final double invested;
  final double xirr;
  final double absoluteReturn;
  final String folioNo;

  FundModel({
    required this.fundId,
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.current,
    required this.invested,
    required this.xirr,
    required this.absoluteReturn,
    required this.folioNo,
  });

  factory FundModel.fromJson(Map<String, dynamic> json) {
    return FundModel(
      fundId: json['fund_id'],
      fundName: json['fund_name'],
      fundType: json['fund_type'],
      fundSubType: json['fund_sub_type'],
      current: (json['current'] ?? 0).toDouble(),
      invested: (json['invested'] ?? 0).toDouble(),
      xirr: (json['xirr'] ?? 0).toDouble(),
      absoluteReturn: (json['absolute_return'] ?? 0).toDouble(),
      folioNo: json['folio_no'] ?? '',
    );
  }
}