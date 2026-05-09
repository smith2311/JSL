class FundModel {
  final int fundId;
  final String fundName;
  final String fundType;
  final String fundSubType;
  final double current;
  final double invested;
  final double xirr;
  final double absoluteReturn;
  final String folioNo;
  final String clientName;

  FundModel({
    required this.fundId,
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.current,
    required this.invested,
    required this.xirr,
    required this.absoluteReturn,
    required this.folioNo,
    required this.clientName
  });

  factory FundModel.fromJson(Map<String, dynamic> json) {
    return FundModel(
      fundId: json['fund_id'] ?? 0,
      fundName: json['fund_name'] ?? '',
      fundType: json['fund_type'] ?? '',
      fundSubType: json['fund_sub_type'] ?? '',
      current: (json['current'] ?? 0).toDouble(),
      invested: (json['invested'] ?? 0).toDouble(),
      xirr: (json['xirr'] ?? 0).toDouble(),
      absoluteReturn: (json['absolute_return'] ?? 0).toDouble(),
      folioNo: json['folio_no'] ?? '',
      clientName: json['client_name'] ?? '',
    );
  }
}