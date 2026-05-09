class PopularFund {
  final int fundId;
  final String fundName;
  final String fundType;
  final String fundSubType;
  final double minimumInvestment;
  final double threeYearReturn;
  final int totalCustomers;

  PopularFund({
    required this.fundId,
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.minimumInvestment,
    required this.threeYearReturn,
    required this.totalCustomers,
  });

  factory PopularFund.fromJson(Map<String, dynamic> json) {
    return PopularFund(
      fundId: json['fund_id'] as int? ?? 0,
      fundName: json['fund_name'] as String? ?? '',
      fundType: json['fund_type'] as String? ?? '',
      fundSubType: json['fund_sub_type'] as String? ?? '',
      // Safe parsing for numeric fields - handle null, int, double, and string
      minimumInvestment: _parseDouble(json['minimum_investment']),
      threeYearReturn: _parseDouble(json['three_year_return']),
      totalCustomers: _parseInt(json['total_customers']),
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper method to safely parse int values
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'fund_id': fundId,
      'fund_name': fundName,
      'fund_type': fundType,
      'fund_sub_type': fundSubType,
      'minimum_investment': minimumInvestment,
      'three_year_return': threeYearReturn,
      'total_customers': totalCustomers,
    };
  }
}