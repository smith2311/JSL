class AccountDetails {
  final int clientId;
  final String clientName;
  final String? gender;
  final String? groupCode;
  final String? customerType;
  final String? panNumber;
  final String? mobile;
  final String? emailId;
  final String? rmName;
  final String? rmMobile;
  final String? rmEmail;
  final String? bseClientId;
  final String? kycStatus;
  final String? accountType;
  final List<String>? familyMembers;

  AccountDetails({
    required this.clientId,
    required this.clientName,
    this.gender,
    this.groupCode,
    this.customerType,
    this.panNumber,
    this.mobile,
    this.emailId,
    this.rmName,
    this.rmMobile,
    this.rmEmail,
    this.bseClientId,
    this.kycStatus,
    this.accountType,
    this.familyMembers,
  });

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    return AccountDetails(
      clientId: json['client_id'] ?? 0,
      clientName: json['client_name'] ?? '',
      gender: json['gender'],
      groupCode: json['group_code'],
      customerType: json['customer_type'],
      panNumber: json['pan_number'],
      mobile: json['mobile'],
      emailId: json['email_id'],
      rmName: json['rm_name'],
      rmMobile: json['rm_mobile'],
      rmEmail: json['rm_email'],
      bseClientId: json['bse_client_id'],
      kycStatus: json['kyc_status'],
      accountType: json['account_type'],
      familyMembers: json['family_members'] != null
          ? List<String>.from(json['family_members'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'client_name': clientName,
      'gender': gender,
      'group_code': groupCode,
      'customer_type': customerType,
      'pan_number': panNumber,
      'mobile': mobile,
      'email_id': emailId,
      'rm_name': rmName,
      'rm_mobile': rmMobile,
      'rm_email': rmEmail,
      'bse_client_id': bseClientId,
      'kyc_status': kycStatus,
      'account_type': accountType,
      'family_members': familyMembers,
    };
  }
}