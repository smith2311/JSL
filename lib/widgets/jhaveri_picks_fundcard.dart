import 'package:flutter/material.dart';
import '../../constants/strings.dart';

class JhaveriFundCard extends StatelessWidget {
  final String logoPath;
  final String fundName;
  final String category;
  final String minInvestment;
  final String returns;
  final VoidCallback? onTap;

  const JhaveriFundCard({
    super.key,
    required this.logoPath,
    required this.fundName,
    required this.category,
    required this.minInvestment,
    required this.returns,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (() {
      final numericValue = double.tryParse(
          returns.replaceAll('%', '').replaceAll('₹', ''));
      if (numericValue == null) return false;
      return numericValue >= 0;
    })();

    return GestureDetector(
      onTap: () {
        debugPrint("🔥 [JhaveriFundCard] Card tapped: $fundName");
        onTap?.call();
      },
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          // Add visual feedback for tapping
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  logoPath,
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fundName.isNotEmpty ? fundName : "Unknown Fund",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        category.isNotEmpty ? category : "N/A",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F3FE),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888898),
                          ),
                        ),
                        TextSpan(
                          text: returns.isNotEmpty ? returns : "N/A",
                          style: TextStyle(
                            fontSize: 12,
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF888898),
                          ),
                        ),
                        TextSpan(
                          text: minInvestment.isNotEmpty ? minInvestment : "N/A",
                          style: const TextStyle(
                            fontSize: 12,
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
      ),
    );
  }
}