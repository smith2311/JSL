class SipDetailModel {
  final String status;
  final int fundId;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final int? rating;
  final double amount;
  final double currentAmount;
  final String frequency;
  final String sipDate;
  final int successfulInvestments;
  final String bankName;
  final String accountNo;
  final String folioNo;
  final String sipId;
  final String regDate;
  final String nextInstallmentDate;
  final PauseDetails? pauseDetails;
  final String sipEndDate;
  final String? previousPaidDate;
  final String clientName;
  final String sxpType;
  final int minPause;
  final int maxPause;

  SipDetailModel({
    required this.status,
    required this.fundId,
    required this.fundName,
    required this.fundCategory,
    required this.fundSubCategory,
    this.rating,
    required this.amount,
    required this.currentAmount,
    required this.frequency,
    required this.sipDate,
    required this.successfulInvestments,
    required this.bankName,
    required this.accountNo,
    required this.folioNo,
    required this.sipId,
    required this.regDate,
    required this.nextInstallmentDate,
    this.pauseDetails,
    required this.sipEndDate,
    this.previousPaidDate,
    required this.clientName,
    required this.sxpType,
    required this.minPause,
    required this.maxPause,
  });

  factory SipDetailModel.fromJson(Map<String, dynamic> json) {
    PauseDetails? pauseDetails;

    // Only create pauseDetails if data exists and is not empty/null
    if (json['pause_details'] != null) {
      final pauseData = json['pause_details'] as Map<String, dynamic>;
      final startDate = pauseData['start_date'];
      final noOfInstallments = pauseData['no_of_installments'];
      final pauseEndDate = pauseData['pause_end_date'];

      // Check if any meaningful data exists
      if (startDate != null ||
          (noOfInstallments != null && noOfInstallments != 0) ||
          pauseEndDate != null) {
        pauseDetails = PauseDetails.fromJson(pauseData);
      }
    }

    return SipDetailModel(
      status: json['status'] ?? '',
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      fundCategory: json['fund_category'] ?? '',
      fundSubCategory: json['fund_sub_category'] ?? '',
      rating: json['rating'],
      amount: (json['amount'] ?? 0).toDouble(),
      currentAmount: (json['current_amount'] ?? 0).toDouble(),
      frequency: json['frequency'] ?? '',
      sipDate: json['sip_date'] ?? '',
      successfulInvestments: json['successful_investments'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNo: json['account_no'] ?? '',
      folioNo: json['folio_no'] ?? '',
      sipId: json['sip_id'] ?? '',
      regDate: json['reg_date'] ?? '',
      nextInstallmentDate: json['next_installment_date'] ?? '',
      pauseDetails: pauseDetails,
      sipEndDate: json['sip_end_date'] ?? '',
      previousPaidDate: json['previous_paid_date'],
      clientName: json['client_name'] ?? '',
      sxpType: json['sxp_type'] ?? '',
      minPause: 1, // Always keep as 1 as per requirement
      maxPause: json['max_pause'] ?? 3,
    );
  }

  bool get canPause {
    return successfulInvestments >= (minPause - 1) &&
        successfulInvestments < maxPause;
  }

  int get remainingPauseCount {
    return maxPause - successfulInvestments;
  }

  bool get isPaused {
    return status.toLowerCase().trim() == 'paused';
  }

  bool get isActive {
    return status.toLowerCase().trim() == 'active' ||
        status.toLowerCase().trim() == 'resumed';
  }

  bool get isCancelled {
    return status.toLowerCase().trim() == 'cancelled';
  }

  bool get showButtons {
    return !isCancelled;
  }
}

class PauseDetails {
  final String? startDate;
  final int noOfInstallments;
  final String? pauseEndDate;

  PauseDetails({
    this.startDate,
    required this.noOfInstallments,
    this.pauseEndDate,
  });

  factory PauseDetails.fromJson(Map<String, dynamic> json) {
    return PauseDetails(
      startDate: json['start_date'],
      noOfInstallments: json['no_of_installments'] ?? 0,
      pauseEndDate: json['pause_end_date'],
    );
  }

  bool get hasData {
    return startDate != null || noOfInstallments != 0 || pauseEndDate != null;
  }
}