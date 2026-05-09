import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../../providers/order_details_provider.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == AppStrings.complete || statusLower == AppStrings.completed) {
      return const Color(0xFFDCF4E7);
    } else if (statusLower == AppStrings.resp_failed) {
      return const Color(0xFFFBD9D6);
    } else if (statusLower == AppStrings.resp_pend) {
      return const Color(0xFFCADDFF);
    }
    return Colors.grey.shade200;
  }

  Color _getStatusTextColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == AppStrings.complete || statusLower == AppStrings.completed) {
      return const Color(0xFF00A651);
    } else if (statusLower == AppStrings.resp_failed) {
      return const Color(0xFFE53935);
    } else if (statusLower == AppStrings.resp_pend) {
      return const Color(0xFF1976D2);
    }
    return Colors.grey.shade700;
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('d MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderDetailsState = ref.watch(orderDetailsProvider(orderId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: orderDetailsState.when(
        data: (orderData) => _buildContent(context, orderData),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF0060A6)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading order details'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(orderDetailsProvider(orderId).notifier).fetchOrderDetails();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OrderDetailsResponse orderData) {
    final details = orderData.orderDetails;
    final history = orderData.orderHistory;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Fund Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      // Header with fund name
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                AppStrings.iconFunds_png,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                details.schemeName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Color(0xFF888898),
                            ),
                          ],
                        ),
                      ),

                      // Amount and Status
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888898),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${NumberFormat('#,##,##0.00').format(details.amount)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: _getStatusColor(details.status),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Text(
                                details.status,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusTextColor(details.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Investment Type and Date
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Investment Type',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888898),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  details.transactionType,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Date & Time',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888898),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  details.orderDateTime,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.only(right: 15, left: 15),
                        child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                      ),

                      // Units
                      _buildInfoRow('Units', details.units.toStringAsFixed(3)),

                      // NAV(Price)
                      _buildInfoRow('NAV(Price)', '₹${details.nav.toStringAsFixed(2)}'),

                      // NAV Date
                      _buildInfoRow('NAV Date', _formatDate(details.navDate)),

                      // Folio No.
                      _buildInfoRow('Folio No.', details.folioNo),

                      const Padding(
                        padding: EdgeInsets.only(right: 15, left: 15),
                        child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                      ),

                      // Transaction ID
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Transaction ID',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888898),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                details.transactionId,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Transaction Status
                if (history.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTimeline(history),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),

        // Fixed Bottom Button
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
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Handle invest more action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Invest More',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF888898),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<OrderHistoryItem> history) {
    return Column(
      children: List.generate(history.length, (index) {
        final item = history[index];
        final isLast = index == history.length - 1;
        final state = item.state;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: state == 'successful'
                          ? const Color(0xFF0060A6)
                          : state == 'failed'
                          ? const Color(0xFFE53935)
                          : const Color(0xFFE3F3FE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      state == 'successful'
                          ? Icons.check
                          : state == 'failed'
                          ? Icons.close
                          : Icons.circle,
                      color: state == 'pending' ? const Color(0xFF0060A6) : Colors.white,
                      size: state == 'pending' ? 10 : 18,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: const Color(0xFF0060A6),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : 20,
                    top: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.msg,
                        style: TextStyle(
                          fontSize: 13,
                          color: state == 'failed'
                              ? const Color(0xFFE53935)
                              : const Color(0xFF888898),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888898),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}