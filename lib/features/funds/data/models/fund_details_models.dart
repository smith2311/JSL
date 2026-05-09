// lib/features/funds/data/models/fund_details_models.dart

// -------------------- HOLDING SUMMARY --------------------
class HoldingSummary {
  final List<SectorHolding> sectorWise;
  final List<CompanyHolding> companyWise;

  HoldingSummary({
    required this.sectorWise,
    required this.companyWise,
  });

  factory HoldingSummary.fromJson(Map<String, dynamic> json) {
    return HoldingSummary(
      sectorWise: (json['sector_wise'] as List?)
          ?.map((x) => SectorHolding.fromJson(x))
          .toList() ??
          [],
      companyWise: (json['company_wise'] as List?)
          ?.map((x) => CompanyHolding.fromJson(x))
          .toList() ??
          [],
    );
  }
}

class SectorHolding {
  final String sector;
  final double percentage;

  SectorHolding({
    required this.sector,
    required this.percentage,
  });

  String get name => sector;

  factory SectorHolding.fromJson(Map<String, dynamic> json) {
    return SectorHolding(
      sector: json['sector'] ?? '',
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

class CompanyHolding {
  final String company;
  final double percentage;

  CompanyHolding({
    required this.company,
    required this.percentage,
  });

  String get name => company;

  factory CompanyHolding.fromJson(Map<String, dynamic> json) {
    return CompanyHolding(
      company: json['company'] ?? '',
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

// -------------------- INVESTMENT RETURNS --------------------
class InvestmentReturns {
  final List<ReturnPeriod> returns;

  InvestmentReturns({required this.returns});

  factory InvestmentReturns.fromJson(Map<String, dynamic> json) {
    return InvestmentReturns(
      returns: (json['returns'] as List?)
          ?.map((x) => ReturnPeriod.fromJson(x))
          .toList() ??
          [],
    );
  }
}

class ReturnPeriod {
  final String period;
  final double percentage;

  ReturnPeriod({
    required this.period,
    required this.percentage,
  });

  factory ReturnPeriod.fromJson(Map<String, dynamic> json) {
    return ReturnPeriod(
      period: json['period'] ?? '',
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

// -------------------- INVESTMENT PERFORMANCE --------------------
class InvestmentPerformance {
  final List<PerformancePeriod> performance;

  InvestmentPerformance({required this.performance});

  factory InvestmentPerformance.fromJson(Map<String, dynamic> json) {
    return InvestmentPerformance(
      performance: (json['performance'] as List?)
          ?.map((x) => PerformancePeriod.fromJson(x))
          .toList() ??
          [],
    );
  }
}

class PerformancePeriod {
  final String period;
  final double fundReturn;
  final double benchmarkReturn;

  PerformancePeriod({
    required this.period,
    required this.fundReturn,
    required this.benchmarkReturn,
  });

  factory PerformancePeriod.fromJson(Map<String, dynamic> json) {
    return PerformancePeriod(
      period: json['period'] ?? '',
      fundReturn: (json['fund_return'] ?? 0.0).toDouble(),
      benchmarkReturn: (json['benchmark_return'] ?? 0.0).toDouble(),
    );
  }
}

// -------------------- NAV HISTORY --------------------
class NavHistory {
  final String fundName;
  final String period;
  final double returns;
  final List<NavPoint> navList;
  final CategoryReturns categoryReturns;

  NavHistory({
    required this.fundName,
    required this.period,
    required this.returns,
    required this.navList,
    required this.categoryReturns,
  });

  factory NavHistory.fromJson(Map<String, dynamic> json) {
    return NavHistory(
      fundName: json['fund_name'] ?? '',
      period: json['period'] ?? '',
      returns: (json['returns'] ?? 0.0).toDouble(),
      navList: (json['nav_list'] as List?)
          ?.map((x) => NavPoint.fromJson(x))
          .toList() ??
          [],
      categoryReturns:
      CategoryReturns.fromJson(json['category_returns'] ?? {}),
    );
  }
}

class NavPoint {
  final String date;
  final double nav;

  NavPoint({
    required this.date,
    required this.nav,
  });

  factory NavPoint.fromJson(Map<String, dynamic> json) {
    return NavPoint(
      date: json['date'] ?? '',
      nav: (json['nav'] ?? 0.0).toDouble(),
    );
  }
}

class CategoryReturns {
  final double min;
  final double max;

  CategoryReturns({
    required this.min,
    required this.max,
  });

  factory CategoryReturns.fromJson(Map<String, dynamic> json) {
    return CategoryReturns(
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
    );
  }
}

// -------------------- FUND INFO --------------------
class FundInfo {
  final List<FundInfoItem> fundInfo;
  final FundOtherDetails otherDetails;

  FundInfo({
    required this.fundInfo,
    required this.otherDetails,
  });

  factory FundInfo.fromJson(Map<String, dynamic> json) {
    return FundInfo(
      fundInfo: (json['fund_info'] as List?)
          ?.map((x) => FundInfoItem.fromJson(x))
          .toList() ??
          [],
      otherDetails: FundOtherDetails.fromJson(json['other_details'] ?? {}),
    );
  }
}

class FundInfoItem {
  final String label;
  final dynamic value;

  FundInfoItem({
    required this.label,
    required this.value,
  });

  factory FundInfoItem.fromJson(Map<String, dynamic> json) {
    return FundInfoItem(
      label: json['label'] ?? '',
      value: json['value'],
    );
  }
}

class FundOtherDetails {
  final double nav;
  final String navDate;
  final String riskLevel;
  final int minInvestment;
  final String fundName;
  final String fundCategory;
  final String fundSubCategory;
  final double rating;

  FundOtherDetails({
    required this.nav,
    required this.navDate,
    required this.riskLevel,
    required this.minInvestment,
    required this.fundName,
    required this.fundCategory,
    required this.fundSubCategory,
    required this.rating,
  });

  factory FundOtherDetails.fromJson(Map<String, dynamic> json) {
    return FundOtherDetails(
      nav: (json['nav'] ?? 0.0).toDouble(),
      navDate: json['nav_date'] ?? '',
      riskLevel: json['risk_level'] ?? '',
      minInvestment: (json['min_investment'] ?? 0).toInt(), // Fixed: Convert to int properly
      fundName: json['fund_name'] ?? '',
      fundCategory: json['fund_category'] ?? '',
      fundSubCategory: json['fund_sub_category'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }
}