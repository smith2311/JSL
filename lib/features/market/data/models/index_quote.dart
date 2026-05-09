class IndexQuote {
  final String name;
  final double value;
  final double difference;
  final double percentage;

  IndexQuote({
    required this.name,
    required this.value,
    required this.difference,
    required this.percentage,
  });

  factory IndexQuote.fromJson(Map<String, dynamic> json) {
    return IndexQuote(
      name: json["name"] ?? "",
      value: (json["value"] ?? 0).toDouble(),
      difference: (json["difference"] ?? 0).toDouble(),
      percentage: (json["percentage"] ?? 0).toDouble(),
    );
  }

  String get formattedValue => value.toStringAsFixed(2);

  String get changeText =>
      "${difference >= 0 ? "+" : ""}$difference (${percentage.toStringAsFixed(2)}%)";

  bool get isNegative => difference < 0;
}