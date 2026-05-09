import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final dynamic transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final status = transaction.status.toLowerCase();

    // Status color logic
    Color statusColor;
    Color statusTextColor;

    if (status == 'completed') {
      statusColor = const Color(0xFFD4F4DD);
      statusTextColor = const Color(0xFF0F5132);
    } else if (status == 'failed' || status == 'fail') {
      statusColor = const Color(0xFFF8D7DA);
      statusTextColor = const Color(0xFF842029);
    } else {
      statusColor = const Color(0xFFFFF3CD);
      statusTextColor = const Color(0xFF856404);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(statusColor, statusTextColor),
          Padding(
            padding: const EdgeInsets.only(right: 10,left: 10),
            child: const Divider(
              color: Color(0xFFE0E0E0),
              height: 0,
              thickness: 1,
            ),
          ),
          _buildDetails(),
        ],
      ),
    );
  }

  Widget _buildHeader(Color statusColor, Color statusTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      decoration: const BoxDecoration(
        color: Colors.white, // ✅ White background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                transaction.date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.transactionType.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              transaction.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  label: 'NAV',
                  value: transaction.price.toStringAsFixed(0),
                  alignment: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  label: 'Unit',
                  value: transaction.units.toStringAsFixed(4),
                  alignment: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  label: 'Amount',
                  value: '₹${transaction.amount.toStringAsFixed(0)}',
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required CrossAxisAlignment alignment,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
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
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8,8,8,8),
      decoration: const BoxDecoration(
        color: Color(0xFFE3F3FE),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Stamp: ${transaction.stampDuty.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
          Text(
            'STT: ${transaction.stt.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}