import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../../../../../../constants/strings.dart';
import '../../../../../../providers/discover_most_pop_funds_provider.dart';
import '../../../../../../widgets/bottom_filter_jhaveri_picks.dart';
import '../../../../../../widgets/fund_card.dart';

class DiscoverMostPopularFundsScreen extends ConsumerStatefulWidget {
  const DiscoverMostPopularFundsScreen({super.key});

  @override
  ConsumerState<DiscoverMostPopularFundsScreen> createState() =>
      _DiscoverMostPopularFundsScreenState();
}

class _DiscoverMostPopularFundsScreenState
    extends ConsumerState<DiscoverMostPopularFundsScreen> {
  late final String baseUrl;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [DiscoverMostPopularFunds] Initializing...");
    baseUrl = EnvConfig.apiBaseUrl;
    debugPrint("🔗 [DiscoverMostPopularFunds] API Base URL: $baseUrl");
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTokenAndLoadData();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      final fundsState = ref.read(fundsProvider);
      if (!fundsState.isLoadingMore && !fundsState.isLoadingFunds && fundsState.hasMoreData) {
        ref.read(fundsProvider.notifier).loadMoreFunds();
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
    });
  }

  Future<void> _checkTokenAndLoadData() async {
    debugPrint("🔑 [DiscoverMostPopularFunds] Checking auth token...");

    try {
      final token = await ref.read(authTokenProvider.future);

      if (token == null || token.isEmpty) {
        debugPrint("⚠️ [DiscoverMostPopularFunds] No auth token found");
        return;
      }

      debugPrint("✅ [DiscoverMostPopularFunds] Auth token found");
      await _loadCategoriesAndFunds();
    } catch (e) {
      debugPrint("❌ [DiscoverMostPopularFunds] Token error: $e");
    }
  }

  Future<void> _loadCategoriesAndFunds() async {
    debugPrint("📦 [DiscoverMostPopularFunds] Loading categories and funds...");
    await ref.read(categoriesProvider.notifier).fetchCategories(baseUrl);
    await ref.read(fundsProvider.notifier).fetchFunds();
  }

  void _onFilterPressed() async {
    debugPrint("🔧 [DiscoverMostPopularFunds] Filter button pressed");
    final filterState = ref.read(filterProvider);

    final selectedFilters = await showModalBottomSheet<Map<String, Set<String>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BottomFilterJhaveriPicks(
        title: AppStrings.most_pop_funds,
        apiBaseUrl: baseUrl,
        initialAppliedFilters: filterState.appliedFilters,
      ),
    );

    if (selectedFilters != null) {
      debugPrint("🔧 [DiscoverMostPopularFunds] Filters returned: $selectedFilters");
      ref.read(filterProvider.notifier).applyFilters(selectedFilters);
      ref.read(fundsProvider.notifier).fetchFunds(isRefresh: true);
    } else {
      debugPrint("🔧 [DiscoverMostPopularFunds] Filter sheet dismissed");
    }
  }

  void _onBackPressed() {
    debugPrint("⬅️ [DiscoverMostPopularFunds] Back button pressed");

    if (context.canPop()) {
      context.pop();
    } else {
      context.go("/discover");
    }
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
    final fundsState = ref.watch(fundsProvider);
    debugPrint("🗂️ [DiscoverMostPopularFunds] Building with ${fundsState.funds.length} funds");

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        debugPrint("⬅️ [DiscoverMostPopularFunds] PopScope triggered - didPop: $didPop");
        ref.read(filterProvider.notifier).clearAllFilters();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              AppBarWidget(
                onBackPressed: _onBackPressed,
                onFilterPressed: _onFilterPressed,
              ),
              const SizedBox(height: 12),
              CategoryButtons(baseUrl: baseUrl),
              const SizedBox(height: 12),
              SearchBarWidget(controller: _searchController),
              const SizedBox(height: 12),
              FundsListWidget(
                scrollController: _scrollController,
                searchQuery: _searchQuery,
                getFilteredFunds: _getFilteredFunds,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBarWidget extends ConsumerWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onFilterPressed;

  const AppBarWidget({
    super.key,
    required this.onBackPressed,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(filterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBackPressed,
            child: SvgPicture.asset(AppStrings.back_icon, width: 24, height: 24),
          ),
          const SizedBox(width: 36),
          const Expanded(
            child: Text(
              AppStrings.most_pop_funds,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black),
            ),
          ),
          GestureDetector(
            onTap: onFilterPressed,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(AppStrings.filter, width: 24, height: 24),
                if (filterState.hasAppliedFilters)
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
          ),
        ],
      ),
    );
  }
}

class CategoryButtons extends ConsumerWidget {
  final String baseUrl;

  const CategoryButtons({
    super.key,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final filterNotifier = ref.read(filterProvider.notifier);

    if (categoriesState.isLoading) {
      return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()));
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categoriesState.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categoriesState.categories[index];
          final id = cat['id'] as int;
          final name = cat['name'] as String;
          final isSelected = filterNotifier.isCategorySelected(id);

          return CategoryButton(
            id: id,
            name: name,
            isSelected: isSelected,
          );
        },
      ),
    );
  }
}

class CategoryButton extends ConsumerWidget {
  final int id;
  final String name;
  final bool isSelected;

  const CategoryButton({
    super.key,
    required this.id,
    required this.name,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () {
        ref.read(filterProvider.notifier).toggleSubCategory(id);
        ref.read(fundsProvider.notifier).fetchFunds(isRefresh: true);
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF0060A6) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD9D9D9)),
        ),
      ),
      child: Text(name, style: const TextStyle(fontSize: 14)),
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

class FundsListWidget extends ConsumerWidget {
  final ScrollController scrollController;
  final String searchQuery;
  final List<dynamic> Function(List<dynamic>) getFilteredFunds;

  const FundsListWidget({
    super.key,
    required this.scrollController,
    required this.searchQuery,
    required this.getFilteredFunds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authTokenAsync = ref.watch(authTokenProvider);
    final fundsState = ref.watch(fundsProvider);

    return authTokenAsync.when(
      data: (token) {
        if (token == null || token.isEmpty) {
          return const Expanded(child: NoAuthWidget());
        }

        if (fundsState.isLoadingFunds) {
          return const Expanded(child: Center(child: CircularProgressIndicator()));
        }

        if (fundsState.hasError) {
          return ErrorWidget(errorMessage: fundsState.errorMessage);
        }

        final filteredFunds = getFilteredFunds(fundsState.funds);

        if (filteredFunds.isEmpty && searchQuery.isNotEmpty) {
          return const Expanded(child: NoSearchResultsWidget());
        }

        if (filteredFunds.isEmpty) {
          return const Expanded(child: NoFundsWidget());
        }

        return Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.only(left: 10, right: 2, bottom: 20),
            itemCount: filteredFunds.length +
                (fundsState.isLoadingMore && searchQuery.isEmpty ? 1 : 0) +
                (!fundsState.hasMoreData && filteredFunds.isNotEmpty && searchQuery.isEmpty ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (context, index) {
              if (index == filteredFunds.length && fundsState.isLoadingMore) {
                return const LoadingMoreWidget();
              }

              if (index == filteredFunds.length && !fundsState.hasMoreData) {
                return EndOfListWidget(count: filteredFunds.length);
              }

              final fund = filteredFunds[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: FundCard(
                  logoPath: AppStrings.iconFunds_png,
                  fundName: fund.fundName,
                  category: "${fund.fundType} • ${fund.fundSubType}",
                  minInvestment: "₹${fund.minimumInvestment.toStringAsFixed(0)}",
                  returns: "${fund.threeYearReturn.toStringAsFixed(2)}%",
                  investorsCount: "${fund.totalCustomers}+ ${AppStrings.people_invested}",
                  investorIconPath: AppStrings.above_sign,
                  fundId: fund.fundId,
                ),
              );
            },
          ),
        );
      },
      loading: () => const Expanded(child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Expanded(
        child: Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

class NoAuthWidget extends StatelessWidget {
  const NoAuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Please log in to view funds.",
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}

class ErrorWidget extends ConsumerWidget {
  final String errorMessage;

  const ErrorWidget({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Error loading funds",
              style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage.isNotEmpty ? errorMessage : "Please try again",
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(fundsProvider.notifier).fetchFunds(isRefresh: true),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

class NoFundsWidget extends StatelessWidget {
  const NoFundsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text("No funds found", style: TextStyle(color: Colors.grey, fontSize: 18)),
          SizedBox(height: 8),
          Text("Try adjusting your filters", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
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

class LoadingMoreWidget extends StatelessWidget {
  const LoadingMoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class EndOfListWidget extends StatelessWidget {
  final int count;

  const EndOfListWidget({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          "You've reached the end • $count funds loaded",
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ),
    );
  }
}