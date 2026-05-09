// Add this file to: features/auth/data/models/switch_detail.dart

class SchemeConstraint {
  final double? minAmount;
  final double? maxAmount;
  final double? minUnits;
  final double? maxUnits;
  final List<String>? frequencyDates;
  final int? minInstallments;
  final int? maxInstallments;

  SchemeConstraint({
    this.minAmount,
    this.maxAmount,
    this.minUnits,
    this.maxUnits,
    this.frequencyDates,
    this.minInstallments,
    this.maxInstallments,
  });

  factory SchemeConstraint.fromJson(Map<String, dynamic> json) {
    return SchemeConstraint(
      minAmount: (json['min_amount'] ?? 0).toDouble(), // ✅ Handle nullable
      maxAmount: (json['max_amount'] ?? double.infinity).toDouble(),
      minUnits: (json['min_units'] ?? 0).toDouble(),
      maxUnits: (json['max_units'] ?? double.infinity).toDouble(),
      minInstallments: json['min_installments'] ?? 1,
      maxInstallments: json['max_installments'] ?? 999,
      frequencyDates: (json['frequency_dates'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'min_units': minUnits,
      'max_units': maxUnits,
      'frequency_dates': frequencyDates,
      'min_installments': minInstallments,
      'max_installments': maxInstallments,
    };
  }
}

class BseClient {
  final String clientCode;
  final String clientName;
  final String? email;
  final String? mobile;

  BseClient({
    required this.clientCode,
    required this.clientName,
    this.email,
    this.mobile,
  });

  factory BseClient.fromJson(Map<String, dynamic> json) {
    return BseClient(
      clientCode: json['client_code'] ?? '',
      clientName: json['client_name'] ?? '',
      email: json['email'],
      mobile: json['mobile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_code': clientCode,
      'client_name': clientName,
      'email': email,
      'mobile': mobile,
    };
  }
}