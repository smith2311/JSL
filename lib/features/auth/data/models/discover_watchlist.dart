class Fund {
  final String fundName;
  final String fundType;
  final String fundSubType;
  final int minimumInvestment;
  final double threeYearReturn;
  final int totalCustomers;

  Fund({
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.minimumInvestment,
    required this.threeYearReturn,
    required this.totalCustomers,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      fundName: json['fund_name'],
      fundType: json['fund_type'],
      fundSubType: json['fund_sub_type'],
      minimumInvestment: json['minimum_investment'],
      threeYearReturn: (json['three_year_return'] as num).toDouble(),
      totalCustomers: json['total_customers'],
    );
  }
}