import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../constants/strings.dart';
import '../../../../../core/secure_store.dart';
import '../../../../../providers/auth_provider.dart';
import '../../../../../providers/high_returns_provider.dart';
import '../../../../../providers/sub_category_provider.dart';
import '../../../../../widgets/discover_all_mutual_fund_card.dart';
import '../../../../../widgets/high_ret_appbar.dart';
import '../../Discover/All_Mutual_Funds/mutual_funds_screen.dart';

class CollectionsCategoryDetailScreen extends ConsumerStatefulWidget {
  final String category;
  final String title;

  const CollectionsCategoryDetailScreen({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  ConsumerState<CollectionsCategoryDetailScreen> createState() => _CollectionsCategoryDetailScreenState();
}

class _CollectionsCategoryDetailScreenState extends ConsumerState<CollectionsCategoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _noAuthToken = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('\n╔═══════════════════════════════════════╗');
    print('║   SCREEN INITIALIZED                  ║');
    print('╚═══════════════════════════════════════╝');
    print('📱 Category: ${widget.category}');
    print('📝 Title: ${widget.title}');
    print('═══════════════════════════════════════\n');

    _initFunds();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(CollectionsCategoryDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When category changes, reset everything
    if (oldWidget.category != widget.category) {
      print('\n╔═══════════════════════════════════════╗');
      print('║   CATEGORY CHANGED                    ║');
      print('╚═══════════════════════════════════════╝');
      print('🔄 Old Category: ${oldWidget.category}');
      print('🔄 New Category: ${widget.category}');
      print('═══════════════════════════════════════\n');

      _resetState();
      _initFunds();
    }
  }

  void _resetState() {
    print('🧹 Resetting screen state...');
    _searchController.clear();
    _searchQuery = '';
    ref.read(selectedSubCategoriesProvider.notifier).state = [];
    print('✅ Screen state reset complete\n');
  }

  void _onScroll() {
    final state = ref.read(CollectionsCategoryDetailScreensProvider(widget.category));
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoading) {
      print('📜 Scroll threshold reached, loading next page...\n');
      ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).fetchNextPage();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
    });

    if (query.isNotEmpty) {
      print('🔍 Search query changed: "$query"\n');
      ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).searchFunds(query);
    } else {
      print('🔍 Search cleared, fetching all funds\n');
      ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).fetchFunds(reset: true);
    }
  }

  Future<void> _initFunds() async {
    print('🚀 Initializing funds...');
    final token = await SecureStore.getToken();
    if (token == null || token.isEmpty) {
      print('❌ No auth token found\n');
      setState(() => _noAuthToken = true);
      return;
    }
    print('✅ Auth token found');
    setState(() => _noAuthToken = false);

    print('📡 Fetching funds for category: ${widget.category}\n');
    await ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).fetchFunds(reset: true);
  }

  Future<void> _onFilterApplied(Map<String, Set<String>> filters) async {
    print('\n╔═══════════════════════════════════════╗');
    print('║   FILTERS APPLIED                     ║');
    print('╚═══════════════════════════════════════╝');

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

    print('🏢 AMCs: $amcIds');
    print('📂 Fund Categories: $fundCategoryIds');
    print('📁 Sub Categories: $subCategoryIds');
    print('⚠️  Risk Levels: $riskLevelIds');
    print('📊 Fund Sizes: $fundSizeIds');
    print('═══════════════════════════════════════\n');

    ref.read(selectedSubCategoriesProvider.notifier).state = subCategoryIds;

    await ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).applyFilters({
      "amcs": amcIds,
      "fund_category": fundCategoryIds,
      "sub_category": subCategoryIds,
      "risk_level": riskLevelIds,
      "fund_size": fundSizeIds,
    });
  }

  void _navigateToFundDetail(dynamic fund) {
    print('\n🔗 Navigating to fund detail:');
    print('   Fund ID: ${fund.fundId}');
    print('   Fund Name: ${fund.fundName}\n');

    context.go(
      '/fund-detail/${fund.fundId}',
      extra: {
        'fundId': fund.fundId,
        'fundName': fund.fundName,
        'category': fund.fundSubType ?? 'N/A',
        'minInvestment': fund.minimumInvestment != null
            ? '₹${fund.minimumInvestment!.toStringAsFixed(0)}'
            : 'N/A',
        'returns':
        '${fund.threeYearReturn >= 0 ? '+' : ''}${fund.threeYearReturn.toStringAsFixed(1)}%',
        'rating': fund.rating,
        'investorsCount': fund.totalCustomers ?? 0,
        'fundType': fund.fundType ?? 'N/A',
        'fundSubType': fund.fundSubType ?? 'N/A',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final CollectionsCategoryDetailScreensState = ref.watch(CollectionsCategoryDetailScreensProvider(widget.category));
    final selectedIds = ref.watch(selectedSubCategoriesProvider);

    return WillPopScope(
      onWillPop: () async {
        print('\n╔═══════════════════════════════════════╗');
        print('║   BACK BUTTON PRESSED                 ║');
        print('╚═══════════════════════════════════════╝');
        print('🔙 Navigating back to dashboard');
        print('🧹 Clearing state before exit\n');

        _resetState();
        ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).clearState();
        GoRouter.of(context).go("/dashboard");
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F5),
        body: SafeArea(
          child: Column(
            children: [
              CollectionsCategoryDetailScreenAppBar(
                title: widget.title,
                onFiltersApplied: _onFilterApplied,
                onBack: () {
                  print('\n╔═══════════════════════════════════════╗');
                  print('║   APP BAR BACK PRESSED                ║');
                  print('╚═══════════════════════════════════════╝');
                  print('🔙 Navigating back to dashboard\n');

                  _resetState();
                  ref.read(CollectionsCategoryDetailScreensProvider(widget.category).notifier).clearState();
                  GoRouter.of(context).go('/dashboard');
                },
              ),
              const SizedBox(height: 12),
              if (authState.isLoading)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF0060A6)),
                ),
              Expanded(
                child: authState.isAuthenticated
                    ? _buildFundsContent(CollectionsCategoryDetailScreensState, selectedIds)
                    : const AuthRequiredWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFundsContent(CollectionsCategoryDetailScreens CollectionsCategoryDetailScreensState, List<int> selectedIds) {
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
              : ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: CollectionsCategoryDetailScreensState.funds.length +
                (CollectionsCategoryDetailScreensState.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              if (index >= CollectionsCategoryDetailScreensState.funds.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final fund = CollectionsCategoryDetailScreensState.funds[index];
              return DiscoverFundCard(
                logoPath: AppStrings.iconFunds_png,
                fundName: fund.fundName,
                productTitle: "${fund.fundType} • ${fund.fundSubType}",
                threeYearReturnValue: fund.threeYearReturn,
                minimumInvestment: fund.minimumInvestment?.toDouble(),
                rating: fund.rating,
                onTap: () => _navigateToFundDetail(fund),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    print('\n╔═══════════════════════════════════════╗');
    print('║   SCREEN DISPOSED                     ║');
    print('╚═══════════════════════════════════════╝');
    print('🗑️  Category: ${widget.category}');
    print('═══════════════════════════════════════\n');

    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}