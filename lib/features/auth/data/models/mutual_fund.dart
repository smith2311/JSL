class MutualFund {
  final int fundId;
  final String fundName;
  final String fundType;
  final String fundSubType;
  final double? minimumInvestment;
  final double threeYearReturn;
  final int totalCustomers;
  final double rating;

  MutualFund({
    required this.fundId,
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.minimumInvestment,
    required this.threeYearReturn,
    required this.totalCustomers,
    required this.rating,
  });

  factory MutualFund.fromJson(Map<String, dynamic> json) {
    return MutualFund(
      fundId: json['fund_id'] is String
          ? int.tryParse(json['fund_id']) ?? 0
          : (json['fund_id'] ?? 0),
      fundName: json['fund_name'] ?? '',
      fundType: json['fund_type'] ?? '',
      fundSubType: json['fund_sub_type'] ?? '',
      minimumInvestment: (json['minimum_investment'] as num?)?.toDouble(),
      threeYearReturn: (json['three_year_return'] as num?)?.toDouble() ?? 0.0,
      totalCustomers: json['total_customers'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helpers for UI
  String get minInvestmentDisplay =>
      minimumInvestment != null ? "₹${minimumInvestment!.toStringAsFixed(0)}" : "-";

  String get threeYearReturnDisplay =>
      "${threeYearReturn.toStringAsFixed(2)}%";
}