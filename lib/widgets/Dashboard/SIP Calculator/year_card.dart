import 'package:flutter/material.dart';

import '../../../features/auth/data/models/yearly_data.dart';

class YearCard extends StatelessWidget {
  final YearlyData data;

  const YearCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Investments',
                  '₹${data.investment}',
                  null,
                  TextAlign.left,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Total Value',
                  '₹${data.totalValue}',
                  null,
                  TextAlign.center,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Returns',
                  '₹${data.returns}',
                  const Color(0xFF00A651),
                  TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Year',
                  '${data.year}',
                  null,
                  TextAlign.left,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Inflation-Adjusted Value',
                  '₹${data.inflationAdjusted}',
                  null,
                  TextAlign.center,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Monthly SIP',
                  '₹${data.monthlySip}',
                  null,
                  TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      String label,
      String value,
      Color? valueColor,
      TextAlign alignment,
      ) {
    return Column(
      crossAxisAlignment: alignment == TextAlign.left
          ? CrossAxisAlignment.start
          : alignment == TextAlign.right
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF999999),
          ),
          textAlign: alignment,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1A1A),
          ),
          textAlign: alignment,
        ),
      ],
    );
  }
}