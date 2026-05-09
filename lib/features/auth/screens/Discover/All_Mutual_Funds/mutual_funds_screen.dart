import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../constants/strings.dart';
import '../../../../../../core/secure_store.dart';
import '../../../../../../providers/auth_provider.dart';
import '../../../../../../providers/mf_provider.dart';
import '../../../../../../providers/sub_category_provider.dart';
import '../../../../../../widgets/discover_all_mutual_fund_card.dart';
import '../../../../../../widgets/mf_appbar.dart';

class MutualFundsScreen extends ConsumerStatefulWidget {
  const MutualFundsScreen({super.key});

  @override
  ConsumerState<MutualFundsScreen> createState() => _MutualFundsScreenState();
}

class _MutualFundsScreenState extends ConsumerState<MutualFundsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _noAuthToken = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initFunds();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onScroll() {
    final state = ref.read(fundsProvider);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoading) {
      ref.read(fundsProvider.notifier).fetchNextPage();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
    });

    // If there's a query, ask the provider to perform a server-side search
    if (query.isNotEmpty) {
      // NOTE: `searchFunds` should be implemented in your fundsProvider.notifier.
      // It should call the backend for matching funds and update the provider state
      // with the search results (preferably resetting existing list).
      ref.read(fundsProvider.notifier).searchFunds(query);
    } else {
      // If query cleared, restore the default paginated list
      ref.read(fundsProvider.notifier).fetchFunds(reset: true);
    }
  }

  Future<void> _initFunds() async {
    final token = await SecureStore.getToken();
    if (token == null || token.isEmpty) {
      setState(() => _noAuthToken = true);
      return;
    }
    setState(() => _noAuthToken = false);

    // Load the first page of funds initially
    await ref.read(fundsProvider.notifier).fetchFunds(reset: true);
  }

  Future<void> _onFilterApplied(Map<String, Set<String>> filters) async {
    final amcIds = filters['Fund House']
        ?.map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    final fundCategoryIds = filters['Fund Category']
        ?.map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    final subCategoryIds = filters['Sub Category']
        ?.map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    final riskLevelIds = filters['Risk Level']
        ?.map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    final fundSizeIds = filters['Fund Size']
        ?.map((id) => int.tryParse(id) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    ref.read(selectedSubCategoriesProvider.notifier).state = subCategoryIds;

    await ref.read(fundsProvider.notifier).applyFilters({
      "amcs": amcIds,
      "fund_category": fundCategoryIds,
      "sub_category": subCategoryIds,
      "risk_level": riskLevelIds,
      "fund_size": fundSizeIds,
    });
  }

  void _navigateToFundDetail(dynamic fund) {
    context.go(
      '/fund-detail/${fund.fundId}',
      extra: {
        'fundId': fund.fundId,
        'fundName': fund.fundName,
        'category': fund.fundSubType ?? 'N/A',
        'minInvestment': fund.minimumInvestment != null
            ? '₹${fund.minimumInvestment!.toStringAsFixed(0)}'
            : 'N/A',
        'returns': '${fund.threeYearReturn >= 0 ? '+' : ''}${fund.threeYearReturn.toStringAsFixed(1)}%',
        'rating': fund.rating,
        'investorsCount': fund.totalCustomers ?? 0,
        'fundType': fund.fundType ?? 'N/A',
        'fundSubType': fund.fundSubType ?? 'N/A',
      },
    );
  }

  List<dynamic> _getFilteredFunds(List<dynamic> funds) {
    if (_searchQuery.isEmpty) {
      return funds;
    }

    return funds.where((fund) {
      final fundName = fund.fundName?.toLowerCase() ?? '';
      final fundType = fund.fundType?.toLowerCase() ?? '';
      final fundSubType = fund.fundSubType?.toLowerCase() ?? '';

      return fundName.contains(_searchQuery) ||
          fundType.contains(_searchQuery) ||
          fundSubType.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final fundsState = ref.watch(fundsProvider);
    final selectedIds = ref.watch(selectedSubCategoriesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          children: [
            MutualFundsAppBar(
              title: AppStrings.mutual_funds,
              onFiltersApplied: _onFilterApplied,
            ),
            const SizedBox(height: 12),
            if (authState.isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0060A6)),
              ),
            Expanded(
              child: authState.isAuthenticated
                  ? _buildFundsContent(fundsState, selectedIds)
                  : const AuthRequiredWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundsContent(FundsState fundsState, List<int> selectedIds) {
    return Column(
      children: [
        SubCategoryChips(
          selectedIds: selectedIds,
          onFilterApplied: _onFilterApplied,
        ),
        const SizedBox(height: 12),
        SearchBarWidget(controller: _searchController),
        const SizedBox(height: 12),
        Expanded(
          child: _noAuthToken
              ? const NoAuthTokenWidget()
              : FundsList(
            scrollController: _scrollController,
            fundsState: fundsState,
            searchQuery: _searchQuery,
            getFilteredFunds: _getFilteredFunds,
            navigateToFundDetail: _navigateToFundDetail,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class SubCategoryChips extends ConsumerWidget {
  final List<int> selectedIds;
  final Function(Map<String, Set<String>>) onFilterApplied;

  const SubCategoryChips({
    super.key,
    required this.selectedIds,
    required this.onFilterApplied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subCategoriesAsync = ref.watch(subCategoriesProvider);

    return SizedBox(
      height: 45,
      child: subCategoriesAsync.when(
        data: (subCategories) {
          final chips = [
            {'id': null, 'name': 'All'},
            ...subCategories.where((sc) => sc['name'].toLowerCase() != 'all'),
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final chip = chips[index];
              final int? id = chip['id']; // nullable id
              final String name = chip['name'];

              // ✅ Fix: guard against null before calling contains
              final bool selected = id == null
                  ? selectedIds.isEmpty
                  : selectedIds.contains(id as int);

              return SubCategoryChip(
                id: id,
                name: name,
                selected: selected,
                selectedIds: selectedIds,
                onFilterApplied: onFilterApplied,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text(
          "Failed to load categories",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class SubCategoryChip extends StatelessWidget {
  final int? id;
  final String name;
  final bool selected;
  final List<int> selectedIds;
  final Function(Map<String, Set<String>>) onFilterApplied;

  const SubCategoryChip({
    super.key,
    required this.id,
    required this.name,
    required this.selected,
    required this.selectedIds,
    required this.onFilterApplied,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        final current = Set<int>.from(selectedIds);
        if (id == null) {
          current.clear();
        } else {
          // ✅ Fix: explicitly cast id! before using with Set<int>
          final nonNullId = id!;
          if (current.contains(nonNullId)) {
            current.remove(nonNullId);
          } else {
            current.add(nonNullId);
          }
        }

        onFilterApplied({
          "Sub Category": current.map((e) => e.toString()).toSet(),
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF0060A6) : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? Colors.transparent : Colors.black26,
          ),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;

  const SearchBarWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search funds...',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade400,
              size: 22,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: controller.clear,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

class FundsList extends ConsumerWidget {
  final ScrollController scrollController;
  final FundsState fundsState;
  final String searchQuery;
  final List<dynamic> Function(List<dynamic>) getFilteredFunds;
  final Function(dynamic) navigateToFundDetail;

  const FundsList({
    super.key,
    required this.scrollController,
    required this.fundsState,
    required this.searchQuery,
    required this.getFilteredFunds,
    required this.navigateToFundDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredFunds = getFilteredFunds(fundsState.funds);

    if (filteredFunds.isEmpty && searchQuery.isNotEmpty) {
      return const NoSearchResultsWidget();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(fundsProvider.notifier).refreshFunds(),
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredFunds.length + (fundsState.hasMore && searchQuery.isEmpty ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          if (index == filteredFunds.length - 3 &&
              fundsState.hasMore &&
              !fundsState.isLoading &&
              searchQuery.isEmpty) {
            Future.microtask(() {
              ref.read(fundsProvider.notifier).fetchNextPage();
            });
          }

          if (index >= filteredFunds.length) {
            if (fundsState.isLoading) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (fundsState.error != null) {
              return Center(
                child: Text(
                  fundsState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            } else {
              return const SizedBox();
            }
          }

          final fund = filteredFunds[index];
          return DiscoverFundCard(
            logoPath: AppStrings.iconFunds_png,
            fundName: fund.fundName,
            productTitle: "${fund.fundType} • ${fund.fundSubType}",
            threeYearReturnValue: fund.threeYearReturn,
            minimumInvestment: fund.minimumInvestment?.toDouble(),
            rating: fund.rating,
            onTap: () => navigateToFundDetail(fund),
          );
        },
      ),
    );
  }
}

class AuthRequiredWidget extends StatelessWidget {
  const AuthRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              "Authentication Required",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              "Please login to view mutual funds and access personalized features.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class NoAuthTokenWidget extends StatelessWidget {
  const NoAuthTokenWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Please login to view funds.",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }
}

class NoSearchResultsWidget extends StatelessWidget {
  const NoSearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No funds found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}