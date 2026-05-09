import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/strings.dart';
import '../core/config/env.dart';
import '../core/network/connection.dart';
import '../features/funds/data/models/popular_fund.dart';
import '../features/funds/data/repos/popular_fund_repo.dart';
import 'fund_card.dart';

class HorizontalCardList extends StatefulWidget {
  final String? previousRoute;

  const HorizontalCardList({
    super.key,
    this.previousRoute,
  });

  @override
  State<HorizontalCardList> createState() => _HorizontalCardListState();
}

class _HorizontalCardListState extends State<HorizontalCardList> {
  List<PopularFund>? _funds;
  bool _isLoading = true;

  ScrollController? _topController;
  ScrollController? _bottomController;

  bool _isSyncingScroll = false;
  bool _isDisposed = false;

  static const double _rowHeight = 150;
  static const double _rowSpacing = 12;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [HorizontalCardList] Initializing...");
    _initializeControllers();
    _loadFunds();
  }

  void _initializeControllers() {
    _topController = ScrollController();
    _bottomController = ScrollController();
    _setupScrollSynchronization();
  }

  void _setupScrollSynchronization() {
    _topController?.addListener(_handleTopScroll);
    _bottomController?.addListener(_handleBottomScroll);
  }

  void _handleTopScroll() {
    if (_isDisposed || _isSyncingScroll) return;
    if (_topController?.hasClients != true || _bottomController?.hasClients != true) return;
    _syncScroll(_topController!, _bottomController!);
  }

  void _handleBottomScroll() {
    if (_isDisposed || _isSyncingScroll) return;
    if (_topController?.hasClients != true || _bottomController?.hasClients != true) return;
    _syncScroll(_bottomController!, _topController!);
  }

  void _syncScroll(ScrollController source, ScrollController target) {
    if (_isSyncingScroll || _isDisposed) return;

    _isSyncingScroll = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted || !source.hasClients || !target.hasClients) {
        _isSyncingScroll = false;
        return;
      }

      try {
        if (target.offset != source.offset) {
          target.jumpTo(
            source.offset.clamp(
              target.position.minScrollExtent,
              target.position.maxScrollExtent,
            ),
          );
        }
      } catch (e) {
        debugPrint('Scroll sync error: $e');
      } finally {
        _isSyncingScroll = false;
      }
    });
  }

  Future<void> _loadFunds() async {
    final result = await ConnectionHelper.executeWithAutoRetry<List<PopularFund>>(
      operation: () async {
        debugPrint("📦 [HorizontalCardList] Loading funds...");
        final repo = PopularFundRepo(baseUrl: EnvConfig.apiBaseUrl);
        final funds = await repo.fetchPopularFunds(page: 1, pageSize: 10);
        debugPrint("✅ [HorizontalCardList] Loaded ${funds.length} funds");
        return funds;
      },
      onSuccess: () {
        debugPrint("✅ [HorizontalCardList] Funds loaded successfully");
      },
    );

    if (mounted) {
      setState(() {
        _funds = result ?? [];
        _isLoading = false;
      });
    }
  }

  Widget _buildFundRow(List<PopularFund> funds, ScrollController? controller, String rowKey) {
    return SizedBox(
      height: _rowHeight,
      child: ListView.builder(
        key: ValueKey(rowKey),
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: funds.length,
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        cacheExtent: 1000,
        itemBuilder: (context, index) {
          final fund = funds[index];
          return _FundCardWrapper(
            key: ValueKey('fund_${fund.fundId}_$rowKey'),
            fund: fund,
            previousRoute: widget.previousRoute,
          );
        },
      ),
    );
  }

  Widget _buildShimmerRow(ScrollController? controller, String shimmerKey) {
    return SizedBox(
      height: _rowHeight,
      child: ListView.separated(
        key: ValueKey(shimmerKey),
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 280,
            height: _rowHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show shimmer while loading or if there's no data yet
    if (_isLoading || _funds == null) {
      return Column(
        children: [
          _buildShimmerRow(_topController, 'shimmer_top'),
          const SizedBox(height: _rowSpacing),
          _buildShimmerRow(_bottomController, 'shimmer_bottom'),
        ],
      );
    }

    // If we have data, show it
    final funds = _funds!;
    if (funds.isEmpty) {
      // Even on empty, keep retrying in background, show shimmer
      return Column(
        children: [
          _buildShimmerRow(_topController, 'shimmer_top'),
          const SizedBox(height: _rowSpacing),
          _buildShimmerRow(_bottomController, 'shimmer_bottom'),
        ],
      );
    }

    final firstRow = funds.take(5).toList();
    final secondRow = funds.length > 5 ? funds.sublist(5) : <PopularFund>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFundRow(firstRow, _topController, 'top_row'),
        if (secondRow.isNotEmpty) ...[
          const SizedBox(height: _rowSpacing),
          _buildFundRow(secondRow, _bottomController, 'bottom_row'),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _topController?.removeListener(_handleTopScroll);
    _bottomController?.removeListener(_handleBottomScroll);

    _topController?.dispose();
    _bottomController?.dispose();

    _topController = null;
    _bottomController = null;

    super.dispose();
  }
}

class _FundCardWrapper extends StatelessWidget {
  final PopularFund fund;
  final String? previousRoute;

  const _FundCardWrapper({
    super.key,
    required this.fund,
    this.previousRoute,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: 330,
        child: FundCard(
          logoPath: AppStrings.iconFunds_png,
          fundName: fund.fundName,
          category: "${fund.fundType} • ${fund.fundSubType}",
          minInvestment: "₹${fund.minimumInvestment}",
          returns: "${fund.threeYearReturn.toStringAsFixed(1)}%",
          investorsCount: "${fund.totalCustomers}+ ${AppStrings.people_invested}",
          fundId: fund.fundId,
          investorIconPath: AppStrings.above_sign,
          previousRoute: previousRoute,
        ),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is _FundCardWrapper &&
              runtimeType == other.runtimeType &&
              fund.fundId == other.fund.fundId;

  @override
  int get hashCode => fund.fundId.hashCode;
}