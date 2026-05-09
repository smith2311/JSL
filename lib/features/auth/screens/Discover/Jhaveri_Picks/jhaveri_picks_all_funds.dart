import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../../../providers/jhaveri_picks_provider.dart';
import '../../../../../../providers/sub_category_provider.dart';
import '../../../../../../widgets/jhaveri_picks_fundcard.dart';
import '../../../../../../widgets/bottom_filter_jhaveri_picks.dart';
import '../../../../../../constants/strings.dart';
import '../../../data/models/jhaveri_pick.dart';

class JhaveriPicksAllFunds extends ConsumerStatefulWidget {
  final bool fromDiscover; // receive via constructor

  const JhaveriPicksAllFunds({super.key, this.fromDiscover = true});

  @override
  ConsumerState<JhaveriPicksAllFunds> createState() =>
      _JhaveriPicksAllFundsState();
}

class _JhaveriPicksAllFundsState extends ConsumerState<JhaveriPicksAllFunds> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Fetch funds after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(jhaveriPicksProvider.notifier).fetchFunds();
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.fromDiscover) {
      context.go('/discover');
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _showFilterSheet() async {
    final currentState = ref.read(jhaveriPicksProvider);

    final selectedFilters = await showModalBottomSheet<Map<String, Set<String>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BottomFilterJhaveriPicks(
        apiBaseUrl: dotenv.env['API_BASE_URL'] ?? '',
        initialAppliedFilters: currentState.appliedFilters,
        title: "Filter Jhaveri Picks",
      ),
    );

    if (selectedFilters != null) {
      ref.read(jhaveriPicksProvider.notifier).applyFilters(selectedFilters);
    }
  }

  void _toggleCategory(int categoryId) =>
      ref.read(jhaveriPicksProvider.notifier).toggleSubCategory(categoryId);

  void _clearAllFilters() =>
      ref.read(jhaveriPicksProvider.notifier).clearAllFilters();

  void _navigateToFundDetail(JhaveriPick fund) {
    context.push(
      '/fund-details/${fund.fundId}',
      extra: {
        'fundName': fund.fundName,
        'category': "${fund.fundType} • ${fund.fundSubType}",
        'minInvestment':
        fund.minimumInvestment > 0 ? "₹${fund.minimumInvestment}" : "N/A",
        'returns': "${fund.threeYearReturn.toStringAsFixed(2)}%",
        'rating': fund.rating,
        'investorsCount': fund.totalCustomers,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jhaveriPicksProvider);

    return WillPopScope(
      onWillPop: () async {
        _handleBack();
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(state.hasAppliedFilters),
              _buildCategoryChips(),
              const SizedBox(height: 8),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFundsList(state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildBackButton(),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              AppStrings.discover_jhaveri_picks,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          _buildFilterButton(hasActiveFilters),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _handleBack,
      child: SvgPicture.asset(AppStrings.back_icon, width: 24, height: 24),
    );
  }

  Widget _buildFilterButton(bool hasActiveFilters) {
    return GestureDetector(
      onTap: _showFilterSheet,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(AppStrings.filter, width: 24, height: 24),
          if (hasActiveFilters)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
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
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search funds...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
              onPressed: _searchController.clear,
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final subCategoriesAsync = ref.watch(subCategoriesProvider);
    final state = ref.watch(jhaveriPicksProvider);

    return subCategoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories
            .where((cat) => (cat['name']?.toString().toLowerCase() ?? '') != 'all')
            .toList();

        return SizedBox(
          height: 40,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filteredCategories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              if (index == 0) {
                return _buildCategoryChip(
                  categoryId: -1,
                  categoryName: "All",
                  isSelected: state.isAllSelected,
                  isAllChip: true,
                );
              }

              final category = filteredCategories[index - 1];
              final categoryId = category['id'] as int;
              final categoryName = category['name'] as String;
              final isSelected = state.selectedSubCategoryIds.contains(categoryId);

              return _buildCategoryChip(
                categoryId: categoryId,
                categoryName: categoryName,
                isSelected: isSelected,
                isAllChip: false,
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 40,
        child: Center(
          child: Text(
            "Failed to load categories",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required int categoryId,
    required String categoryName,
    required bool isSelected,
    required bool isAllChip,
  }) {
    return TextButton(
      onPressed: () => isAllChip ? _clearAllFilters() : _toggleCategory(categoryId),
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF0060A6) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD9D9D9)),
        ),
      ),
      child: Text(categoryName),
    );
  }

  Widget _buildFundsList(JhaveriPicksState state) {
    if (state.isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (state.hasError) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                state.errorMessage == "AUTH_ERROR"
                    ? "Please login to view funds"
                    : "Failed to load funds: ${state.errorMessage}",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => ref.read(jhaveriPicksProvider.notifier).fetchFunds(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final filteredFunds = _searchQuery.isEmpty
        ? state.funds
        : state.funds
        .where((fund) => fund.fundName.toLowerCase().contains(_searchQuery))
        .toList();

    if (filteredFunds.isEmpty) {
      return const Expanded(
        child: Center(
            child: Text("No funds found", style: TextStyle(color: Colors.grey))),
      );
    }

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredFunds.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          final fund = filteredFunds[index];
          return JhaveriFundCard(
            logoPath: AppStrings.iconFunds_png,
            fundName: fund.fundName,
            category: "${fund.fundType} • ${fund.fundSubType}",
            minInvestment:
            fund.minimumInvestment > 0 ? "₹${fund.minimumInvestment}" : "N/A",
            returns: "${fund.threeYearReturn.toStringAsFixed(2)}%",
            onTap: () => _navigateToFundDetail(fund),
          );
        },
      ),
    );
  }
}