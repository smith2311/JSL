import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/strings.dart';
import '../providers/mf_provider.dart';
import '../providers/select_sub_categories_provider.dart';
import '../providers/sub_category_provider.dart' hide selectedSubCategoriesProvider;
import 'nfo_fund_card.dart';

class DiscoverFundsSection extends ConsumerWidget {
  final String title;
  final VoidCallback? onViewAllTap;
  final int maxPageSize;

  const DiscoverFundsSection({
    super.key,
    required this.title,
    this.onViewAllTap,
    this.maxPageSize = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundsState = ref.watch(fundsProvider);
    final selectedIds = ref.watch(selectedSubCategoriesProvider);
    final subCategoriesAsync = ref.watch(subCategoriesProvider);

    // Only show first N funds
    final fundsToShow = fundsState.funds.take(maxPageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + View All
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (onViewAllTap != null)
                GestureDetector(
                  onTap: onViewAllTap,
                  child: const Text(
                    AppStrings.view_all_funds,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Chips
        subCategoriesAsync.when(
          data: (subCategories) {
            final chips = [
              {'id': null, 'name': 'All'},
              ...subCategories.where((sc) => sc['name'].toLowerCase() != 'all'),
            ];

            return SizedBox(
              height: 45,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final chip = chips[index];
                  final id = chip['id'] as int?;
                  final name = chip['name'] as String;
                  final selected = id == null ? selectedIds.isEmpty : selectedIds.contains(id);

                  return TextButton(
                    onPressed: () async {
                      final notifier = ref.read(selectedSubCategoriesProvider.notifier);
                      if (id == null) {
                        notifier.state = [];
                      } else {
                        final current = Set<int>.from(notifier.state);
                        current.contains(id) ? current.remove(id) : current.add(id);
                        notifier.state = current.toList();
                      }

                      // Trigger fetch with new filter
                      await ref.read(fundsProvider.notifier).applyFilters({
                        "amcs": [],
                        "fund_category": [],
                        "sub_category": ref.read(selectedSubCategoriesProvider),
                        "risk_level": [],
                        "fund_size": [],
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: selected ? const Color(0xFF0060A6) : Colors.white,
                      foregroundColor: selected ? Colors.white : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: selected ? Colors.transparent : Colors.black26),
                      ),
                    ),
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(height: 45, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const Text("Failed to load categories", style: TextStyle(color: Colors.red)),
        ),
        const SizedBox(height: 12),

        // Funds (first N)
        Column(
          children: fundsToShow.map((fund) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: NfoFundCard(
                fundId: fund.fundId,
                logoPath: AppStrings.iconFunds_png,
                fundName: fund.fundName,
                productTitle: "${fund.fundType} • ${fund.fundSubType}",
                threeYearReturnValue: fund.threeYearReturn,
                totalCustomers: fund.totalCustomers,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}