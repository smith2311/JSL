class Nominee {
  final String firstName;
  final String middleName;
  final String lastName;
  final String dob;
  final String relation;
  final double applicablePercentage;
  final String idType;
  final String idNumber;
  final String mobile;
  final String email;
  final String address1;
  final String address2;
  final String address3;
  final String city;
  final String pin;
  final String state;
  final String country;
  final bool isMinor;
  final String guardianName;
  final String guardianPan;

  Nominee({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.dob,
    required this.relation,
    required this.applicablePercentage,
    required this.idType,
    required this.idNumber,
    required this.mobile,
    required this.email,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.city,
    required this.pin,
    required this.state,
    required this.country,
    required this.isMinor,
    required this.guardianName,
    required this.guardianPan,
  });

  factory Nominee.fromJson(Map<String, dynamic> json) {
    final apiIdType = json['id_type'] ?? '';
    final apiRelation = json['relation'] ?? '';

    String nullToEmpty(dynamic value) => value?.toString() ?? '';

    // ✅ FIX: API returns "allocation_percent" not "applicable_percentage"
    final allocationPercent = json['allocation_percent'] ?? json['applicable_percentage'] ?? 0;

    print('🔍 Parsing Nominee:');
    print('   allocation_percent from API: $allocationPercent');
    print('   Type: ${allocationPercent.runtimeType}');

    return Nominee(
      firstName: nullToEmpty(json['first_name']),
      middleName: nullToEmpty(json['middle_name']),
      lastName: nullToEmpty(json['last_name']),
      dob: nullToEmpty(json['dob']),
      relation: apiRelation,
      applicablePercentage: (allocationPercent is int)
          ? allocationPercent.toDouble()
          : (allocationPercent is double)
          ? allocationPercent
          : double.tryParse(allocationPercent.toString()) ?? 0.0,
      idType: apiIdType,
      idNumber: nullToEmpty(json['id_number']),
      mobile: nullToEmpty(json['mobile']),
      email: nullToEmpty(json['email']),
      address1: nullToEmpty(json['address_1']),
      address2: nullToEmpty(json['address_2']),
      address3: nullToEmpty(json['address_3']),
      city: nullToEmpty(json['city']),
      pin: nullToEmpty(json['pin']),
      state: nullToEmpty(json['state']),
      country: nullToEmpty(json['country']),
      isMinor: json['is_minor'] == true || json['is_minor'] == 1,
      guardianName: nullToEmpty(json['guardian_name']),
      guardianPan: nullToEmpty(json['guardian_pan']),
    );
  }

  Map<String, dynamic> toJson() {
    dynamic emptyToNull(String value) => value.isEmpty ? null : value;

    return {
      'first_name': firstName,
      'middle_name': emptyToNull(middleName),
      'last_name': lastName,
      'dob': dob,
      'relation': relation,
      'applicable_percentage': applicablePercentage.toString(),
      'id_type': idType,
      'id_number': idNumber,
      'mobile': mobile,
      'email': email,
      'address_1': address1,
      'address_2': emptyToNull(address2),
      'address_3': emptyToNull(address3),
      'city': city,
      'pin': emptyToNull(pin),
      'state': state,
      'country': country,
      'is_minor': isMinor,
      'guardian_name': emptyToNull(guardianName),
      'guardian_pan': emptyToNull(guardianPan),
    };
  }
}