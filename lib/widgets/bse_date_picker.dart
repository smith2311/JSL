import 'package:flutter/material.dart';

class BseDatePickerWidget extends StatefulWidget {
  final int? initialDay;
  final String label;
  final String? helperText;
  final ValueChanged<int> onDaySelected;
  final String? Function(int?)? validator;
  final bool enabled;
  final List<int>? allowedDays;
  final List<int>? disabledDays;

  const BseDatePickerWidget({
    super.key,
    this.initialDay,
    required this.label,
    this.helperText,
    required this.onDaySelected,
    this.validator,
    this.enabled = true,
    this.allowedDays,
    this.disabledDays,
  });

  @override
  State<BseDatePickerWidget> createState() => _BseDatePickerWidgetState();
}

class _BseDatePickerWidgetState extends State<BseDatePickerWidget> {
  int? _selectedDay;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
  }

  void _validateDay(int? day) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(day);
      });
    }
  }

  List<int> _getAvailableDays() {
    if (widget.allowedDays != null && widget.allowedDays!.isNotEmpty) {
      return widget.allowedDays!;
    }

    // Default: days 1-28 (safe for all months)
    final days = List.generate(28, (i) => i + 1);

    if (widget.disabledDays != null) {
      return days.where((day) => !widget.disabledDays!.contains(day)).toList();
    }

    return days;
  }

  void _showDayPicker() {
    if (!widget.enabled) return;

    final availableDays = _getAvailableDays();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select SWP Date',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the day of the month for withdrawal',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availableDays.length,
                  itemBuilder: (context, index) {
                    final day = availableDays[index];
                    final isSelected = day == _selectedDay;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                        });
                        _validateDay(day);
                        widget.onDaySelected(day);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0060A6)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0060A6)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  String _getDisplayText() {
    if (_selectedDay == null) return 'Select Date';

    // Add ordinal suffix
    String suffix = 'th';
    if (_selectedDay! % 10 == 1 && _selectedDay != 11) {
      suffix = 'st';
    } else if (_selectedDay! % 10 == 2 && _selectedDay != 12) {
      suffix = 'nd';
    } else if (_selectedDay! % 10 == 3 && _selectedDay != 13) {
      suffix = 'rd';
    }

    return '$_selectedDay$suffix of every month';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showDayPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: widget.enabled ? Colors.white : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _errorText != null
                    ? Colors.red
                    : const Color(0xFFE0E0E0),
                width: _errorText != null ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getDisplayText(),
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedDay == null
                        ? const Color(0xFF888898)
                        : Colors.black,
                    fontWeight: _selectedDay == null
                        ? FontWeight.w400
                        : FontWeight.w500,
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  color: widget.enabled
                      ? const Color(0xFF0060A6)
                      : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              _errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
        if (widget.helperText != null && _errorText == null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              widget.helperText!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888898),
              ),
            ),
          ),
      ],
    );
  }
}

// BSE Date validators
class BseDateValidators {
  static String? required(int? day) {
    if (day == null) {
      return 'Please select a date';
    }
    return null;
  }

  static String? validDay(int? day) {
    if (day == null) {
      return 'Please select a date';
    }
    if (day < 1 || day > 28) {
      return 'Day must be between 1 and 28';
    }
    return null;
  }

  static String? Function(int?) notInList(List<int> disallowedDays) {
    return (day) {
      if (day == null) {
        return 'Please select a date';
      }
      if (disallowedDays.contains(day)) {
        return 'This date is not available';
      }
      return null;
    };
  }

  static String? Function(int?) mustBeInList(List<int> allowedDays) {
    return (day) {
      if (day == null) {
        return 'Please select a date';
      }
      if (!allowedDays.contains(day)) {
        return 'Please select from available dates';
      }
      return null;
    };
  }

  static String? Function(int?) combinedValidators(
      List<String? Function(int?)> validators,
      ) {
    return (day) {
      for (final validator in validators) {
        final error = validator(day);
        if (error != null) return error;
      }
      return null;
    };
  }
}