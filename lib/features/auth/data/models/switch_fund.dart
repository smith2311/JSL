class SwitchFundModel {
  final String fundName;
  final String fundType;
  final String fundSubType;
  final double returnPercentage;
  final int fundId;

  SwitchFundModel({
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.returnPercentage,
    required this.fundId,
  });

  factory SwitchFundModel.fromJson(Map<String, dynamic> json) {
    return SwitchFundModel(
      fundName: json['fund_name'] ?? '',
      fundType: json['fund_type'] ?? '',
      fundSubType: json['fund_sub_type'] ?? '',
      returnPercentage: (json['return_percentage'] ?? 0).toDouble(),
      fundId: json['fund_id'] ?? 0,
    );
  }
}

class SwitchFundsListResponse {
  final int pageIndex;
  final int totalRecords;
  final int totalPages;
  final int pageSize;
  final List<SwitchFundModel> dataList;

  SwitchFundsListResponse({
    required this.pageIndex,
    required this.totalRecords,
    required this.totalPages,
    required this.pageSize,
    required this.dataList,
  });

  factory SwitchFundsListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final list = data['data_list'] as List;

    return SwitchFundsListResponse(
      pageIndex: data['page_index'] ?? 1,
      totalRecords: data['total_records'] ?? 0,
      totalPages: data['total_pages'] ?? 0,
      pageSize: data['page_size'] ?? 10,
      dataList: list.map((e) => SwitchFundModel.fromJson(e)).toList(),
    );
  }
}