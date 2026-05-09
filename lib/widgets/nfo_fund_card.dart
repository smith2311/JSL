import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class NfoFundCard extends StatelessWidget {
  final int? fundId;
  final String fundName;
  final String productTitle;
  final double threeYearReturnValue;
  final String logoPath;
  final double? minimumInvestment;
  final double? rating;
  final int? totalCustomers;
  final VoidCallback ? onTap;

  const NfoFundCard({
    super.key,
    required this.fundName,
    required this.productTitle,
    required this.threeYearReturnValue,
    required this.logoPath,
    this.fundId,
    this.minimumInvestment,
    this.rating,
    this.totalCustomers,
    this.onTap,
  });

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return const Color(0xFF197D4B);
    if (rating >= 4.0) return const Color(0xFF12B76A);
    if (rating >= 3.6) return const Color(0xFFE1AF19);
    if (rating >= 3.0) return const Color(0xFFFFA800);
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = threeYearReturnValue >= 0;
    final formattedReturn = isPositive
        ? "+${threeYearReturnValue.toStringAsFixed(2)}%"
        : "${threeYearReturnValue.toStringAsFixed(2)}%";
    final formattedMinInvestment = minimumInvestment != null
        ? "₹${minimumInvestment!.toStringAsFixed(0)}"
        : "-";

    return GestureDetector(
      onTap: fundId != null
          ? () {
        context.go('/fund-details/$fundId', extra: {
          'fundName': fundName,
          'category': productTitle,
          'minInvestment': formattedMinInvestment,
          'returns': formattedReturn,
          'rating': rating?.toStringAsFixed(1) ?? 'N/A',
          'investorsCount': totalCustomers ?? 'N/A',
        });
      }
          : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: Image.asset(
                logoPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 32, height: 32, color: Colors.red),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fundName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    productTitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rating != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRatingColor(rating!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          rating!.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                Text(
                  formattedReturn,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green.shade600 : Colors.red,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      AppStrings.yr_returns_MF,
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedMinInvestment,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}