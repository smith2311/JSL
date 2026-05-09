import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/portfolio_model.dart';
import '../features/auth/data/repo/portfolio_orders_repo.dart';

final orderListProvider =
StateNotifierProvider<OrderListNotifier, AsyncValue<List<OrderModel>>>(
      (ref) => OrderListNotifier(OrderRepository()),
);

class OrderListNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository repository;
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  // Store current filter parameters
  List<int>? _currentClientIds;
  String _currentSearchTerm = '';
  String _currentSortBy = '';
  String _currentSortOrder = '';
  List<String> _currentAmcs = [];
  List<String> _currentFundCategory = [];
  List<String> _currentSubCategory = [];

  OrderListNotifier(this.repository) : super(const AsyncValue.loading());

  bool get hasMore => _hasMore;

  Future<void> fetchOrders({
    bool refresh = false,
    List<int>? clientIds,
    String searchTerm = '',
    String sortBy = '',
    String sortOrder = '',
    List<String> amcs = const [],
    List<String> fundCategory = const [],
    List<String> subCategory = const [],
  }) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _currentClientIds = clientIds;
      _currentSearchTerm = searchTerm;
      _currentSortBy = sortBy;
      _currentSortOrder = sortOrder;
      _currentAmcs = amcs;
      _currentFundCategory = fundCategory;
      _currentSubCategory = subCategory;
      state = const AsyncValue.loading();
    }

    if (!_hasMore) return;

    try {
      final newOrders = await repository.fetchOrders(
        page: _page,
        pageSize: _pageSize,
        clientIds: _currentClientIds,
        searchTerm: _currentSearchTerm,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        amcs: _currentAmcs,
        fundCategory: _currentFundCategory,
        subCategory: _currentSubCategory,
      );

      final List<OrderModel> updatedList = refresh
          ? newOrders
          : [
        ...state.maybeWhen(
            data: (List<OrderModel> v) => v, orElse: () => <OrderModel>[]),
        ...newOrders
      ];

      _hasMore = newOrders.length == _pageSize;
      state = AsyncValue.data(updatedList);

      if (_hasMore) _page++;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}