// FILE: bank_details_model.dart

class BankDetailsResponse {
  final int status;
  final String message;
  final BankDetailsData data;

  BankDetailsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory BankDetailsResponse.fromJson(Map<String, dynamic> json) {
    return BankDetailsResponse(
      status: json['status'] as int,
      message: json['message'] as String,
      data: BankDetailsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class BankDetailsData {
  final List<BankAccount> dataList;

  BankDetailsData({required this.dataList});

  factory BankDetailsData.fromJson(Map<String, dynamic> json) {
    return BankDetailsData(
      dataList: (json['data_list'] as List)
          .map((item) => BankAccount.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BankAccount {
  final String accountOwner;
  final String ifscCode;
  final String accountNo;
  final String accountType;

  BankAccount({
    required this.accountOwner,
    required this.ifscCode,
    required this.accountNo,
    required this.accountType,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      accountOwner: json['account_owner'] as String,
      ifscCode: json['ifsc_code'] as String,
      accountNo: json['account_no'] as String,
      accountType: json['account_type'] as String,
    );
  }
}