import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../constants/strings.dart';
import '../widgets/discover_all_mutual_fund_card.dart';
import 'package:go_router/go_router.dart';
import '../providers/watchlist_provider.dart';

class LargeCapFundsList extends ConsumerStatefulWidget {
  final int pageSize;

  const LargeCapFundsList({super.key, this.pageSize = 20});

  @override
  ConsumerState<LargeCapFundsList> createState() => _LargeCapFundsListState();
}

class _LargeCapFundsListState extends ConsumerState<LargeCapFundsList> {
  List<Map<String, dynamic>> funds = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  int currentPage = 1;
  int totalPages = 1;
  String? error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchFunds();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50 &&
          !isLoadingMore &&
          currentPage < totalPages) {
        _loadMoreFunds();
      }
    });
  }

  /// Fetch funds from watchlist API
  Future<void> _fetchFunds({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
      funds.clear();
      error = null;
    }

    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          error = "Please login to view watchlist.";
          isLoading = false;
        });
        return;
      }

      final body = {
        "page": currentPage,
        "page_size": widget.pageSize,
        "search_term": "",
        "sort_order": "",
        "sort_by": "",
        "filter": {
          "amcs": [],
          "fund_category": [],
          "sub_category": [],
          "risk_level": [],
          "fund_size": []
        }
      };

      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/funds/watchlist'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final apiData = data['data'];
        final List<dynamic> list = apiData?['data_list'] ?? [];

        funds.addAll(list.map((e) => Map<String, dynamic>.from(e)));
        totalPages = apiData?['total_pages'] ?? 1;

        // Update watchlist provider
        final fundIds = list.map<int>((e) => e['fund_id'] as int).toList();
        ref.read(watchlistProvider.notifier).setWatchlist(fundIds);

        if (!mounted) return;
        setState(() {
          error = null;
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          error = "HTTP error: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Network error: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreFunds() async {
    if (isLoadingMore || currentPage >= totalPages) return;
    isLoadingMore = true;
    currentPage++;
    await _fetchFunds();
    isLoadingMore = false;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshFunds() async {
    await _fetchFunds(isRefresh: true);
  }

  Future<void> _removeFromWatchlist(int fundId, String fundName) async {
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) return;

      final body = {"action": "remove", "fund_id": fundId};
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/funds/watchlist/add-remove'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      final success = data['status'] == 1;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? "Removed '$fundName' from watchlist"
              : data['message'] ?? "Failed to update watchlist"),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade600,
        ),
      );

      if (success) {
        ref.read(watchlistProvider.notifier).removeFund(fundId);
        await _fetchFunds(isRefresh: true);
      }
    } catch (e) {
      debugPrint("Error removing fund: $e");
    }
  }

  Widget _shimmerCard() => Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);

    if (isLoading && funds.isEmpty) {
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => _shimmerCard(),
      );
    }

    if (error != null && funds.isEmpty) {
      return Center(child: Text(error!));
    }

    if (funds.isEmpty) {
      return const Center(child: Text("No funds in watchlist"));
    }

    return RefreshIndicator(
      onRefresh: _refreshFunds,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: funds.length + (isLoadingMore ? 3 : 0),
        itemBuilder: (context, index) {
          if (index >= funds.length) return _shimmerCard();

          final fund = funds[index];
          final fundId = fund['fund_id'] as int?;
          final fundName = fund['fund_name'] ?? 'Unknown Fund';
          final threeYearReturn =
              (fund['three_year_return'] as num?)?.toDouble() ?? 0.0;
          final minInvestment =
          (fund['minimum_investment'] as num?)?.toDouble();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DiscoverFundCard(
              fundName: fundName,
              productTitle:
              "${fund['fund_type'] ?? ''} - ${fund['fund_sub_type'] ?? ''}",
              threeYearReturnValue: threeYearReturn,
              minimumInvestment: minInvestment,
              logoPath: AppStrings.iconFunds_png,
              isSaved: fundId != null && watchlist.contains(fundId),
              onSave: () {
                if (fundId != null) _removeFromWatchlist(fundId, fundName);
              },
              onTap: () {
                if (fundId != null) {
                  GoRouter.of(context).go(
                    '/fund-details/$fundId',
                    extra: {
                      'fund_id': fundId,
                      'fund_name': fundName,
                      'category': fund['fund_category'] ?? 'N/A',
                      'minInvestment': minInvestment?.toString() ?? 'N/A',
                      'returns': threeYearReturn.toString(),
                      'rating': fund['rating']?.toString() ?? 'N/A',
                      'investorsCount': fund['investors_count']?.toString() ?? 'N/A',
                      'fund_type': fund['fund_type'] ?? '',
                      'fund_sub_type': fund['fund_sub_type'] ?? '',
                    },
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}