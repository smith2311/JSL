import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class FundCard extends StatelessWidget {
  final String logoPath;
  final String fundName;
  final String category;
  final String minInvestment;
  final String returns;
  final String investorsCount;
  final int? fundId;
  final String? investorIconPath;
  final String? previousRoute; // ✅ Add this parameter

  const FundCard({
    super.key,
    required this.logoPath,
    required this.fundName,
    required this.category,
    required this.minInvestment,
    required this.returns,
    required this.investorsCount,
    this.fundId,
    this.investorIconPath,
    this.previousRoute, // ✅ Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = returns.startsWith("+") || (!returns.startsWith("-") && !returns.contains("-"));

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        width: 330,
        height: 160,
        padding: const EdgeInsets.only(top: 5, right: 10, left: 10),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Logo + Name + Category
            _FundHeader(
              logoPath: logoPath,
              fundName: fundName,
              category: category,
            ),
            const SizedBox(height: 19),

            // Middle Row: Min Investment + 3Y Returns
            _FundMetrics(
              minInvestment: minInvestment,
              returns: returns,
              isPositive: isPositive,
            ),
            const SizedBox(height: 23),

            // Bottom Row: Investors
            _InvestorsBadge(
              investorsCount: investorsCount,
              investorIconPath: investorIconPath,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    debugPrint("🔥 [FundCard] Fund tapped!");
    debugPrint("📊 [FundCard] Fund ID: $fundId");
    debugPrint("📊 [FundCard] Fund Name: $fundName");
    debugPrint("🔙 [FundCard] Previous Route: $previousRoute"); // ✅ Log previous route

    if (fundId != null) {
      debugPrint("🚀 [FundCard] Navigating to fund details with ID: $fundId");
      context.push('/fund-details/$fundId', extra: {
        'fundName': fundName,
        'category': category,
        'minInvestment': minInvestment,
        'returns': returns,
        'investorsCount': investorsCount,
        'previousRoute': previousRoute, // ✅ Pass previousRoute in extra
      });
    } else {
      debugPrint("⚠️ [FundCard] No fund ID available for navigation");
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FundCard &&
              runtimeType == other.runtimeType &&
              fundId == other.fundId &&
              fundName == other.fundName &&
              returns == other.returns;

  @override
  int get hashCode => Object.hash(fundId, fundName, returns);
}

// Separate widget for fund header to prevent unnecessary rebuilds
class _FundHeader extends StatelessWidget {
  final String logoPath;
  final String fundName;
  final String category;

  const _FundHeader({
    required this.logoPath,
    required this.fundName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          logoPath,
          width: 24,
          height: 24,
          // Add caching to prevent image reloads
          cacheWidth: 48,
          cacheHeight: 48,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fundName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Separate widget for fund metrics
class _FundMetrics extends StatelessWidget {
  final String minInvestment;
  final String returns;
  final bool isPositive;

  const _FundMetrics({
    required this.minInvestment,
    required this.returns,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MetricColumn(
          label: "Min. Investment",
          value: minInvestment,
          valueColor: Colors.black,
        ),
        _MetricColumn(
          label: "3Y Returns",
          value: returns,
          valueColor: isPositive ? Colors.green : Colors.red,
          alignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}

// Reusable metric column widget
class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final CrossAxisAlignment alignment;

  const _MetricColumn({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF888898),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// Separate widget for investors badge
class _InvestorsBadge extends StatelessWidget {
  final String investorsCount;
  final String? investorIconPath;

  const _InvestorsBadge({
    required this.investorsCount,
    this.investorIconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFE3F3FE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (investorIconPath != null) ...[
            SvgPicture.asset(
              investorIconPath!,
              width: 14,
              height: 14,
              colorFilter: const ColorFilter.mode(
                Color(0xFF0060A6),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              investorsCount,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}