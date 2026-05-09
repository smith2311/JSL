class ConfirmSwpDetails {
  final double amount;
  final String frequency;
  final String swpDate;
  final int noOfInstallments;
  final String bseClientId;
  final String withdrawalBy;
  final bool firstOrder;

  ConfirmSwpDetails({
    required this.amount,
    required this.frequency,
    required this.swpDate,
    required this.noOfInstallments,
    required this.bseClientId,
    required this.withdrawalBy,
    required this.firstOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'frequency': frequency,
      'swp_date': swpDate,
      'no_of_installments': noOfInstallments,
      'bse_client_id': bseClientId,
      'withdrawal_by': withdrawalBy,
      'first_order': firstOrder,
    };
  }
}
