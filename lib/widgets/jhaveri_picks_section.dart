import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../constants/strings.dart';
import '../../../../widgets/jhaveri_picks_fundcard.dart';
import '../providers/jhaveri_picks_provider.dart';

class JhaveriPicksSection extends ConsumerStatefulWidget {
  final String title;
  final int maxItems;
  final VoidCallback onViewAllTap;
  final bool showShimmer;

  const JhaveriPicksSection({
    super.key,
    required this.title,
    required this.onViewAllTap,
    this.maxItems = 5,
    this.showShimmer = true,
  });

  @override
  ConsumerState<JhaveriPicksSection> createState() =>
      _JhaveriPicksSectionState();
}

class _JhaveriPicksSectionState extends ConsumerState<JhaveriPicksSection> {
  @override
  void initState() {
    super.initState();
    // Don't fetch here - let DiscoverScreen handle it based on auth
    debugPrint("[JhaveriPicksSection] Widget initialized");
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jhaveriPicksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium),
              GestureDetector(
                onTap: widget.onViewAllTap,
                child: const Text(
                  AppStrings.view_all_funds,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildContent(state),
      ],
    );
  }

  Widget _buildContent(JhaveriPicksState state) {
    debugPrint("[JhaveriPicksSection] Building content - Loading: ${state.isLoading}, Error: ${state.hasError}, Funds: ${state.funds.length}");

    if (state.isLoading) {
      return widget.showShimmer ? _buildShimmer() : const SizedBox.shrink();
    }

    if (state.hasError) {
      return _buildError(state.errorMessage);
    }

    if (state.funds.isEmpty) {
      return _buildEmpty();
    }

    return _buildFundsList(state.funds);
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          3,
              (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0060A6),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String errorMessage) {
    debugPrint("❌ [JhaveriPicksSection] Displaying error: $errorMessage");

    final isAuthError = errorMessage == "AUTH_ERROR" ||
        errorMessage.contains("No valid access token");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAuthError ? Icons.lock_outline : Icons.error_outline,
              size: 48,
              color: isAuthError ? Colors.orange[300] : Colors.red[300],
            ),
            const SizedBox(height: 12),
            Text(
              isAuthError ? "Login Required" : "Failed to load funds",
              style: TextStyle(
                color: isAuthError ? Colors.orange[700] : Colors.red[700],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAuthError
                  ? "Please login to view Jhaveri Picks"
                  : errorMessage.replaceAll('Exception: ', ''),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (isAuthError)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => context.push('/login'),
                child: const Text("Login Now"),
              )
            else
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0060A6),
                  side: const BorderSide(color: Color(0xFF0060A6)),
                ),
                onPressed: () {
                  debugPrint("🔄 [JhaveriPicks] User clicked retry");
                  ref.read(jhaveriPicksProvider.notifier).fetchFunds();
                },
                child: const Text("Retry"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              "No funds available",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFundsList(List<dynamic> funds) {
    final items = funds.take(widget.maxItems).toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final fund = items[index];

        // Debug print to see the actual fund object
        debugPrint("📊 [JhaveriPicksSection] Fund data: ${fund.toString()}");
        debugPrint("📊 [JhaveriPicksSection] Minimum Investment: ${fund.minimumInvestment}");

        final safeFundId = fund.fundId;
        final safeFundName = fund.fundName.isNotEmpty
            ? fund.fundName
            : "Unknown Fund";
        final safeCategory = "${fund.fundType.isNotEmpty ? fund.fundType : "N/A"} • ${fund.fundSubType.isNotEmpty ? fund.fundSubType : "N/A"}";

        // FIXED: Properly handle int minimumInvestment
        final safeMinInvestment = fund.minimumInvestment > 0
            ? "₹${fund.minimumInvestment}"
            : "N/A";

        final safeReturns = fund.threeYearReturn != 0.0
            ? "${fund.threeYearReturn.toStringAsFixed(2)}%"
            : "N/A";
        final safeRating = fund.rating.toString();
        final safeInvestors = fund.totalCustomers.toString();

        debugPrint("💰 [JhaveriPicksSection] Displaying min investment: $safeMinInvestment (raw: ${fund.minimumInvestment})");

        return JhaveriFundCard(
          logoPath: AppStrings.iconFunds_png,
          fundName: safeFundName,
          category: safeCategory,
          minInvestment: safeMinInvestment,
          returns: safeReturns,
          onTap: () {
            debugPrint("🔥 [JhaveriPicksSection] Tapped fund: $safeFundId");
            context.push(
              '/fund-details/$safeFundId',
              extra: {
                'fundName': safeFundName,
                'category': safeCategory,
                'minInvestment': safeMinInvestment,
                'returns': safeReturns,
                'rating': safeRating,
                'investorsCount': safeInvestors,
              },
            );
          },
        );
      },
    );
  }
}