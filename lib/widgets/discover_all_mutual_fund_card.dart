import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class DiscoverFundCard extends StatelessWidget {
  final String fundName;
  final String productTitle;
  final double threeYearReturnValue;
  final String logoPath;
  final bool? isSaved;
  final VoidCallback? onSave;
  final VoidCallback? onTap;
  final double? minimumInvestment;
  final double? rating;

  const DiscoverFundCard({
    super.key,
    required this.fundName,
    required this.productTitle,
    required this.threeYearReturnValue,
    required this.logoPath,
    this.isSaved = false,
    this.onSave,
    this.onTap,
    this.minimumInvestment,
    this.rating,
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
    final formattedReturn =
        "${isPositive ? '+' : '-'}${threeYearReturnValue.abs().toStringAsFixed(1)}%";
    final formattedMinInvestment = minimumInvestment != null
        ? "₹${minimumInvestment!.toStringAsFixed(0)}"
        : "-";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Logo + Fund Name + Product Title + Save + Rating
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Image.asset(
                      logoPath,
                      width: 32,
                      height: 32,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.account_balance,
                              color: Colors.grey.shade400, size: 32),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fundName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          productTitle,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF666666)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (rating != null)
                    Container(
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
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  if (onSave != null)
                    GestureDetector(
                      onTap: onSave,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          AppStrings.save,
                          width: 20,
                          height: 20,
                          color: isSaved == true
                              ? const Color(0xFF0060A6)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Bottom row: 3Y Return + Min Investment
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 8, left: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    // 3-year return
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                          children: [
                            const TextSpan(
                                text: AppStrings.yr_returns_MF,
                                style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(
                                text: formattedReturn,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPositive ? Colors.green : Colors.red)),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Minimum investment
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13, color: Colors.black),
                          children: [
                            const TextSpan(
                                text: AppStrings.mf_min_investment,
                                style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(
                                text: formattedMinInvestment,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
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