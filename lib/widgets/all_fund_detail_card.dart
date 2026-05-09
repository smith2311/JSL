import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/strings.dart';
import '../core/utils/date_utils.dart';
import '../providers/fund_detail_providers.dart';
import '../providers/investment_returns_service_provider.dart';

class FundDetailCard extends ConsumerWidget {
  final int fundId;

  const FundDetailCard({super.key, required this.fundId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundInfoAsync = ref.watch(fundInfoProvider(fundId));
    final showAll = ref.watch(fundDetailViewAllProvider); // track view all state

    debugPrint("Fund ID clicked: $fundId");

    return fundInfoAsync.when(
      data: (data) {
        final other = data.otherDetails;
        final infoList = data.fundInfo;

        // Move display list logic here
        final displayInfoList =
        showAll || infoList.length <= 4 ? infoList : infoList.sublist(0, 4);

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Icon + Fund Name
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Image.asset(
                        AppStrings.iconFunds_png,
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      other.fundName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Fund Info rows
              ...displayInfoList.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _formatLabel(item.label),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatValue(item.value),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                          textAlign: TextAlign.right,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              // View All / View Less button
              if (infoList.length > 4)
                Center(
                  child: TextButton(
                    onPressed: () {
                      ref.read(fundDetailViewAllProvider.notifier).state =
                      !showAll;
                    },
                    child: Text(
                      showAll ? AppStrings.view_less : AppStrings.view_all_funds,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
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
          "Error loading fund info: $error",
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  String _formatLabel(String label) {
    return label;
  }

  String _formatValue(dynamic value) {
    if (value == null) return "-";
    if (value is String) {
      if (value.contains('-') || value.contains('/')) {
        return DateUtilsHelper.formatDate(value);
      }
      return value;
    }
    if (value is double || value is int) return value.toString();
    return value.toString();
  }
}