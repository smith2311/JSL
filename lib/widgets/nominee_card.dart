import 'package:flutter/material.dart';
import '../features/auth/data/models/nominee_centre.dart';
import '../constants/strings.dart';

class NomineeCard extends StatelessWidget {
  final Nominee nominee;
  final int index;
  final VoidCallback onEdit;

  const NomineeCard({
    super.key,
    required this.nominee,
    required this.index,
    required this.onEdit,
  });

  String _getFullName() {
    final parts = [
      nominee.firstName,
      nominee.middleName,
      nominee.lastName,
    ].where((part) => part.isNotEmpty);

    return parts.join(' ');
  }

  String _getRelationLabel() {
    // Convert API key to display label
    return AppStrings.getRelationLabel(nominee.relation);
  }

  @override
  Widget build(BuildContext context) {
    print('🃏 NomineeCard Debug:');
    print('   Index: $index');
    print('   Name: ${_getFullName()}');
    print('   Relation API Key: ${nominee.relation}');
    print('   Relation Label: ${_getRelationLabel()}');
    print('   Percentage: ${nominee.applicablePercentage}'); // ✅ Should now show correct value

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with name and edit button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFullName(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRelationLabel(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF0066A6),
                    size: 20,
                  ),
                  tooltip: 'Edit nominee',
                ),
              ],
            ),
          ),

          // Bottom section with allocation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Allocation',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${nominee.applicablePercentage.toStringAsFixed(nominee.applicablePercentage.truncateToDouble() == nominee.applicablePercentage ? 0 : 1)}%', // ✅ Format percentage properly
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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