import 'package:flutter/material.dart';
import '../../constants/strings.dart';

class MutualFundCard extends StatelessWidget {
  final String logoPath;
  final String fundName;
  final String category;
  final String minInvestment;
  final String threeYearReturn;
  final double rating; // numeric rating

  const MutualFundCard({
    super.key,
    required this.logoPath,
    required this.fundName,
    required this.category,
    required this.minInvestment,
    required this.threeYearReturn,
    required this.rating,
  });

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return const Color(0xFF197D4B);
    if (rating >= 4.0) return const Color(0xFF12B76A);
    if (rating >= 3.6) return const Color(0xFFE1AF19);
    if (rating >= 3.0) return const Color(0xFFFFA800);
    return Colors.red; // default for other cases
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = threeYearReturn.startsWith("+");

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Logo + Fund Name + Category + Rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  logoPath,
                  width: 30,
                  height: 30,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fundName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Rating Badge
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(rating),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ⬇️ Added spacing between the top and bottom sections
          const SizedBox(height: 8),

          // 🔹 3Y Returns and Min Investment section with background
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      const TextSpan(
                        text: AppStrings.yr_returns,
                        style:
                        TextStyle(fontSize: 11, color: Color(0xFF888898)),
                      ),
                      TextSpan(
                        text: threeYearReturn,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: AppStrings.min_investment,
                        style:
                        TextStyle(fontSize: 11, color: Color(0xFF888898)),
                      ),
                      TextSpan(
                        text: minInvestment,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
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
    );
  }
}