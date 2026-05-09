import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../../app/router.dart';
import '../../../../../../../constants/strings.dart';
import '../../../../../../../providers/stp_detail_screen_provider.dart';
import '../../../../../../../widgets/cancel_sip_reason_bottomsheet.dart';
import '../../../../data/models/stp_detail.dart';
import '../../../../data/models/transaction_history.dart';

class StpDetailScreen extends ConsumerWidget {
  final String sxpId;
  final int currentTab;
  final int currentSubTab;

  const StpDetailScreen({
    super.key,
    required this.sxpId,
    this.currentTab = 1,
    this.currentSubTab = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('[DEBUG] StpDetailScreen - build() called with sxpId: $sxpId');

    final stpDetailState = ref.watch(stpDetailProvider(sxpId));
    final transactionHistoryState = ref.watch(stpTransactionHistoryProvider(sxpId));

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
          stpDetailState.when(
            data: (stpDetail) {
              final statusLower = stpDetail.status.toLowerCase().trim();
              print('[DEBUG] STP status: $statusLower');
              if (statusLower == 'active') {
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () {
                    print('[DEBUG] More options button pressed');
                    _showOptionsDialog(context, stpDetail);
                  },
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
          print('[DEBUG] Pull to refresh triggered');
          ref.invalidate(stpDetailProvider(sxpId));
          ref.invalidate(stpTransactionHistoryProvider(sxpId));

          await Future.wait([
            ref.read(stpDetailProvider(sxpId).future),
            ref.read(stpTransactionHistoryProvider(sxpId).future),
          ]).catchError((_) {});
        },
        child: stpDetailState.when(
          data: (stpDetail) => _buildContent(context, ref, stpDetail, transactionHistoryState as AsyncValue<List<TransactionHistoryItem>>),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF0060A6)),
          ),
          error: (error, stack) {
            print('[DEBUG] Error loading STP details: $error');
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Error loading STP details'),
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
                          print('[DEBUG] Retry button pressed');
                          ref.invalidate(stpDetailProvider(sxpId));
                          ref.invalidate(stpTransactionHistoryProvider(sxpId));
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
            );
          },
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, StpDetailModel stpDetail) {
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
              print('[DEBUG] Cancel option selected');
              _showCancelSipReasonBottomSheet(context, stpDetail);
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

  void _showCancelSipReasonBottomSheet(BuildContext context, StpDetailModel stpDetail) {
    print('[DEBUG] Showing cancel reason bottom sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelSipReasonBottomSheet(
        sxpId: sxpId,
        regNo: stpDetail.stpId,
        sxpType: stpDetail.sxpType,
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      StpDetailModel stpDetail,
      AsyncValue<List<TransactionHistoryItem>> transactionHistoryState,
      ) {
    print('[DEBUG] Building STP content');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combined Fund From and Fund To Card
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Fund From
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
                          const Text(
                            'Fund From',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888898),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stpDetail.fundNameFrom,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Arrow with divider
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      // Arrow circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Colors.black,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right divider only
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EB),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fund To
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
                          const Text(
                            'Fund To',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888898),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            stpDetail.fundNameTo,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Details Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(8,8,8,8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Next Transfer Date
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6EAF8),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Next Transfer Date: ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                      ),
                      Text(
                        stpDetail.nextInstallmentDate,
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
                          '₹${NumberFormat('#,##,##0').format(stpDetail.amount)}',
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
                        color: _getStatusColor(stpDetail.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        stpDetail.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(stpDetail.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Frequency', stpDetail.frequency),
                    _buildInfoItem('Current Amount', '₹${stpDetail.currentAmount.toStringAsFixed(0)}', isEnd: true),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 16),
                _buildDetailRow('No. of Installments', '${stpDetail.noOfInstallments}'),
                const SizedBox(height: 12),
                _buildDetailRow('Successful Transfers', '${stpDetail.successfulInvestments}'),
                const SizedBox(height: 12),
                _buildDetailRow('Folio No.', stpDetail.folioNo),
                const SizedBox(height: 12),
                _buildDetailRow('STP ID', stpDetail.stpId),
                const SizedBox(height: 12),
                _buildDetailRow('Registration Date', stpDetail.registrationDate),
                const SizedBox(height: 12),
                _buildDetailRow('Start Date', stpDetail.startDate),
                const SizedBox(height: 12),
                _buildDetailRow('End Date', stpDetail.endDate),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Transaction History Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Transaction History Items (No container wrapper)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: transactionHistoryState.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
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
              loading: () => Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF0060A6)),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Error loading transactions: ${err.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
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
        color: Colors.white,
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
    if (statusLower == 'success' || statusLower == 'successful' || statusLower == 'queued_for_rta') {
      return const Color(0xFF00A651);
    } else if (statusLower == 'failed') {
      return const Color(0xFFE53935);
    }
    return Colors.black;
  }
}