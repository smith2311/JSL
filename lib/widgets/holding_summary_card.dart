// lib/widgets/holding_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

import '../features/funds/data/models/fund_details_models.dart';
import '../providers/fund_detail_providers.dart';
import '../providers/investment_returns_service_provider.dart';

class HoldingSummaryCard extends ConsumerStatefulWidget {
  final int fundId;
  const HoldingSummaryCard({super.key, required this.fundId});

  @override
  ConsumerState<HoldingSummaryCard> createState() =>
      _HoldingSummaryCardState();
}

class _HoldingSummaryCardState extends ConsumerState<HoldingSummaryCard> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final holdingAsync = ref.watch(holdingSummaryProvider(widget.fundId));

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Custom Tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildCustomTab(AppStrings.hs_tab1, 0),
                  _buildCustomTab(AppStrings.hs_tab2, 1),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Async Data
            holdingAsync.when(
              data: (data) {
                if (data.sectorWise.isEmpty && data.companyWise.isEmpty) {
                  return const Center(child: Text("No data"));
                }

                final bool isSectorTab = _selectedTabIndex == 0;

                return isSectorTab
                    ? _buildList<SectorHolding>(data.sectorWise)
                    : _buildList<CompanyHolding>(data.companyWise);
              },
              loading: () =>
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF0060A6)),
              ),
              error: (err, _) =>
                  Center(
                    child: Text(
                      "Error: $err",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTab(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0060A6) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList<T>(List<T> items) {
    final isSectorTab = _selectedTabIndex == 0;
    final showAll = isSectorTab
        ? ref.watch(sectorViewAllProvider)
        : ref.watch(companyViewAllProvider);

    if (items.isEmpty) return const Center(child: Text("No data"));

    // Show only first 3 if View All not clicked
    final displayItems = showAll || items.length <= 3 ? items : items.sublist(
        0, 3);

    return Column(
      children: [
        ...displayItems.map((item) {
          late String name;
          late double percentage;

          if (item is SectorHolding) {
            name = item.name;
            percentage = item.percentage;
          } else if (item is CompanyHolding) {
            name = item.name;
            percentage = item.percentage;
          } else {
            name = "Unknown";
            percentage = 0.0;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${percentage.toStringAsFixed(2)}%",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // Only show View All if not yet expanded
        if (!showAll && items.length > 3)
          TextButton(
            onPressed: () {
              if (isSectorTab) {
                ref
                    .read(sectorViewAllProvider.notifier)
                    .state = true;
              } else {
                ref
                    .read(companyViewAllProvider.notifier)
                    .state = true;
              }
            },
            child: const Text(
              AppStrings.view_all_funds,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}