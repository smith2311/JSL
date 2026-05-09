import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../../constants/strings.dart';
import '../../../../../../../providers/swp_detail_screen_provider.dart';
import '../../../../../../../widgets/cancel_sip_reason_bottomsheet.dart';
import '../../../../data/models/swp_detail.dart';
import '../../../../data/models/transaction_history.dart';

final portfolioTabStateProvider = StateProvider<Map<String, int>>((ref) => {
  'selectedTab': 0,
  'selectedSubTab': 0,
});

class SwpDetailScreen extends ConsumerWidget {
  final String sxpId;
  final int currentTab;
  final int currentSubTab;

  const SwpDetailScreen({
    super.key,
    required this.sxpId,
    this.currentTab = 1,
    this.currentSubTab = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swpDetailState = ref.watch(swpDetailProvider(sxpId));
    final transactionHistoryState = ref.watch(swpTransactionHistoryProvider(sxpId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Restore tab state
            ref.read(portfolioTabStateProvider.notifier).state = {
              'selectedTab': currentTab,
              'selectedSubTab': currentSubTab,
            };
            context.go('/portfolio');
          },
        ),

        actions: [
          swpDetailState.when(
            data: (swpDetail) {
              // Only show menu if status is active
              final statusLower = swpDetail.status.toLowerCase().trim();
              if (statusLower == 'active') {
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () => _showOptionsDialog(context, swpDetail as SwpDetailModel),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0060A6),
        onRefresh: () async {
          // Refresh both APIs
          ref.invalidate(swpDetailProvider(sxpId));
          ref.invalidate(swpTransactionHistoryProvider(sxpId));

          // Wait for providers to complete refresh
          await Future.wait([
            ref.read(swpDetailProvider(sxpId).future),
            ref.read(swpTransactionHistoryProvider(sxpId).future),
          ]).catchError((_) {
            // Ignore errors during refresh, they'll be shown in the UI
          });
        },
        child: swpDetailState.when(
          data: (swpDetail) => _buildContent(context, ref, swpDetail as SwpDetailModel, transactionHistoryState as AsyncValue<List<TransactionHistoryItem>>),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0060A6)),
          ),
          error: (error, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Error loading SWP details'),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(swpDetailProvider(sxpId));
                        ref.invalidate(swpTransactionHistoryProvider(sxpId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0060A6),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, SwpDetailModel swpDetail) {
    showMenu(
      context: context,
      color: Colors.white,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        kToolbarHeight,
        0,
        0,
      ),
      items: [
        PopupMenuItem(
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              _showCancelSipReasonBottomSheet(context, swpDetail);
            });
          },
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
    );
  }

  void _showCancelSipReasonBottomSheet(BuildContext context, SwpDetailModel swpDetail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelSipReasonBottomSheet(
        sxpId: sxpId,
        regNo: swpDetail.swpId,
        sxpType: swpDetail.sxpType,
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      SwpDetailModel swpDetail,
      AsyncValue<List<TransactionHistoryItem>> transactionHistoryState,
      ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6EAF8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Next Withdrawal Date: ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                      ),
                      Text(
                        swpDetail.nextWithdrawalDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            swpDetail.fundName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildChip(swpDetail.fundCategory),
                              const SizedBox(width: 6),
                              _buildChip(swpDetail.fundSubCategory),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 22, color: Color(0xFF888898)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Amount',
                          style: TextStyle(fontSize: 13, color: Color(0xFF888898)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,##0').format(swpDetail.amount)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getStatusColor(swpDetail.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        swpDetail.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(swpDetail.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Frequency', swpDetail.frequency),
                    _buildInfoItem('Current Amount', '₹${swpDetail.currentAmount.toStringAsFixed(0)}', isEnd: true),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 16),
                _buildDetailRow('SWP Date', swpDetail.swpDate),
                const SizedBox(height: 12),
                _buildDetailRow('Successful Withdrawals', '${swpDetail.successfulWithdrawals}'),
                const SizedBox(height: 12),
                _buildDetailRow('Bank Linked to', '${swpDetail.bankName} -** ${swpDetail.accountNo.substring(swpDetail.accountNo.length - 4)}'),
                const SizedBox(height: 12),
                _buildDetailRow('Folio No.', swpDetail.folioNo),
                const SizedBox(height: 12),
                _buildDetailRow('SWP ID', swpDetail.swpId),
                const SizedBox(height: 12),
                _buildDetailRow('Registration Date', swpDetail.regDate),
                const SizedBox(height: 12),
                _buildDetailRow('End Date', swpDetail.endDate),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                transactionHistoryState.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No transactions yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: transactions
                          .map((tx) => _buildTransactionItem(tx))
                          .toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(color: Color(0xFF0060A6)),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading transactions: ${err.toString()}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F3FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF0060A6),
          fontWeight: FontWeight.w600,
        ),
      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF888898)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionHistoryItem tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getTransactionStatusColor(tx.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tx.isUnits
                ? '${tx.amount.toStringAsFixed(3)} units'
                : '₹${NumberFormat('#,##,##0.00').format(tx.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _getTransactionStatusColor(tx.status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase().trim();
    if (statusLower == 'active') {
      return const Color(0xFFDCF4E7);
    } else if (statusLower == 'inactive' || statusLower == 'failed' || statusLower == 'cancelled') {
      return const Color(0xFFFBD9D6);
    }
    return Colors.grey.shade200;
  }

  Color _getStatusTextColor(String status) {
    final statusLower = status.toLowerCase().trim();
    if (statusLower == 'active') {
      return const Color(0xFF00A651);
    } else if (statusLower == 'inactive' || statusLower == 'failed' || statusLower == 'cancelled') {
      return const Color(0xFFE53935);
    }
    return Colors.grey.shade700;
  }

  Color _getTransactionStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'success' || statusLower == 'successful') {
      return const Color(0xFF00A651);
    } else if (statusLower == 'failed') {
      return const Color(0xFFE53935);
    }
    return Colors.black;
  }
}