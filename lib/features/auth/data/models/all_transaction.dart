class TransactionModel {
  final String transactionType;
  final String status;
  final double amount;
  final String date;
  final double price;
  final double stampDuty;
  final double stt;
  final double units;

  TransactionModel({
    required this.transactionType,
    required this.status,
    required this.amount,
    required this.date,
    required this.price,
    required this.stampDuty,
    required this.stt,
    required this.units,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionType: json['transaction_type'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stampDuty: (json['stamp_duty'] ?? 0).toDouble(),
      stt: (json['stt'] ?? 0).toDouble(),
      units: (json['units'] ?? 0).toDouble(),
    );
  }
}

class AllTransactionsResponse {
  final int pageIndex;
  final int totalRecords;
  final int totalPages;
  final int pageSize;
  final List<TransactionModel> dataList;

  AllTransactionsResponse({
    required this.pageIndex,
    required this.totalRecords,
    required this.totalPages,
    required this.pageSize,
    required this.dataList,
  });

  factory AllTransactionsResponse.fromJson(Map<String, dynamic> json) {
    return AllTransactionsResponse(
      pageIndex: json['page_index'] ?? 1,
      totalRecords: json['total_records'] ?? 0,
      totalPages: json['total_pages'] ?? 0,
      pageSize: json['page_size'] ?? 10,
      dataList: (json['data_list'] as List?)
          ?.map((e) => TransactionModel.fromJson(e))
          .toList() ??
          [],
    );
  }
}