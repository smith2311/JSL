import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class OrderCard extends StatelessWidget {
  final String? fundName;
  final String? clientName;
  final String? orderStatus;
  final double? investedAmount;
  final String? investmentDate;
  final String? bseId;
  final String? logoPath;
  final bool isLoading;

  const OrderCard({
    super.key,
    this.fundName,
    this.clientName,
    this.orderStatus,
    this.investedAmount,
    this.investmentDate,
    this.bseId,
    this.logoPath,
    this.isLoading = false,
  });

  Color _getStatusColor() {
    final status = orderStatus?.toLowerCase() ?? '';

    // Completed/Success states
    if (status == 'completed' || status == 'success' || status == 'alloted') {
      return const Color(0xFFDCF4E7);
    }
    // Pending states
    else if (status == 'pending' ||
        status == 'payment pending' ||
        status == 'in process' ||
        status == 'received') {
      return const Color(0xFFCADBFF);
    }
    // Failed/Cancelled/Expired states
    else if (status == 'failed' ||
        status == 'cancelled' ||
        status == 'expired' ||
        status == 'rejected') {
      return const Color(0xFFFBD9D6);
    }

    return Colors.grey.shade200;
  }

  Color _getStatusTextColor() {
    final status = orderStatus?.toLowerCase() ?? '';

    // Completed/Success states
    if (status == 'completed' || status == 'success' || status == 'alloted') {
      return const Color(0xFF00A651);
    }
    // Pending states
    else if (status == 'pending' ||
        status == 'payment pending' ||
        status == 'in process' ||
        status == 'received') {
      return const Color(0xFF1976D2);
    }
    // Failed/Cancelled/Expired states
    else if (status == 'failed' ||
        status == 'cancelled' ||
        status == 'expired' ||
        status == 'rejected') {
      return const Color(0xFFE53935);
    }

    return Colors.grey.shade700;
  }

  String _formatStatus() {
    if (orderStatus == null) return '';

    // Capitalize first letter of each word
    return orderStatus!.split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      // Shimmer placeholder
      return Card(
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 35, height: 35, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Container(height: 16, color: Colors.white)),
                    Container(width: 60, height: 16, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 50, height: 12, color: Colors.white),
                    Container(width: 50, height: 12, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 100, height: 15, color: Colors.white),
                    Container(width: 60, height: 15, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 80, height: 12, color: Colors.white),
                      Container(width: 60, height: 12, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal card
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 4, right: 4, bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: logo + fund name + status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 55,
                  height: 35,
                  child: logoPath != null
                      ? Image.asset(logoPath!, fit: BoxFit.contain)
                      : Container(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      fundName ?? '',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    _formatStatus(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusTextColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Name + Amount titles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                      AppStrings.orders_name_lbl,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                      AppStrings.orders_amt_lbl,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                  ),
                ),
              ],
            ),

            // Client name + invested amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                      clientName ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500
                      )
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    investedAmount != null
                        ? "₹ ${investedAmount!.toStringAsFixed(0)}"
                        : '',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom row box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F3FE),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${AppStrings.orders_date_lbl}: ",
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888898)
                          ),
                        ),
                        TextSpan(
                          text: investmentDate ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black
                          ),
                        ),
                      ],
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${AppStrings.orders_bseid_lbl}: ",
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888898)
                          ),
                        ),
                        TextSpan(
                          text: bseId ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}