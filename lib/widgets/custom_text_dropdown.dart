import 'package:flutter/material.dart';

import '../providers/onetime_startsip_provider.dart';

class CustomDropdownCard extends StatefulWidget {
  final String label;
  final List<dynamic> items;
  final ValueChanged<String?>? onChanged; // Made nullable
  final String? hintText;
  final String? selectedValue;
  final bool showLabelInside;
  final bool isMandateDropdown;
  final bool isEnabled; // Added parameter

  const CustomDropdownCard({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.selectedValue,
    this.showLabelInside = true,
    this.isMandateDropdown = false,
    this.isEnabled = true, // Default to true
  });

  @override
  State<CustomDropdownCard> createState() => _CustomDropdownCardState();
}

class _CustomDropdownCardState extends State<CustomDropdownCard> {
  late String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(CustomDropdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedValue != oldWidget.selectedValue) {
      selectedValue = widget.selectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showLabelInside) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown(),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown(),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    if (widget.isMandateDropdown) {
      final mandates = widget.items as List<Mandate>;
      return DropdownButtonFormField<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          filled: true,
          fillColor: widget.isEnabled
              ? (widget.showLabelInside ? Colors.white : const Color(0xFFF5F5F5))
              : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: widget.isEnabled ? Colors.black87 : Colors.grey.shade400,
        ),
        style: TextStyle(
          color: widget.isEnabled ? Colors.black87 : Colors.grey.shade600,
          fontSize: 14,
        ),
        items: mandates.asMap().entries.map((entry) {
          final mandate = entry.value;
          return DropdownMenuItem<String>(
            value: mandate.mandateId.toString(),
            child: Text(
              mandate.displayName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: widget.isEnabled ? (value) {
          if (value == null) return;
          setState(() {
            selectedValue = value;
          });
          widget.onChanged?.call(value);
        } : null,
      );
    } else {
      // Convert dynamic items to strings and deduplicate
      final uniqueItems = <String>[];
      final seen = <String>{};

      for (final item in widget.items) {
        final itemString = item.toString();
        if (!seen.contains(itemString)) {
          seen.add(itemString);
          uniqueItems.add(itemString);
        }
      }

      return DropdownButtonFormField<String>(
        value: selectedValue != null && uniqueItems.contains(selectedValue)
            ? selectedValue
            : null,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          filled: true,
          fillColor: widget.isEnabled
              ? (widget.showLabelInside ? Colors.white : const Color(0xFFF5F5F5))
              : Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5),
          ),
        ),
        dropdownColor: Colors.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: widget.isEnabled ? Colors.black87 : Colors.grey.shade400,
        ),
        style: TextStyle(
          color: widget.isEnabled ? Colors.black87 : Colors.grey.shade600,
          fontSize: 14,
        ),
        items: uniqueItems.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: widget.isEnabled ? (value) {
          setState(() {
            selectedValue = value;
          });
          widget.onChanged?.call(value);
        } : null,
      );
    }
  }
}