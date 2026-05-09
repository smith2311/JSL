class JhaveriPick {
  final int fundId;
  final String fundName;
  final String fundType;
  final String fundSubType;
  final double threeYearReturn;
  final int minimumInvestment;
  final int totalCustomers;
  final double rating;

  JhaveriPick({
    required this.fundId,
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.minimumInvestment,
    required this.threeYearReturn,
    required this.totalCustomers,
    required this.rating,
  });

  factory JhaveriPick.fromJson(Map<String, dynamic> json) {
    return JhaveriPick(
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      fundType: json['fund_type'] ?? '',
      fundSubType: json['fund_sub_type'] ?? '',

      // FIXED: Handle both int and double from API, convert to int
      minimumInvestment: _parseMinimumInvestment(json['minimum_investment']),

      threeYearReturn: (json['three_year_return'] is double)
          ? json['three_year_return']
          : (json['three_year_return'] is int
          ? (json['three_year_return'] as int).toDouble()
          : double.tryParse(json['three_year_return'].toString()) ?? 0.0),

      totalCustomers: (json['total_customers'] is int)
          ? json['total_customers']
          : int.tryParse(json['total_customers'].toString()) ?? 0,

      rating: (json['rating'] is double)
          ? json['rating']
          : (json['rating'] is int
          ? (json['rating'] as int).toDouble()
          : double.tryParse(json['rating'].toString()) ?? 0.0),
    );
  }

  // Helper method to parse minimum_investment
  static int _parseMinimumInvestment(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt(); // Convert 1000.00 to 1000
    }

    // Try parsing as double first (handles "1000.00"), then convert to int
    final doubleValue = double.tryParse(value.toString());
    if (doubleValue != null) {
      return doubleValue.toInt();
    }

    return 0;
  }
}