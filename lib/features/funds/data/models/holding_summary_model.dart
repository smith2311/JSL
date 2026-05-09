// lib/features/funds/data/models/holding_summary_model.dart

class SectorHolding {
  final String sector;
  final double percentage;

  SectorHolding({required this.sector, required this.percentage});

  String get name => sector;

  factory SectorHolding.fromJson(Map<String, dynamic> json) {
    return SectorHolding(
      sector: json['sector'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class CompanyHolding {
  final String company;
  final double percentage;

  CompanyHolding({required this.company, required this.percentage});

  String get name => company;

  factory CompanyHolding.fromJson(Map<String, dynamic> json) {
    return CompanyHolding(
      company: json['company'] as String,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class HoldingSummaryModel {
  final List<SectorHolding> sectorWise;
  final List<CompanyHolding> companyWise;

  HoldingSummaryModel({required this.sectorWise, required this.companyWise});

  factory HoldingSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    final sectorList = (data['sector_wise'] as List<dynamic>)
        .map((e) => SectorHolding.fromJson(e as Map<String, dynamic>))
        .toList();

    final companyList = (data['company_wise'] as List<dynamic>)
        .map((e) => CompanyHolding.fromJson(e as Map<String, dynamic>))
        .toList();

    return HoldingSummaryModel(
      sectorWise: sectorList,
      companyWise: companyList,
    );
  }
}