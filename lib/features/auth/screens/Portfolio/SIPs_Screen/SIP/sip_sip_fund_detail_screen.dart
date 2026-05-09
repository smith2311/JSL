import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/features/auth/screens/Portfolio/SIPs_Screen/SIP/pause_sip_screen.dart';
import '../../../../../../../constants/strings.dart';
import '../../../../../../../providers/sip_sip_detail_screen_provider.dart';
import '../../../../../../../widgets/cancel_sip_reason_bottomsheet.dart';
import '../../../../../../../widgets/resume_sip_confirmation.dart';
import '../../../../data/models/transaction_history.dart';

// Import the tab state provider
final portfolioTabStateProvider = StateProvider<Map<String, int>>((ref) => {
  'selectedTab': 0,
  'selectedSubTab': 0,
});

class SipDetailScreen extends ConsumerWidget {
  final String sxpId;
  final int currentTab;
  final int currentSubTab;

  const SipDetailScreen({
    super.key,
    required this.sxpId,
    this.currentTab = 1,
    this.currentSubTab = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sipDetailState = ref.watch(sipDetailProvider(sxpId));
    final transactionHistoryState = ref.watch(sipTransactionHistoryProvider(sxpId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Restore tab state before navigating back
            ref.read(portfolioTabStateProvider.notifier).state = {
              'selectedTab': currentTab,
              'selectedSubTab': currentSubTab,
            };
            context.go('/portfolio');
          },
        ),
        actions: [
          sipDetailState.when(
            data: (sipDetail) {
              if (!sipDetail.isCancelled) {
                return IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: () => _showOptionsDialog(context, sipDetail),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: const Color(0xFF0060A6),
            onRefresh: () async {
              ref.invalidate(sipDetailProvider(sxpId));
              ref.invalidate(sipTransactionHistoryProvider(sxpId));

              await Future.wait([
                ref.read(sipDetailProvider(sxpId).future),
                ref.read(sipTransactionHistoryProvider(sxpId).future),
              ]).catchError((_) {});
            },
            child: sipDetailState.when(
              data: (sipDetail) => _buildContent(context, ref, sipDetail, transactionHistoryState),
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
                        const Text('Error loading SIP details'),
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
                            ref.invalidate(sipDetailProvider(sxpId));
                            ref.invalidate(sipTransactionHistoryProvider(sxpId));
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
          if (sipDetailState.hasValue && sipDetailState.value!.isPaused)
          // Add your pause overlay here if needed
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: sipDetailState.when(
        data: (sipDetail) {
          if (!sipDetail.showButtons) return null;

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: sipDetail.isPaused
                            ? () => _showResumeSipConfirmation(context, ref, sipDetail)
                            : (sipDetail.canPause
                            ? () => _showPauseSipBottomSheet(context, ref, sipDetail)
                            : null),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: (!sipDetail.isPaused && !sipDetail.canPause)
                                ? Colors.grey.shade300
                                : const Color(0xFF0060A6),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          sipDetail.isPaused ? 'Resume SIP' : 'Pause SIP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: (!sipDetail.isPaused && !sipDetail.canPause)
                                ? Colors.grey.shade400
                                : const Color(0xFF0060A6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Step Up functionality coming soon'),
                              backgroundColor: Color(0xFF0060A6),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0060A6),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Step Up',
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
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, dynamic sipDetail) {
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
              _showCancelSipReasonBottomSheet(context, sipDetail);
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

  void _showCancelSipReasonBottomSheet(BuildContext context, dynamic sipDetail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CancelSipReasonBottomSheet(
        sxpId: sxpId,
        regNo: sipDetail.sipId,
        sxpType: sipDetail.sxpType,
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      WidgetRef ref,
      dynamic sipDetail,
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
                        'Next Installment Date: ',
                        style: TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                      ),
                      Text(
                        sipDetail.nextInstallmentDate,
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
                            sipDetail.fundName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildChip(sipDetail.fundCategory),
                              const SizedBox(width: 6),
                              _buildChip(sipDetail.fundSubCategory),
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
                          '₹${NumberFormat('#,##,##0').format(sipDetail.amount)}',
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
                        color: _getStatusColor(sipDetail.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sipDetail.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(sipDetail.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('Frequency', sipDetail.frequency),
                    _buildInfoItem('Current Amount', '₹${sipDetail.currentAmount.toStringAsFixed(0)}', isEnd: true),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                const SizedBox(height: 16),
                _buildDetailRow('SIP Date', sipDetail.sipDate),
                const SizedBox(height: 12),
                _buildDetailRow('Successful Installment', '${sipDetail.successfulInvestments}'),
                if (sipDetail.bankName.isNotEmpty && sipDetail.accountNo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Bank Linked to', '${sipDetail.bankName} -** ${sipDetail.accountNo.length >= 4 ? sipDetail.accountNo.substring(sipDetail.accountNo.length - 4) : sipDetail.accountNo}'),
                ],
                if (sipDetail.folioNo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Folio No.', sipDetail.folioNo),
                ],
                const SizedBox(height: 12),
                _buildDetailRow('SIP ID', sipDetail.sipId),
                const SizedBox(height: 12),
                _buildDetailRow('Registration Date', sipDetail.regDate),
                const SizedBox(height: 12),
                _buildDetailRow('SIP End Date', sipDetail.sipEndDate),
              ],
            ),
          ),
          if (sipDetail.isPaused && sipDetail.pauseDetails != null && sipDetail.pauseDetails.hasData) ...[
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
                    'Pause details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Start date',
                    sipDetail.pauseDetails!.startDate ?? '-',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'No. of installments',
                    sipDetail.pauseDetails!.noOfInstallments > 0
                        ? '${sipDetail.pauseDetails!.noOfInstallments}'
                        : '-',
                  ),
                ],
              ),
            ),
          ],
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
                            'No transactions found',
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
          SizedBox(height: sipDetail.showButtons ? 16 : 100),
        ],
      ),
    );
  }

  void _showPauseSipBottomSheet(BuildContext context, WidgetRef ref, dynamic sipDetail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => PauseSipScreen(
        sxpId: sxpId,
        sipDetail: sipDetail,
      ),
    );
  }

  void _showResumeSipConfirmation(BuildContext context, WidgetRef ref, dynamic sipDetail) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => ResumeSipConfirmation(
        sxpId: sxpId,
        sipDetail: sipDetail,
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
    if (statusLower == 'active' || statusLower == 'resumed') {
      return const Color(0xFFDCF4E7);
    } else if (statusLower == 'paused') {
      return const Color(0xFFFFF4E5);
    } else if (statusLower == 'inactive' || statusLower == 'failed' || statusLower == 'cancelled') {
      return const Color(0xFFFBD9D6);
    }
    return Colors.grey.shade200;
  }

  Color _getStatusTextColor(String status) {
    final statusLower = status.toLowerCase().trim();
    if (statusLower == 'active' || statusLower == 'resumed') {
      return const Color(0xFF00A651);
    } else if (statusLower == 'paused') {
      return const Color(0xFFFF9800);
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