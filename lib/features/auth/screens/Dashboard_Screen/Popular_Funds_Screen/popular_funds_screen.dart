// File: lib/features/auth/presentation/screens/popular_funds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../../../../../widgets/fund_card.dart';
import '../../../../../constants/strings.dart';
import '../../../../funds/data/models/popular_fund.dart';
import '../../../../funds/data/repos/popular_fund_repo.dart';


class PopularFundsScreen extends StatefulWidget {
  const PopularFundsScreen({super.key});

  @override
  State<PopularFundsScreen> createState() => _PopularFundsScreenState();
}

class _PopularFundsScreenState extends State<PopularFundsScreen> {
  late final PopularFundRepo _repo;
  final List<PopularFund> _funds = [];
  final ScrollController _scrollController = ScrollController();

  int _nextPage = 1;
  final int _pageSize = 10;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [PopularFundsScreen] Initializing...");
    final baseUrl = EnvConfig.apiBaseUrl;
    debugPrint("🔗 [PopularFundsScreen] API Base URL: $baseUrl");
    _repo = PopularFundRepo(baseUrl: baseUrl);
    _loadNextPage();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        debugPrint("🔄 [PopularFundsScreen] Loading more funds...");
        _loadNextPage();
      }
    });
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore) return;

    debugPrint("📦 [PopularFundsScreen] Loading page $_nextPage...");
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final pageFunds = await _repo.fetchPopularFunds(page: _nextPage, pageSize: _pageSize, filters: {});

      debugPrint("✅ [PopularFundsScreen] Loaded ${pageFunds.length} funds from page $_nextPage");
      for (var fund in pageFunds) {
        debugPrint("📊 [PopularFundsScreen] Fund loaded - ID: ${fund.fundId}, Name: ${fund.fundName}");
      }

      setState(() {
        _funds.addAll(pageFunds);
        if (pageFunds.length < _pageSize) {
          _hasMore = false;
          debugPrint("🔚 [PopularFundsScreen] No more funds to load");
        } else {
          _nextPage++;
        }
      });
    } catch (e) {
      debugPrint('❌ [PopularFundsScreen] Error loading popular funds page $_nextPage: $e');
      setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    debugPrint("🔄 [PopularFundsScreen] Refreshing all funds...");
    setState(() {
      _funds.clear();
      _nextPage = 1;
      _hasMore = true;
      _hasError = false;
    });
    await _loadNextPage();
  }

  void _handleBackNavigation() {
    debugPrint("⬅️ [PopularFundsScreen] Back button pressed");
    debugPrint("Navigation state - canPop: ${context.canPop()}");

    if (context.canPop()) {
      context.pop();
    } else {
      // Fallback navigation - go to dashboard
      context.go('/dashboard');
    }
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("❌ Failed to load data."),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _refreshAll, child: const Text("Retry")),
        ],
      ),
    );
  }

  @override
  void dispose() {
    debugPrint("🗑️ [PopularFundsScreen] Disposing...");
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("🏗️ [PopularFundsScreen] Building with ${_funds.length} funds");

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        debugPrint("🔙 [PopularFundsScreen] PopScope triggered - didPop: $didPop");
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF1F3F5),
          elevation: 0,
          leading: IconButton(
            onPressed: _handleBackNavigation,
            icon: SvgPicture.asset(
              AppStrings.back_icon,
              width: 26,
              height: 26,
              color: Colors.black,
            ),
          ),
          title: const Text(
            AppStrings.pop_funds,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: _hasError && _funds.isEmpty
            ? _buildError()
            : _funds.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _funds.length + (_hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= _funds.length) {
                  debugPrint("🔄 [PopularFundsScreen] Loading indicator shown");
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final fund = _funds[index];
                final screenWidth = MediaQuery.of(context).size.width;

                debugPrint("🎨 [PopularFundsScreen] Rendering fund card for ID: ${fund.fundId}, Name: ${fund.fundName}");

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: screenWidth - 16,
                    child: FundCard(
                      logoPath: AppStrings.iconFunds_png,
                      fundName: fund.fundName,
                      category: "${fund.fundType} • ${fund.fundSubType}",
                      minInvestment: "₹${fund.minimumInvestment}",
                      returns: "${fund.threeYearReturn.toStringAsFixed(1)}%",
                      investorsCount: "${fund.totalCustomers}+ ${AppStrings.people_invested}",
                      investorIconPath: AppStrings.above_sign,
                      fundId: fund.fundId, // Critical: Pass the fund ID
                    ),
                  ),
                );
              }
          ),
        ),
      ),
    );
  }
}