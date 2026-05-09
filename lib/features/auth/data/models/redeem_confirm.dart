
class ConfirmRedeemDetails {
  final double amount;
  final double units;
  final double taxesAndExitLoad;
  final double exitLoad;
  final double ltcg;
  final double taxOnLtcg;
  final double stcg;
  final double taxOnStcg;

  ConfirmRedeemDetails({
    required this.amount,
    required this.units,
    required this.taxesAndExitLoad,
    required this.exitLoad,
    required this.ltcg,
    required this.taxOnLtcg,
    required this.stcg,
    required this.taxOnStcg,
  });

  factory ConfirmRedeemDetails.fromJson(Map<String, dynamic> json) {
    return ConfirmRedeemDetails(
      amount: (json['amount'] ?? 0).toDouble(),
      units: (json['units'] ?? 0).toDouble(),
      taxesAndExitLoad: (json['taxes_and_exit_load'] ?? 0).toDouble(),
      exitLoad: (json['exit_load'] ?? 0).toDouble(),
      ltcg: (json['ltcg'] ?? 0).toDouble(),
      taxOnLtcg: (json['tax_on_ltcg'] ?? 0).toDouble(),
      stcg: (json['stcg'] ?? 0).toDouble(),
      taxOnStcg: (json['tax_on_stcg'] ?? 0).toDouble(),
    );
  }
}