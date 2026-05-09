import 'package:flutter/material.dart';
class Mandate {
  final int mandateId;
  final String bankName;
  final String accountNo;
  final String ifsc;
  final double amount;
  final String status;

  Mandate({
    required this.mandateId,
    required this.bankName,
    required this.accountNo,
    required this.ifsc,
    required this.amount,
    required this.status,
  });

  factory Mandate.fromJson(Map<String, dynamic> json) {
    return Mandate(
      mandateId: json['mandate_id'] ?? 0,
      bankName: json['bank_name'] ?? '',
      accountNo: json['account_no'] ?? '',
      ifsc: json['ifsc'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }

  // Get masked account number (XX XXXX 2349)
  String get maskedAccountNo {
    if (accountNo.length >= 4) {
      final lastFour = accountNo.substring(accountNo.length - 4);
      return 'XX XXXX $lastFour';
    }
    return accountNo;
  }

  // Get first letter for avatar
  String get bankInitial {
    return bankName.isNotEmpty ? bankName[0].toUpperCase() : 'B';
  }

  // Get status color
  MandateStatusInfo get statusInfo {
    switch (status.toLowerCase()) {
      case 'initiated':
        return MandateStatusInfo(
          color: const Color(0xFF03850D),
          textColor: Colors.white,
          label: 'Initiated',
        );
      case 'investor auth awaited':
        return MandateStatusInfo(
          color: const Color(0xFFFFA800),
          textColor: Colors.white,
          label: 'Investor Auth Awaited',
        );
      case 'rejected':
        return MandateStatusInfo(
          color: const Color(0xFFFF5252),
          textColor: Colors.white,
          label: 'Rejected',
        );
      case 'approved':
      case 'active':
        return MandateStatusInfo(
          color: const Color(0xFF4CAF50),
          textColor: Colors.white,
          label: 'Approved',
        );
      default:
        return MandateStatusInfo(
          color: Colors.grey,
          textColor: Colors.white,
          label: status,
        );
    }
  }
}

class MandateStatusInfo {
  final Color color;
  final Color textColor;
  final String label;

  MandateStatusInfo({
    required this.color,
    required this.textColor,
    required this.label,
  });
}