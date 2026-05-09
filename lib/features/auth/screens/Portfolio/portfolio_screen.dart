import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/widgets/portfolio_order_card.dart';
import 'package:jhaveri_jsl_app/widgets/portfolio_searchbar_bottom_filter.dart';
import '../../../../../constants/strings.dart';
import '../../../../../providers/portfolio_orders_list_provider.dart';
import '../../../../../providers/portfolio_provider.dart';
import '../../../../../providers/family_members_provider.dart';
import '../../../../../providers/sip_tab_provider.dart';
import '../../../../../providers/portfolio_searchbar_provider.dart';
import '../../../../../widgets/portfolio_appbar.dart';
import '../../../../../widgets/portfolio_card.dart';
import '../../../../../widgets/portfolio_fundcard.dart';
import '../../../../../widgets/portfolio_searchbar.dart';
import '../../../../../widgets/portfolio_tabs.dart';
import '../../../../../widgets/sip_header_card.dart';
import '../../../../../widgets/sip_subtab_fundcard.dart';
import '../../../../../providers/portfolio_fund_card_provider.dart';
import '../../data/models/portfolio_model.dart';

final portfolioTabStateProvider = StateProvider<Map<String, int>>((ref) => {
      'selectedTab': 0,
      'selectedSubTab': 0,
    });

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  int _selectedTab = 0;
  int _selectedSubTab = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  // Search controllers for each tab
  final TextEditingController _portfolioSearchController =
      TextEditingController();
  final TextEditingController _sipSearchController = TextEditingController();
  final TextEditingController _ordersSearchController = TextEditingController();

  Timer? _searchDebounce;

  static const _scrollThreshold = 100.0;
  static const _searchDebounceTime = Duration(milliseconds: 500);

  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedState = ref.read(portfolioTabStateProvider);
      setState(() {
        _selectedTab = savedState['selectedTab'] ?? 0;
        _selectedSubTab = savedState['selectedSubTab'] ?? 0;
      });

      final selectedMemberState = ref.read(selectedMemberProvider);
      final clientIds = selectedMemberState.isMeSelected
          ? <int>[]
          : selectedMemberState.clientIds.cast<int>();

      _refreshData(clientIds: clientIds);

      if (_selectedTab == 1) {
        ref
            .read(sipDetailsProvider.notifier)
            .fetchSipDetails(_selectedSubTab, clientIds: clientIds);
        _refreshSipList(clientIds);
      }
    });
    _scrollController.addListener(_onScroll);

    // Setup search listeners
    _portfolioSearchController.addListener(() => _onSearchChanged(0));
    _sipSearchController.addListener(() => _onSearchChanged(1));
    _ordersSearchController.addListener(() => _onSearchChanged(2));
  }

  void _onSearchChanged(int tabIndex) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final selectedMemberState = ref.read(selectedMemberProvider);
      final clientIds = selectedMemberState.isMeSelected
          ? <int>[]
          : selectedMemberState.clientIds.cast<int>();

      if (tabIndex == 0) {
        ref
            .read(portfolioFilterProvider.notifier)
            .setSearchTerm(_portfolioSearchController.text);
        _refreshFundsList(clientIds);
      } else if (tabIndex == 1) {
        final provider = _getFilterProviderForSubTab(_selectedSubTab);
        ref.read(provider.notifier).setSearchTerm(_sipSearchController.text);
        _refreshSipList(clientIds);
      } else if (tabIndex == 2) {
        ref
            .read(ordersFilterProvider.notifier)
            .setSearchTerm(_ordersSearchController.text);
        _refreshOrdersList(clientIds);
      }
    });
  }

  StateNotifierProvider<dynamic, PortfolioFilterState>
      _getFilterProviderForSubTab(int subTab) {
    switch (subTab) {
      case 0:
        return sipFilterProvider;
      case 1:
        return swpFilterProvider;
      case 2:
        return stpFilterProvider;
      default:
        return sipFilterProvider;
    }
  }

  void _updateTabState() {
    ref.read(portfolioTabStateProvider.notifier).state = {
      'selectedTab': _selectedTab,
      'selectedSubTab': _selectedSubTab,
    };
  }

  Future<void> _handleRefresh() async {
    final selectedMemberState = ref.read(selectedMemberProvider);
    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds.cast<int>();

    await _refreshData(clientIds: clientIds);
  }

  void _onScroll() {
    if (_isRefreshing) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= _scrollThreshold) {
      switch (_selectedTab) {
        case 0:
          _loadMoreFunds();
          break;
        case 1:
          _loadMoreSipItems();
          break;
        case 2:
          _loadMoreOrders();
          break;
      }
    }
  }

  // Optimize data fetching
  Future<void> _refreshData({List<int>? clientIds}) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await Future.wait([
        ref
            .read(portfolioProvider.notifier)
            .fetchPortfolio(clientIds: clientIds),
        ref.read(xirrProvider.notifier).fetchXirr(clientIds: clientIds),
        _refreshCurrentTab(clientIds),
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _refreshCurrentTab(List<int>? clientIds) {
    switch (_selectedTab) {
      case 0:
        return _refreshFundsList(clientIds);
      case 1:
        return _refreshSipList(clientIds);
      case 2:
        return _refreshOrdersList(clientIds);
      default:
        return Future.value();
    }
  }

  Future<void> _loadMoreFunds() async {
    final selectedMemberState = ref.read(selectedMemberProvider);
    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds.cast<int>();
    final filterState = ref.read(portfolioFilterProvider);

    await ref.read(fundListProvider.notifier).fetchFunds(
          refresh: false,
          clientIds: clientIds,
          searchTerm: filterState.searchTerm,
          sortBy: filterState.sortBy,
          sortOrder: filterState.sortOrder,
          amcs: filterState.amcs,
          fundCategory: filterState.fundCategory,
          subCategory: filterState.subCategory,
        );
  }

  Future<void> _loadMoreSipItems() async {
    final selectedMemberState = ref.read(selectedMemberProvider);
    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds.cast<int>();
    final provider = _getFilterProviderForSubTab(_selectedSubTab);
    final filterState = ref.read(provider);

    await ref.read(sipListProvider(_selectedSubTab).notifier).fetchList(
          refresh: false,
          clientIds: clientIds,
          searchTerm: filterState.searchTerm,
          sortBy: filterState.sortBy,
          sortOrder: filterState.sortOrder,
          amcs: filterState.amcs,
          fundCategory: filterState.fundCategory,
          subCategory: filterState.subCategory,
        );
  }

  Future<void> _loadMoreOrders() async {
    final selectedMemberState = ref.read(selectedMemberProvider);
    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds.cast<int>();
    final filterState = ref.read(ordersFilterProvider);

    await ref.read(orderListProvider.notifier).fetchOrders(
          refresh: false,
          clientIds: clientIds,
          searchTerm: filterState.searchTerm,
          sortBy: filterState.sortBy,
          sortOrder: filterState.sortOrder,
          amcs: filterState.amcs,
          fundCategory: filterState.fundCategory,
          subCategory: filterState.subCategory,
        );
  }

  Future<void> _refreshFundsList(List<int>? clientIds) async {
    final filterState = ref.read(portfolioFilterProvider);
    await ref.read(fundListProvider.notifier).fetchFunds(
          refresh: true,
          clientIds: clientIds,
          searchTerm: filterState.searchTerm,
          sortBy: filterState.sortBy,
          sortOrder: filterState.sortOrder,
          amcs: filterState.amcs,
          fundCategory: filterState.fundCategory,
          subCategory: filterState.subCategory,
        );
  }

  Future<void> _refreshSipList(List<int>? clientIds) async {
    final provider = _getFilterProviderForSubTab(_selectedSubTab);
    final filterState = ref.read(provider);
    await ref.read(sipListProvider(_selectedSubTab).notifier).fetchList(
          refresh: true,
          clientIds: clientIds,
          searchTerm: filterState.searchTerm,
          sortBy: filterState.sortBy,
          sortOrder: filterState.sortOrder,
          amcs: filterState.amcs,
          fundCategory: filterState.fundCategory,
          subCategory: filterState.subCategory,
        );
  }

  Future<void> _refreshOrdersList(List<int>? clientIds) async {
    final filterState = ref.read(ordersFilterProvider);
    await ref.read(orderListProvider.notifier).fetchOrders(
          refresh: true,
          clientIds: clientIds,
          searchTerm: filterState.searchTerm,
          sortBy: filterState.sortBy,
          sortOrder: filterState.sortOrder,
          amcs: filterState.amcs,
          fundCategory: filterState.fundCategory,
          subCategory: filterState.subCategory,
        );
  }

// In your _showFilterBottomSheet method in portfolio_screen.dart, update to pass currentSubTab:

  void _showFilterBottomSheet(int tabIndex) async {
    final selectedMemberState = ref.read(selectedMemberProvider);
    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds.cast<int>();

    StateNotifierProvider<dynamic, PortfolioFilterState> provider;
    if (tabIndex == 0) {
      provider = portfolioFilterProvider;
    } else if (tabIndex == 1) {
      provider = _getFilterProviderForSubTab(_selectedSubTab);
    } else {
      provider = ordersFilterProvider;
    }

    final currentFilter = ref.read(provider);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => PortfolioBottomFilter(
        selectedSortBy: currentFilter.sortBy,
        selectedSortOrder: currentFilter.sortOrder,
        selectedAmcs: currentFilter.amcs,
        selectedFundCategory: currentFilter.fundCategory,
        selectedSubCategory: currentFilter.subCategory,
        currentTab: tabIndex,
        currentSubTab:
            _selectedSubTab, // ✅ Pass the current sub-tab (SIP=0, SWP=1, STP=2)
      ),
    );

    if (result != null) {
      ref.read(provider.notifier).applyFilterResult(result);

      if (tabIndex == 0) {
        await _refreshFundsList(clientIds);
      } else if (tabIndex == 1) {
        await _refreshSipList(clientIds);
      } else {
        await _refreshOrdersList(clientIds);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolioState = ref.watch(portfolioProvider);
    final xirrState = ref.watch(xirrProvider);
    final fundListState = ref.watch(fundListProvider);
    final orderListState = ref.watch(orderListProvider);
    final selectedMemberState = ref.watch(selectedMemberProvider);

    // Watch filter states to show active indicator
    final portfolioFilterState = ref.watch(portfolioFilterProvider);
    final sipFilterState =
        ref.watch(_getFilterProviderForSubTab(_selectedSubTab));
    final ordersFilterState = ref.watch(ordersFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              Container(
                color: const Color(0xFF0060A6),
                child: PortfolioCustomAppBar(
                  onUserChanged: ({List<int>? clientIds}) {
                    _refreshData(clientIds: clientIds);
                    if (_selectedTab == 1) {
                      ref.read(sipDetailsProvider.notifier).fetchSipDetails(
                          _selectedSubTab,
                          clientIds: clientIds);
                      _refreshSipList(clientIds);
                    }
                  },
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Container(
                        width: double.infinity,
                        color: const Color(0xFF0060A6),
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 30, top: 10),
                        child: portfolioState.when(
                          data: (portfolio) => PortfolioCard(
                            portfolio: portfolio,
                            xirr: xirrState.maybeWhen(
                                data: (v) => v, orElse: () => null),
                            displayTitle:
                                _getPortfolioTitle(selectedMemberState),
                          ),
                          loading: () => Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF0060A6)),
                            ),
                          ),
                          error: (err, _) => Container(
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 48, color: Colors.red),
                                  const SizedBox(height: 8),
                                  const Text('Error loading portfolio',
                                      style: TextStyle(color: Colors.red)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _refreshData(
                                        clientIds:
                                            selectedMemberState.clientIds),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabsHeaderDelegate(
                        selectedTab: _selectedTab,
                        selectedSubTab: _selectedSubTab,
                        selectedMemberState: selectedMemberState,
                        portfolioSearchController: _portfolioSearchController,
                        sipSearchController: _sipSearchController,
                        ordersSearchController: _ordersSearchController,
                        portfolioHasActiveFilters:
                            portfolioFilterState.hasAnyActiveFiltersOrSort,
                        sipHasActiveFilters:
                            sipFilterState.hasAnyActiveFiltersOrSort,
                        ordersHasActiveFilters:
                            ordersFilterState.hasAnyActiveFiltersOrSort,
                        onTabSelected: (index) {
                          if (_selectedTab != index) {
                            setState(() {
                              _selectedTab = index;
                              if (index == 1) {
                                _selectedSubTab = 0;
                              }
                            });
                            _updateTabState();
                            if (index == 1) {
                              final clientIds = selectedMemberState.isMeSelected
                                  ? <int>[]
                                  : selectedMemberState.clientIds.cast<int>();
                              ref
                                  .read(sipDetailsProvider.notifier)
                                  .fetchSipDetails(0, clientIds: clientIds);
                              _refreshSipList(clientIds);
                            }
                          }
                        },
                        onSubTabSelected: (subTab) {
                          setState(() {
                            _selectedSubTab = subTab;
                          });
                          _updateTabState();
                          final clientIds = selectedMemberState.isMeSelected
                              ? <int>[]
                              : selectedMemberState.clientIds.cast<int>();
                          ref
                              .read(sipDetailsProvider.notifier)
                              .fetchSipDetails(subTab, clientIds: clientIds);
                          _refreshSipList(clientIds);
                        },
                        onFilterTap: () => _showFilterBottomSheet(_selectedTab),
                        onSearchChanged: (value) {
                          if (_selectedTab == 0) {
                            _portfolioSearchController.text = value;
                          } else if (_selectedTab == 1) {
                            _sipSearchController.text = value;
                          } else {
                            _ordersSearchController.text = value;
                          }
                        },
                        ref: ref,
                      ),
                    ),
                    if (_selectedTab == 1)
                      _buildSipSliverList()
                    else if (_selectedTab == 2)
                      _buildOrdersSliverList(orderListState)
                    else
                      _buildFundsSliverList(fundListState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPortfolioTitle(SelectedMemberState state) {
    if (state.isMeSelected) return AppStrings.my_inv;
    if (state.displayName == 'All') return AppStrings.my_fam_inv;
    return state.displayName;
  }

  Widget _buildFundsSliverList(AsyncValue<FundListState> fundListState) {
    final filterState = ref.watch(portfolioFilterProvider);

    return fundListState.when(
      data: (fundState) {
        final isFiltered = filterState.hasAnyActiveFiltersOrSort;

        if (fundState.funds.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    isFiltered
                        ? 'No data found.\nTry changing your filter.'
                        : 'No funds available.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => PortfolioFundcard(fund: fundState.funds[index]),
            childCount: fundState.funds.length,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SliverFillRemaining(
        child: Center(child: Text('Error loading funds')),
      ),
    );
  }

  Widget _buildOrdersSliverList(AsyncValue<List<OrderModel>> orderListState) {
    final filterState = ref.watch(ordersFilterProvider);

    return orderListState.when(
      data: (orders) {
        final isFiltered = filterState.hasAnyActiveFiltersOrSort;

        if (orders.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    isFiltered
                        ? 'No data found.\nTry changing your filter.'
                        : 'No orders available.',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => OrderCard(order: orders[index]),
            childCount: orders.length,
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SliverFillRemaining(
        child: Center(child: Text('Error loading orders')),
      ),
    );
  }

// Add this method to your _PortfolioScreenState class in portfolio_screen.dart

  Widget _buildSipSliverList() {
    final sipListState = ref.watch(sipListProvider(_selectedSubTab));
    final filterState = ref.watch(_getFilterProviderForSubTab(_selectedSubTab));
    final selectedMemberState = ref.watch(selectedMemberProvider);

    // ✅ Check if any filter or sort is active
    final isFiltered = filterState.hasAnyActiveFiltersOrSort;

    // ✅ Show empty state when no data and filters are active
    if (sipListState.items.isEmpty && !sipListState.isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, color: Colors.grey, size: 48),
              const SizedBox(height: 12),
              Text(
                isFiltered
                    ? 'No data found.\nTry changing your filter.'
                    : 'No ${_getSubTabDisplayName(_selectedSubTab)} available.',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (isFiltered) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Clear filters
                    final provider =
                        _getFilterProviderForSubTab(_selectedSubTab);
                    ref.read(provider.notifier).clearAll();

                    // Refresh data
                    final clientIds = selectedMemberState.isMeSelected
                        ? <int>[]
                        : selectedMemberState.clientIds.cast<int>();
                    _refreshSipList(clientIds);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0060A6),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Clear Filters'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // ✅ Show loading state
    if (sipListState.items.isEmpty && sipListState.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Build the list
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= sipListState.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = sipListState.items[index];
          return SipSubtabFundcard(
            fundName: item.fundName,
            fundType: '${item.fundCategory} • ${item.fundSubCategory}',
            frequency: item.frequency,
            amount: '₹${item.amount.toStringAsFixed(2)}',
            nextInstallmentDate: item.nextDate,
            subTab: _selectedSubTab,
            clientName: item.clientName,
            sxpId: item.id,
            currentTab: _selectedTab,
            currentSubTab: _selectedSubTab,
          );
        },
        childCount: sipListState.items.length + (sipListState.hasMore ? 1 : 0),
      ),
    );
  }

// ✅ Helper method to get display name
  String _getSubTabDisplayName(int subTab) {
    switch (subTab) {
      case 0:
        return 'SIPs';
      case 1:
        return 'SWPs';
      case 2:
        return 'STPs';
      default:
        return 'items';
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _portfolioSearchController.dispose();
    _sipSearchController.dispose();
    _ordersSearchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int selectedTab;
  final int selectedSubTab;
  final SelectedMemberState selectedMemberState;
  final TextEditingController portfolioSearchController;
  final TextEditingController sipSearchController;
  final TextEditingController ordersSearchController;
  final bool portfolioHasActiveFilters;
  final bool sipHasActiveFilters;
  final bool ordersHasActiveFilters;
  final Function(int) onTabSelected;
  final Function(int) onSubTabSelected;
  final VoidCallback onFilterTap;
  final ValueChanged<String> onSearchChanged;
  final WidgetRef ref;

  _TabsHeaderDelegate({
    required this.selectedTab,
    required this.selectedSubTab,
    required this.selectedMemberState,
    required this.portfolioSearchController,
    required this.sipSearchController,
    required this.ordersSearchController,
    required this.portfolioHasActiveFilters,
    required this.sipHasActiveFilters,
    required this.ordersHasActiveFilters,
    required this.onTabSelected,
    required this.onSubTabSelected,
    required this.onFilterTap,
    required this.onSearchChanged,
    required this.ref,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF1F3F5),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            PortfolioTabs(
              titles: AppStrings.port_tab_title,
              selectedIndex: selectedTab,
              onTabSelected: onTabSelected,
            ),
            if (selectedTab == 1) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SipHeader(subTab: selectedSubTab),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildSubTab('SIP', 0),
                    const SizedBox(width: 12),
                    _buildSubTab('SWP', 1),
                    const SizedBox(width: 12),
                    _buildSubTab('STP', 2),
                  ],
                ),
              ),
              PortfolioSearchFilterWidget(
                searchController: sipSearchController,
                onFilterTap: onFilterTap,
                hintText: 'Search ${_getSubTabName(selectedSubTab)}...',
                onChanged: onSearchChanged,
                hasActiveFilters: sipHasActiveFilters,
              ),
            ] else if (selectedTab == 0) ...[
              PortfolioSearchFilterWidget(
                searchController: portfolioSearchController,
                onFilterTap: onFilterTap,
                hintText: 'Search funds...',
                onChanged: onSearchChanged,
                hasActiveFilters: portfolioHasActiveFilters,
              ),
            ] else ...[
              PortfolioSearchFilterWidget(
                searchController: ordersSearchController,
                onFilterTap: onFilterTap,
                hintText: 'Search orders...',
                onChanged: onSearchChanged,
                hasActiveFilters: ordersHasActiveFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSubTabName(int subTab) {
    switch (subTab) {
      case 0:
        return 'SIP';
      case 1:
        return 'SWP';
      case 2:
        return 'STP';
      default:
        return 'SIP';
    }
  }

  Widget _buildSubTab(String label, int index) {
    return Expanded(
      child: TextButton(
        onPressed: () => onSubTabSelected(index),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6),
          side: BorderSide(
            color: selectedSubTab == index
                ? const Color(0xFF0060A6)
                : Colors.transparent,
            width: 2,
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selectedSubTab == index
                ? const Color(0xFF0060A6)
                : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent {
    if (selectedTab == 1) {
      return 276.0; 
    }
    return 128.0; 
  }

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) {
    return oldDelegate.selectedTab != selectedTab ||
        oldDelegate.selectedSubTab != selectedSubTab ||
        oldDelegate.portfolioHasActiveFilters != portfolioHasActiveFilters ||
        oldDelegate.sipHasActiveFilters != sipHasActiveFilters ||
        oldDelegate.ordersHasActiveFilters != ordersHasActiveFilters;
  }
}
