import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/widgets/action_btn_bottom_dialog.dart';
import '../../../../../../providers/portf_fund_detail_redeem_provider.dart';
import '../../../../../constants/messages.dart';
import '../../../data/models/portfolio_fund_detail.dart';

class PortfolioFundDetailScreen extends ConsumerWidget {
  final int fundId;
  final String folioNo;
  final String clientName;

  const PortfolioFundDetailScreen({
    super.key,
    required this.fundId,
    required this.folioNo,
    required this.clientName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundDetailState = ref.watch(portfolioFundDetailProvider(
      FundDetailParams(fundId: fundId, folioNo: folioNo),
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: fundDetailState.when(
        data: (fundDetail) => _buildContent(context, fundDetail),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                ErrorMessages.errorLoadingFundDetails,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PortfolioFundDetailModel fundDetail) {
    final isPositiveReturn = fundDetail.returns >= 0;
    final isPositiveOneDayReturn = fundDetail.oneDayReturn >= 0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fund Header Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fund name with logo and arrow
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  AppStrings.iconFunds_png,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fundDetail.fundName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Padding(
                                padding: EdgeInsets.only(top: 45),
                                child: Icon(Icons.arrow_forward_ios, size: 22, color: Color(0xFF888898)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Category, Sub-category, and Rating
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F3FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  fundDetail.fundCategory,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0060A6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F3FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  fundDetail.fundSubCategory,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0060A6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F3FE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFF0060A6), size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      fundDetail.rating.toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF0060A6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        AppStrings.returns,
                        style: TextStyle(fontSize: 13, color: Color(0xFF888898)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${isPositiveReturn ? '+' : ''}₹${NumberFormat('#,##,##0').format(fundDetail.returns)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: isPositiveReturn ? const Color(0xFF00A651) : const Color(0xFFE53935),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isPositiveReturn ? '+' : ''}${fundDetail.returnPercentage.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isPositiveReturn ? const Color(0xFF00A651) : const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  AppStrings.current,
                                  style: TextStyle(fontSize: 13, color: Color(0xFF888898)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${NumberFormat('#,##,##0.00').format(fundDetail.current)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  AppStrings.inv,
                                  style: TextStyle(fontSize: 13, color: Color(0xFF888898)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${NumberFormat('#,##,##0.00').format(fundDetail.invested)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        AppStrings.one_d_ret,
                        '₹${NumberFormat('#,##,##0').format(fundDetail.oneDayReturn)} ${isPositiveOneDayReturn ? '+' : ''}${fundDetail.oneDayReturnPercentage.toStringAsFixed(1)}%',
                        valueColor: isPositiveOneDayReturn ? const Color(0xFF00A651) : const Color(0xFFE53935),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppStrings.xirr, '${fundDetail.xirr.toStringAsFixed(1)}%', valueColor: const Color(0xFF00A651)),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppStrings.bal_unit, fundDetail.balanceUnits.toStringAsFixed(3)),
                      const SizedBox(height: 12),
                      _buildDetailRow(AppStrings.fol_no, fundDetail.folioNo),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Other Details Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.oth_det,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildDetailRow(AppStrings.hol_pat, fundDetail.holdingPattern.isEmpty ? '--' : fundDetail.holdingPattern),
                      const SizedBox(height: 16),
                      _buildDetailRow(AppStrings.joint_hol, fundDetail.jointHolder.isEmpty ? '--' : fundDetail.jointHolder),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // Bottom Buttons
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (context) => ActionBottomSheet(
                          fundId: fundId,
                          folioNo: folioNo,
                          clientId: fundDetail.clientId.toString(),
                          fundName: fundDetail.fundName,
                          availableUnits: fundDetail.balanceUnits,
                          availableAmount: fundDetail.current,
                          clientName:clientName,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0060A6), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      AppStrings.action,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0060A6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.pushNamed(
                        'onetime-startsip',
                        pathParameters: {'fundId': fundId.toString()},
                        extra: {
                          'initialTab': 0,
                          'client_id': fundDetail.clientId.toString(),
                          'fundName': fundDetail.fundName, // Pass the fund name
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0060A6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      AppStrings.inv_more,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isEnd = false}) {
    return Column(
      crossAxisAlignment: isEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF888898)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF888898)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}