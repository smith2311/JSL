import 'package:flutter_riverpod/flutter_riverpod.dart';

// Filter state model
class PortfolioFilterState {
  final String searchTerm;
  final String sortBy;
  final String sortOrder;
  final List<String> amcs;
  final List<String> fundCategory;
  final List<String> subCategory;

  PortfolioFilterState({
    this.searchTerm = '',
    this.sortBy = '',
    this.sortOrder = '',
    this.amcs = const [],
    this.fundCategory = const [],
    this.subCategory = const [],
  });

  PortfolioFilterState copyWith({
    String? searchTerm,
    String? sortBy,
    String? sortOrder,
    List<String>? amcs,
    List<String>? fundCategory,
    List<String>? subCategory,
  }) {
    return PortfolioFilterState(
      searchTerm: searchTerm ?? this.searchTerm,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      amcs: amcs ?? this.amcs,
      fundCategory: fundCategory ?? this.fundCategory,
      subCategory: subCategory ?? this.subCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'search_term': searchTerm,
      'sort_by': sortBy,
      'sort_order': sortOrder,
      'filter': {
        'amcs': amcs,
        'fund_category': fundCategory,
        'sub_category': subCategory,
      },
    };
  }

  bool get hasActiveFilters {
    return amcs.isNotEmpty || fundCategory.isNotEmpty || subCategory.isNotEmpty;
  }

  bool get hasSorting {
    return sortBy.isNotEmpty && sortOrder.isNotEmpty;
  }

  bool get hasAnyActiveFiltersOrSort {
    return hasActiveFilters || hasSorting;
  }
}

// Portfolio filter provider
final portfolioFilterProvider =
StateNotifierProvider<PortfolioFilterNotifier, PortfolioFilterState>(
      (ref) => PortfolioFilterNotifier(),
);

class PortfolioFilterNotifier extends StateNotifier<PortfolioFilterState> {
  PortfolioFilterNotifier() : super(PortfolioFilterState());

  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
  }

  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  void setFilters({
    List<String>? amcs,
    List<String>? fundCategory,
    List<String>? subCategory,
  }) {
    state = state.copyWith(
      amcs: amcs,
      fundCategory: fundCategory,
      subCategory: subCategory,
    );
  }

  void applyFilterResult(Map<String, dynamic> result) {
    state = state.copyWith(
      sortBy: result['sortBy'] ?? '',
      sortOrder: result['sortOrder'] ?? '',
      amcs: List<String>.from(result['amcs'] ?? []),
      fundCategory: List<String>.from(result['fundCategory'] ?? []),
      subCategory: List<String>.from(result['subCategory'] ?? []),
    );
  }

  void clearAllFilters() {
    state = PortfolioFilterState();
  }

  void clearSorting() {
    state = state.copyWith(sortBy: '', sortOrder: '');
  }
}

// SIP filter provider
final sipFilterProvider =
StateNotifierProvider<SipFilterNotifier, PortfolioFilterState>(
      (ref) => SipFilterNotifier(),
);

class SipFilterNotifier extends StateNotifier<PortfolioFilterState> {
  SipFilterNotifier() : super(PortfolioFilterState());

  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
  }

  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  void setFilters({
    List<String>? amcs,
    List<String>? fundCategory,
    List<String>? subCategory,
  }) {
    state = state.copyWith(
      amcs: amcs,
      fundCategory: fundCategory,
      subCategory: subCategory,
    );
  }

  void applyFilterResult(Map<String, dynamic> result) {
    state = state.copyWith(
      sortBy: result['sortBy'] ?? '',
      sortOrder: result['sortOrder'] ?? '',
      amcs: List<String>.from(result['amcs'] ?? []),
      fundCategory: List<String>.from(result['fundCategory'] ?? []),
      subCategory: List<String>.from(result['subCategory'] ?? []),
    );
  }

  void clearAllFilters() {
    state = PortfolioFilterState();
  }

  void clearSorting() {
    state = state.copyWith(sortBy: '', sortOrder: '');
  }
}

// SWP filter provider
final swpFilterProvider =
StateNotifierProvider<SwpFilterNotifier, PortfolioFilterState>(
      (ref) => SwpFilterNotifier(),
);

class SwpFilterNotifier extends StateNotifier<PortfolioFilterState> {
  SwpFilterNotifier() : super(PortfolioFilterState());

  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
  }

  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  void setFilters({
    List<String>? amcs,
    List<String>? fundCategory,
    List<String>? subCategory,
  }) {
    state = state.copyWith(
      amcs: amcs,
      fundCategory: fundCategory,
      subCategory: subCategory,
    );
  }

  void applyFilterResult(Map<String, dynamic> result) {
    state = state.copyWith(
      sortBy: result['sortBy'] ?? '',
      sortOrder: result['sortOrder'] ?? '',
      amcs: List<String>.from(result['amcs'] ?? []),
      fundCategory: List<String>.from(result['fundCategory'] ?? []),
      subCategory: List<String>.from(result['subCategory'] ?? []),
    );
  }

  void clearAllFilters() {
    state = PortfolioFilterState();
  }

  void clearSorting() {
    state = state.copyWith(sortBy: '', sortOrder: '');
  }
}

// STP filter provider
final stpFilterProvider =
StateNotifierProvider<StpFilterNotifier, PortfolioFilterState>(
      (ref) => StpFilterNotifier(),
);

class StpFilterNotifier extends StateNotifier<PortfolioFilterState> {
  StpFilterNotifier() : super(PortfolioFilterState());

  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
  }

  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  void setFilters({
    List<String>? amcs,
    List<String>? fundCategory,
    List<String>? subCategory,
  }) {
    state = state.copyWith(
      amcs: amcs,
      fundCategory: fundCategory,
      subCategory: subCategory,
    );
  }

  void applyFilterResult(Map<String, dynamic> result) {
    state = state.copyWith(
      sortBy: result['sortBy'] ?? '',
      sortOrder: result['sortOrder'] ?? '',
      amcs: List<String>.from(result['amcs'] ?? []),
      fundCategory: List<String>.from(result['fundCategory'] ?? []),
      subCategory: List<String>.from(result['subCategory'] ?? []),
    );
  }

  void clearAllFilters() {
    state = PortfolioFilterState();
  }

  void clearSorting() {
    state = state.copyWith(sortBy: '', sortOrder: '');
  }
}

// Orders filter provider
final ordersFilterProvider =
StateNotifierProvider<OrdersFilterNotifier, PortfolioFilterState>(
      (ref) => OrdersFilterNotifier(),
);

class OrdersFilterNotifier extends StateNotifier<PortfolioFilterState> {
  OrdersFilterNotifier() : super(PortfolioFilterState());

  void setSearchTerm(String term) {
    state = state.copyWith(searchTerm: term);
  }

  void setSorting(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
  }

  void setFilters({
    List<String>? amcs,
    List<String>? fundCategory,
    List<String>? subCategory,
  }) {
    state = state.copyWith(
      amcs: amcs,
      fundCategory: fundCategory,
      subCategory: subCategory,
    );
  }

  void applyFilterResult(Map<String, dynamic> result) {
    state = state.copyWith(
      sortBy: result['sortBy'] ?? '',
      sortOrder: result['sortOrder'] ?? '',
      amcs: List<String>.from(result['amcs'] ?? []),
      fundCategory: List<String>.from(result['fundCategory'] ?? []),
      subCategory: List<String>.from(result['subCategory'] ?? []),
    );
  }

  void clearAllFilters() {
    state = PortfolioFilterState();
  }

  void clearSorting() {
    state = state.copyWith(sortBy: '', sortOrder: '');
  }
}