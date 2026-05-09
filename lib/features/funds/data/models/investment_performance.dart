class InvestmentPerformance {
  final String period;
  final double fundReturn;
  final double benchmarkReturn;

  InvestmentPerformance({
    required this.period,
    required this.fundReturn,
    required this.benchmarkReturn,
  });

  factory InvestmentPerformance.fromJson(Map<String, dynamic> json) {
    return InvestmentPerformance(
      period: json['period'] as String,
      fundReturn: (json['fund_return'] as num).toDouble(),
      benchmarkReturn: (json['benchmark_return'] as num).toDouble(),
    );
  }
}

class InvestmentPerformanceResponse {
  final int status;
  final String message;
  final List<InvestmentPerformance> performance;

  InvestmentPerformanceResponse({
    required this.status,
    required this.message,
    required this.performance,
  });

  factory InvestmentPerformanceResponse.fromJson(Map<String, dynamic> json) {
    return InvestmentPerformanceResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      performance: (json['data']['performance'] as List)
          .map((e) => InvestmentPerformance.fromJson(e))
          .toList(),
    );
  }
}