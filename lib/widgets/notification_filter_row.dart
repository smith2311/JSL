import 'package:flutter/material.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class NotificationFilterRow extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  const NotificationFilterRow({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: AppStrings.notificationFilters.map((filter) {
            final isSelected = filter == selectedFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => onFilterSelected(filter),
                style: TextButton.styleFrom(
                  backgroundColor:
                  isSelected ? const Color(0xFF0060A6) : Colors.transparent,
                  foregroundColor: isSelected ? Colors.white : Colors.black,
                  minimumSize: Size.zero, // removes min constraints
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? Colors.transparent : Colors.black26,
                    ),
                  ),
                ),
                child: Text(
                  filter,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}