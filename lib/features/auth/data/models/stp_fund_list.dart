// Model for Switch/STP Fund List

class StpFundListItem {
  final String fundName;
  final String fundType;
  final String fundSubType;
  final int returnPercentage;
  final int fundId;

  StpFundListItem({
    required this.fundName,
    required this.fundType,
    required this.fundSubType,
    required this.returnPercentage,
    required this.fundId,
  });

  factory StpFundListItem.fromJson(Map<String, dynamic> json) {
    return StpFundListItem(
      fundName: json['fund_name'] ?? '',
      fundType: json['fund_type'] ?? '',
      fundSubType: json['fund_sub_type'] ?? '',
      returnPercentage: json['return_percentage'] ?? 0,
      fundId: json['fund_id'] ?? 0,
    );
  }
}

class StpFundListResponse {
  final int pageIndex;
  final int totalRecords;
  final int totalPages;
  final int pageSize;
  final List<StpFundListItem> dataList;

  StpFundListResponse({
    required this.pageIndex,
    required this.totalRecords,
    required this.totalPages,
    required this.pageSize,
    required this.dataList,
  });

  factory StpFundListResponse.fromJson(Map<String, dynamic> json) {
    return StpFundListResponse(
      pageIndex: json['page_index'] ?? 1,
      totalRecords: json['total_records'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      pageSize: json['page_size'] ?? 10,
      dataList: (json['data_list'] as List<dynamic>?)
          ?.map((item) => StpFundListItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

// Model for SXP Constraints

class SxpConstraints {
  final List<int> frequencyDates;
  final int minInstallments;
  final int maxInstallments;
  final double minAmount;
  final double maxAmount;
  final double minUnits;
  final double maxUnits;

  SxpConstraints({
    required this.frequencyDates,
    required this.minInstallments,
    required this.maxInstallments,
    required this.minAmount,
    required this.maxAmount,
    required this.minUnits,
    required this.maxUnits,
  });

  factory SxpConstraints.fromJson(Map<String, dynamic> json) {
    return SxpConstraints(
      frequencyDates: (json['frequency_dates'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      minInstallments: json['min_installments'] ?? 0,
      maxInstallments: json['max_installments'] ?? 0,
      minAmount: (json['min_amount'] ?? 0).toDouble(),
      maxAmount: (json['max_amount'] ?? 0).toDouble(),
      minUnits: (json['min_units'] ?? 0).toDouble(),
      maxUnits: (json['max_units'] ?? 0).toDouble(),
    );
  }
}