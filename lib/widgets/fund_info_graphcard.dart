import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jhaveri_jsl_app/core/utils/date_utils.dart';
import '../constants/strings.dart';
import '../providers/fund_info_provider.dart';
import '../providers/nav_history_provider.dart';

class FundGraphInfoScreen extends ConsumerStatefulWidget {
  final int fundId;

  const FundGraphInfoScreen({super.key, required this.fundId});

  @override
  ConsumerState<FundGraphInfoScreen> createState() =>
      _FundGraphInfoScreenState();
}

class _FundGraphInfoScreenState extends ConsumerState<FundGraphInfoScreen> {
  String selectedPeriod = "3y";

  @override
  void initState() {
    super.initState();
    print("=== [FUND GRAPH] initState called for fundId: ${widget.fundId} ===");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("[FUND GRAPH] Fetching initial data - fundId: ${widget.fundId}, period: $selectedPeriod");
      ref.read(fundInfoProvider.notifier).fetchFundInfo(widget.fundId);
      ref.read(navHistoryProvider.notifier)
          .fetchNavHistory(widget.fundId, period: selectedPeriod);
    });
  }

  void _onPeriodChanged(String period) {
    print("=== [PERIOD CHANGE] User selected period: $period ===");
    print("[PERIOD CHANGE] Previous period: $selectedPeriod -> New period: $period");
    print("[PERIOD CHANGE] FundId: ${widget.fundId}");

    setState(() {
      selectedPeriod = period;
    });

    print("[API CALL] Starting fetchNavHistory for fundId: ${widget.fundId}, period: $period");
    print("[API CALL] Timestamp: ${DateTime.now()}");

    ref.read(navHistoryProvider.notifier)
        .fetchNavHistory(widget.fundId, period: period);
  }

  @override
  Widget build(BuildContext context) {
    final fundInfoAsync = ref.watch(fundInfoProvider);
    final navHistoryAsync = ref.watch(navHistoryProvider);

    return fundInfoAsync.when(
      data: (fundInfo) {
        print("=== [FUND INFO] Fund information loaded ===");
        print("[FUND INFO] Name: ${fundInfo?.fundName ?? 'NULL'}");
        print("[FUND INFO] NAV: ${fundInfo?.nav ?? 'NULL'}");
        print("[FUND INFO] Static Returns: ${fundInfo?.returns ?? 'NULL'}%");
        print("[FUND INFO] Category: ${fundInfo?.fundCategory ?? 'NULL'}");

        if (fundInfo == null) {
          print("❌ [FUND INFO] Fund information is NULL!");
          return const Center(child: Text("No fund information available"));
        }

        return navHistoryAsync.when(
          data: (navHistory) {
            print("=== [DATA RECEIVED] NAV History data received ===");
            print("[DATA] Fund: ${fundInfo.fundName}");
            print("[DATA] Returns from API: ${navHistory?.returns ?? 'NULL'}");
            print("[DATA] Fallback returns (fundInfo): ${fundInfo.returns}");
            print("[DATA] NAV data points: ${navHistory?.navList ?.length ?? 0}");
            print("[DATA] Current period: $selectedPeriod");

            if (navHistory?.navList != null && navHistory!.navList.isNotEmpty) {
              print("[NAV DATA] First point: Date=${navHistory.navList.first.date}, NAV=${navHistory.navList.first.nav}");
              print("[NAV DATA] Last point: Date=${navHistory.navList.last.date}, NAV=${navHistory.navList.last.nav}");
              print("[NAV DATA] All NAV values: ${navHistory.navList.map((e) => e.nav).join(', ')}");
            } else {
              print("[NAV DATA] ⚠️  No NAV data points available!");
            }

            final double returnsValue = navHistory?.returns ?? fundInfo.returns;
            final List<NavDataPoint> navList = navHistory?.navList ?? [];

            print("[CHART UPDATE] Using returns: $returnsValue%");
            print("[CHART UPDATE] Chart will render with ${navList.length} data points");
            print("=== [DATA PROCESSING] Complete ===\n");

            return _buildFundDetails(fundInfo, returnsValue, navList);
          },
          loading: () {
            print("⏳ [LOADING] NAV History data is loading...");
            print("[LOADING] Fund: ${fundInfo.fundName}, Period: $selectedPeriod");
            return _buildLoadingState(fundInfo);
          },
          error: (error, _) {
            print("❌ [ERROR] Failed to fetch NAV History data");
            print("[ERROR] Fund: ${fundInfo.fundName}");
            print("[ERROR] Period: $selectedPeriod");
            print("[ERROR] Details: $error");
            return _buildErrorState(fundInfo, error);
          },
        );
      },
      loading: () => _buildShimmerLoadingState(),
      error: (error, _) => Center(child: Text("Error: ${error.toString()}")),
    );
  }

  Widget _buildShimmerLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerContainer(width: 32, height: 32, borderRadius: 6),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildShimmerContainer(width: double.infinity, height: 16, borderRadius: 4),
                          const SizedBox(height: 4),
                          _buildShimmerContainer(width: 150, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildShimmerContainer(width: 80, height: 28, borderRadius: 14),
                    const SizedBox(width: 8),
                    _buildShimmerContainer(width: 90, height: 28, borderRadius: 14),
                    const SizedBox(width: 8),
                    _buildShimmerContainer(width: 60, height: 28, borderRadius: 14),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerContainer(width: 120, height: 24, borderRadius: 4),
                        const SizedBox(height: 4),
                        _buildShimmerContainer(width: 100, height: 14, borderRadius: 4),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildShimmerContainer(width: 80, height: 18, borderRadius: 4),
                        const SizedBox(height: 4),
                        _buildShimmerContainer(width: 70, height: 14, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildShimmerChart(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(6, (index) =>
                      _buildShimmerContainer(width: 40, height: 32, borderRadius: 16)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(FundInfoModel fundInfo) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFundHeader(fundInfo),
                const SizedBox(height: 16),
                _buildChipsRow(fundInfo),
                const SizedBox(height: 20),
                _buildNavAndReturns(fundInfo, fundInfo.returns),
                const SizedBox(height: 20),
                _buildShimmerChart(),
                const SizedBox(height: 12),
                _buildTimeButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FundInfoModel fundInfo, Object error) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFundHeader(fundInfo),
                const SizedBox(height: 16),
                _buildChipsRow(fundInfo),
                const SizedBox(height: 20),
                _buildNavAndReturns(fundInfo, fundInfo.returns),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          "Failed to load chart data",
                          style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _onPeriodChanged(selectedPeriod),
                          child: Text(
                            "Tap to retry",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTimeButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundDetails(FundInfoModel fundInfo, double returnsValue, List<NavDataPoint> navList) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFundHeader(fundInfo),
                const SizedBox(height: 16),
                _buildChipsRow(fundInfo),
                const SizedBox(height: 20),
                _buildNavAndReturns(fundInfo, returnsValue),
                const SizedBox(height: 20),
                _buildAreaChart(navList),
                const SizedBox(height: 12),
                _buildTimeButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFundHeader(FundInfoModel fundInfo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Image.asset(
            AppStrings.iconFunds_png,
            fit: BoxFit.contain,
            width: 32,
            height: 32,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            fundInfo.fundName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChipsRow(FundInfoModel fundInfo) {
    return Row(
      children: [
        _buildChip(fundInfo.fundCategory),
        const SizedBox(width: 8),
        _buildChip(fundInfo.fundSubCategory),
        const SizedBox(width: 8),
        _buildRatingChip(fundInfo.rating),
      ],
    );
  }

  Widget _buildNavAndReturns(FundInfoModel fundInfo, double returnsValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "₹${fundInfo.nav.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "NAV (${DateUtilsHelper.formatDate(fundInfo.navDate)})",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${returnsValue.toStringAsFixed(2)}%",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: returnsValue >= 0
                    ? Colors.green.shade600
                    : Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.yr_returns_fund,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAreaChart(List<NavDataPoint> navList) {
    print("=== [CHART RENDER] Building area chart ===");
    print("[CHART] Data points received: ${navList.length}");

    if (navList.isEmpty) {
      print("[CHART] ⚠️  No data available - showing placeholder");
      return Container(
        width: double.infinity,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "No chart data available",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    final navValues = navList.map((e) => e.nav).toList();
    final minNav = navValues.reduce((a, b) => a < b ? a : b);
    final maxNav = navValues.reduce((a, b) => a > b ? a : b);

    print("[CHART] NAV range: Min=$minNav, Max=$maxNav");
    print("[CHART] Period: $selectedPeriod");
    print("[CHART] Data points for rendering:");
    for (int i = 0; i < navList.length; i++) {
      print("[CHART]   [$i] ${navList[i].date}: ₹${navList[i].nav}");
    }

    final padding = (maxNav - minNav) * 0.1;
    final chartMinY = minNav - padding;
    final chartMaxY = maxNav + padding;

    print("[CHART] Chart Y-axis: Min=$chartMinY, Max=$chartMaxY");
    print("[CHART] Rendering chart with fl_chart library");
    print("=== [CHART RENDER] Complete ===\n");

    return SizedBox(
      width: double.infinity,
      height: 220,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => const Color(0xFF0060A6),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final index = touchedSpot.x.toInt();
                  if (index >= 0 && index < navList.length) {
                    final dataPoint = navList[index];
                    print("[TOOLTIP] Showing data for point $index: ${dataPoint.date} - ₹${dataPoint.nav}");
                    return LineTooltipItem(
                      "${dataPoint.date}\n₹${dataPoint.nav.toStringAsFixed(2)}",
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (navList.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: navList.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.nav);
              }).toList(),
              isCurved: true,
              color: const Color(0xFF0060A6),
              barWidth: 2,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0060A6).withOpacity(0.3),
                    const Color(0xFF0060A6).withOpacity(0.1),
                    const Color(0xFF0060A6).withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ["1m", "6m", "1y", "3y", "5y", "max"]
          .map((period) => _buildTimeButton(period))
          .toList(),
    );
  }

  Widget _buildShimmerChart() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          _buildShimmerContainer(
            width: double.infinity,
            height: 220,
            borderRadius: 8,
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: _buildShimmerContainer(
              width: double.infinity,
              height: 2,
              borderRadius: 1,
            ),
          ),
          ...List.generate(8, (index) {
            final double height = 20 + (index % 4) * 15.0;
            final double leftOffset = 20.0 + index * 35.0;
            return Positioned(
              bottom: 20,
              left: leftOffset,
              child: _buildShimmerContainer(
                width: 8,
                height: height,
                borderRadius: 4,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShimmerContainer({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1500),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const _ShimmerWidget(),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  Widget _buildChip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE3F3FE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFF10102B)),
    ),
  );

  Widget _buildRatingChip(double rating) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFE3F3FE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.star, color: Color(0xFF0060A6), size: 14),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10102B)),
        ),
      ],
    ),
  );

  Widget _buildTimeButton(String period) {
    final isSelected = selectedPeriod.toLowerCase() == period.toLowerCase();
    return GestureDetector(
      onTap: () {
        print("🔘 [USER ACTION] Time button tapped: $period");
        print("[USER ACTION] Currently selected: $selectedPeriod");
        if (isSelected) {
          print("[USER ACTION] Same period selected - no API call needed");
        } else {
          print("[USER ACTION] Different period - triggering API call");
        }
        _onPeriodChanged(period);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0060A6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          period,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  const _ShimmerWidget();

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutSine,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.white.withOpacity(0.85),
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        );
      },
    );
  }
}