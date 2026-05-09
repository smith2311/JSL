// features/funds/data/models/investment_return.dart

enum ReturnType { abs, cagr }

class InvestmentReturn {
  final String period;
  final double percentage;

  InvestmentReturn({
    required this.period,
    required this.percentage,
  });

  factory InvestmentReturn.fromJson(Map<String, dynamic> json) {
    return InvestmentReturn(
      period: json['period'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'percentage': percentage,
    };
  }
}

class InvestmentReturnsResponse {
  final int status;
  final String message;
  final List<InvestmentReturn> returns;

  InvestmentReturnsResponse({
    required this.status,
    required this.message,
    required this.returns,
  });

  factory InvestmentReturnsResponse.fromJson(Map<String, dynamic> json) {
    return InvestmentReturnsResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      returns: (json['data']['returns'] as List)
          .map((item) => InvestmentReturn.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': {
        'returns': returns.map((item) => item.toJson()).toList(),
      },
    };
  }
}