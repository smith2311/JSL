import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SwpDatePickerWidget extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime? minDate;
  final DateTime? maxDate;
  final String label;
  final String? helperText;
  final ValueChanged<DateTime> onDateSelected;
  final String? Function(DateTime?)? validator;
  final bool enabled;

  const SwpDatePickerWidget({
    super.key,
    this.initialDate,
    this.minDate,
    this.maxDate,
    required this.label,
    this.helperText,
    required this.onDateSelected,
    this.validator,
    this.enabled = true,
  });

  @override
  State<SwpDatePickerWidget> createState() => _SwpDatePickerWidgetState();
}

class _SwpDatePickerWidgetState extends State<SwpDatePickerWidget> {
  DateTime? _selectedDate;
  String? _errorText;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _controller.text = DateFormat('dd MMM yyyy').format(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateDate(DateTime? date) {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(date);
      });
    }
  }

  Future<void> _selectDate() async {
    if (!widget.enabled) return;

    final now = DateTime.now();
    final minDate = widget.minDate ?? now;
    final maxDate = widget.maxDate ?? DateTime(now.year + 10);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? minDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0060A6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _controller.text = DateFormat('dd MMM yyyy').format(pickedDate);
      });
      _validateDate(pickedDate);
      widget.onDateSelected(pickedDate);
    }
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
        GestureDetector(
          onTap: _selectDate,
          child: AbsorbPointer(
            child: TextFormField(
              controller: _controller,
              enabled: widget.enabled,
              decoration: InputDecoration(
                hintText: 'Select Date',
                hintStyle: const TextStyle(color: Color(0xFF888898)),
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF0060A6),
                  size: 20,
                ),
                errorText: _errorText,
                helperText: widget.helperText,
                helperStyle: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888898),
                ),
                filled: true,
                fillColor: widget.enabled ? Colors.white : const Color(0xFFF5F5F5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF0060A6),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Example validators
class DateValidators {
  static String? requiredDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    return null;
  }

  static String? mustBeFutureDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay.isBefore(today)) {
      return 'Date must be today or in the future';
    }
    return null;
  }

  static String? mustBeWithinNextYear(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    final now = DateTime.now();
    final oneYearFromNow = DateTime(now.year + 1, now.month, now.day);

    if (date.isAfter(oneYearFromNow)) {
      return 'Date must be within the next year';
    }
    return null;
  }

  static String? Function(DateTime?) combinedValidators(
      List<String? Function(DateTime?)> validators,
      ) {
    return (date) {
      for (final validator in validators) {
        final error = validator(date);
        if (error != null) return error;
      }
      return null;
    };
  }
}