import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../providers/investment_returns_service_provider.dart';
import '../../../../../providers/selected_fund_provider.dart';
import '../../../../../widgets/all_fund_appbar.dart';
import '../../../../../widgets/all_fund_detail_card.dart';
import '../../../../../widgets/fund_info_graphcard.dart';
import '../../../../../widgets/risk_min_invest_container.dart';
import '../../../../../widgets/category_returns.dart';
import '../../../../../widgets/holding_summary_card.dart';
import '../../../../../widgets/investment_returns_card.dart';
import '../../../../../constants/strings.dart';

class AllFundDetailScreen extends ConsumerStatefulWidget {
  final int fundId;
  final String fundName;
  final Map<String, dynamic>? extraData;

  const AllFundDetailScreen({
    super.key,
    required this.fundId,
    required this.fundName,
    this.extraData,
  });

  @override
  ConsumerState<AllFundDetailScreen> createState() =>
      _AllFundDetailScreenState();
}

class _AllFundDetailScreenState extends ConsumerState<AllFundDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedFundProvider.notifier).state = {
        'fundId': widget.fundId,
        'fundName': widget.fundName,
      };
    });
  }

  void _handleBackNavigation() {
    final previousRoute = widget.extraData?['previousRoute'] as String?;

    if (previousRoute != null) {
      context.go(previousRoute);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/discover');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fundData = ref.watch(selectedFundProvider);
    final displayFundName = fundData['fundName'] ?? 'Fund ${widget.fundId}';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: FundDetailAppBar(
        fundId: widget.fundId,
        fundName: displayFundName,
        onBack: _handleBackNavigation,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FundGraphInfoScreen(fundId: widget.fundId),
                  const SizedBox(height: 16),
                  FundRiskMinRow(fundId: widget.fundId),
                  _sectionTitle(AppStrings.categ_returns),
                  CategoryReturnsWidget(fundId: widget.fundId),
                  _sectionTitle(AppStrings.hold_sum),
                  HoldingSummaryCard(fundId: widget.fundId),
                  _sectionTitle(AppStrings.inv_return),
                  const InvestmentReturnsCard(),
                  _sectionTitle(AppStrings.fund_info),
                  FundDetailCard(fundId: widget.fundId),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    final selectedTab = ref.watch(selectedTabProvider);
    final performanceAmount = ref.watch(performanceAmountProvider);

    final bool isEnabled = selectedTab == 0 ||
        (selectedTab == 1 &&
            performanceAmount >= 100 &&
            performanceAmount <= 500000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isEnabled
                    ? () {
                        context.pushNamed(
                          'onetime-startsip',
                          pathParameters: {'fundId': widget.fundId.toString()},
                          extra: {'initialTab': 0},
                        );
                      }
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(
                      color: isEnabled
                          ? const Color(0xFF0060A6)
                          : Colors.grey.shade300,
                      width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  AppStrings.onetime_btn,
                  style: TextStyle(
                    color: isEnabled
                        ? const Color(0xFF0060A6)
                        : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: isEnabled
                    ? () {
                        context.pushNamed(
                          'onetime-startsip',
                          pathParameters: {'fundId': widget.fundId.toString()},
                          extra: {'initialTab': 1},
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEnabled
                      ? const Color(0xFF0060A6)
                      : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text(
                  AppStrings.start_sip_btn,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 16, top: 24),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      );
}
