/// Model class for yearly SIP data
class YearlyData {
  final int year;
  final int investment;
  final int returns;
  final int totalValue;
  final int inflationAdjusted;
  final int monthlySip;

  YearlyData({
    required this.year,
    required this.investment,
    required this.returns,
    required this.totalValue,
    required this.inflationAdjusted,
    required this.monthlySip,
  });
}