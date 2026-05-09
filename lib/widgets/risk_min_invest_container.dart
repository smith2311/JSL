import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/widgets/risk_bar.dart';
import '../providers/fund_detail_providers.dart';

class FundRiskMinRow extends ConsumerWidget {
  final int fundId;

  const FundRiskMinRow({super.key, required this.fundId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundInfoAsync = ref.watch(fundInfoProvider(fundId));

    return fundInfoAsync.when(
      data: (data) {
        final other = data.otherDetails;
        final riskLevel = other.riskLevel;
        final minInvestment = other.minInvestment;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Risk Bar on left with FIXED width
              SizedBox(
                width: 223,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        riskLevel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // ✅ black bold text
                        ),
                      ),

                      const SizedBox(height: 8), // ✅ padding from top

                      RiskBarWidget(
                        riskLevel: riskLevel,
                        width: 120,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Min Investment Container on right with FIXED width
              SizedBox(
                width: 140,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "₹$minInvestment",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        AppStrings.min_invest_graph,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text(
          "Error loading data: $error",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}