import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/config/env.dart';
import '../core/token_helper.dart';
import '../widgets/discover_all_mutual_fund_card.dart';
import '../constants/strings.dart';
import 'package:go_router/go_router.dart';

/// --- Riverpod Provider for Watchlist ---
class WatchlistNotifier extends StateNotifier<List<int>> {
  WatchlistNotifier() : super([]);

  void setWatchlist(List<int> fundIds) => state = fundIds;

  void removeFund(int fundId) => state = state.where((id) => id != fundId).toList();

  void toggleFund(int fundId) {
    if (state.contains(fundId)) {
      state = state.where((id) => id != fundId).toList();
    } else {
      state = [...state, fundId];
    }
  }
}

final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<int>>(
      (ref) => WatchlistNotifier(),
);

/// --- Watchlist Widget with Search ---
class WatchlistFundsList extends ConsumerStatefulWidget {
  const WatchlistFundsList({super.key});

  @override
  ConsumerState<WatchlistFundsList> createState() => _WatchlistFundsListState();
}

class _WatchlistFundsListState extends ConsumerState<WatchlistFundsList> {
  List<Map<String, dynamic>> funds = [];
  bool isLoading = true;
  String? error;

  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = "";

  @override
  void initState() {
    super.initState();
    _fetchWatchlistFunds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWatchlistFunds({String searchTerm = ""}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      error = null;
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
        "page": 1,
        "page_size": 50,
        "search_term": searchTerm,
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
        if (apiData != null && apiData['data_list'] != null) {
          final List<Map<String, dynamic>> list = (apiData['data_list'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          final fundIds = list.map((e) => e['fund_id'] as int).toList();
          ref.read(watchlistProvider.notifier).setWatchlist(fundIds);

          if (!mounted) return;
          setState(() {
            funds = list;
            isLoading = false;
            error = null;
          });
        } else {
          if (!mounted) return;
          setState(() {
            funds = [];
            isLoading = false;
            error = searchTerm.isEmpty ? "No funds found." : "No matching funds found.";
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          error = "Failed to fetch funds: ${response.statusCode}";
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

  void _onSearchChanged(String value) {
    setState(() {
      _searchTerm = value;
    });
    // Debounce search - wait for user to stop typing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchTerm == value && mounted) {
        _fetchWatchlistFunds(searchTerm: value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchTerm = "";
    });
    _fetchWatchlistFunds(searchTerm: "");
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
        await _fetchWatchlistFunds(searchTerm: _searchTerm);
      }
    } catch (e) {
      debugPrint("Error removing fund: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = ref.watch(watchlistProvider);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search Your Saved Funds',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF0060A6)),
              suffixIcon: _searchTerm.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: _clearSearch,
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0060A6), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // List Content
        Expanded(
          child: _buildContent(watchlist),
        ),
      ],
    );
  }

  Widget _buildContent(List<int> watchlist) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0060A6)),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0060A6),
                foregroundColor: Colors.white,
              ),
              onPressed: () => _fetchWatchlistFunds(searchTerm: _searchTerm),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (funds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchTerm.isEmpty
                  ? "No funds in watchlist"
                  : "No matching funds found",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (_searchTerm.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _clearSearch,
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchWatchlistFunds(searchTerm: _searchTerm),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: funds.length,
        itemBuilder: (context, index) {
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