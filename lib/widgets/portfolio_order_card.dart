import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../features/auth/data/models/portfolio_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFFDCF4E7);
      case 'failed' || 'cancelled':
        return const Color(0xFFFBD9D6);
      case 'pending' || 'payment_pending':
        return const Color(0xFFCADDFF);
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF00A651);
      case 'failed' || 'cancelled':
        return const Color(0xFFE53935);
      case 'pending' || 'payment_pending':
        return const Color(0xFF1976D2);
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(order.investmentDate);
    final statusColor = _getStatusColor(order.orderStatus);
    final statusTextColor = _getStatusTextColor(order.orderStatus);

    return InkWell(
      onTap: () {
        context.push('/order-details/${order.orderId}');
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        child: Column(
          children: [
            // Row 1: Logo + Fund name + Status + Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Image.asset(AppStrings.iconFunds_png, width: 35, height: 35),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.fundName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      order.orderStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Color(0xFF888898)),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F3F5)),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Column 1: Name - Wrapped in Flexible to allow text wrapping
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.name,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.clientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Column 2: Type
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          AppStrings.type,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.orderType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Column 3: Amount
                  const SizedBox(width: 8),

                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          AppStrings.orders_amt_lbl,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.investedAmount}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Row 4: BSE ID and Invested Date with background color
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    color: Color(0xFFE3F3FE),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    )),
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                              text: 'BSE ID: ',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF888898))),
                          TextSpan(
                              text: order.bseId,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black)),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                              text: 'Date: ',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF888898))),
                          TextSpan(
                              text: date,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}