import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/portfolio_fund_card_provider.dart';

class PortfolioTabs extends ConsumerWidget {
  final List<String> titles;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const PortfolioTabs({
    super.key,
    required this.titles,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundListState = ref.watch(fundListProvider);
    final totalRecords = fundListState.maybeWhen(
      data: (fundState) => fundState.totalRecords,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(titles.length, (index) {
          final isSelected = selectedIndex == index;

          // Update first tab dynamically with total records count from API
          final displayTitle = index == 0 ? '${titles[index]} ($totalRecords)' : titles[index];

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.horizontal(
                    left: index == 0 ? const Radius.circular(8) : Radius.zero,
                    right: index == titles.length - 1 ? const Radius.circular(8) : Radius.zero,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Inner selected fill
                    if (isSelected)
                      Positioned(
                        top: 4,
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0060A6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    Center(
                      child: Text(
                        displayTitle,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}