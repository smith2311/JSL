import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwpInstallmentsWidget extends StatefulWidget {
  final int? initialValue;
  final int minInstallments;
  final int maxInstallments;
  final String label;
  final String? helperText;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;
  final bool enabled;
  final bool showIncrementButtons;

  const SwpInstallmentsWidget({
    super.key,
    this.initialValue,
    this.minInstallments = 1,
    this.maxInstallments = 999,
    required this.label,
    this.helperText,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.showIncrementButtons = true,
  });

  @override
  State<SwpInstallmentsWidget> createState() => _SwpInstallmentsWidgetState();
}

class _SwpInstallmentsWidgetState extends State<SwpInstallmentsWidget> {
  late TextEditingController _controller;
  String? _errorText;
  int? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validateAndUpdate(String value) {
    if (value.isEmpty) {
      setState(() {
        _currentValue = null;
        _errorText = widget.validator?.call(null);
      });
      widget.onChanged(null);
      return;
    }

    final parsed = int.tryParse(value);
    setState(() {
      _currentValue = parsed;
      _errorText = widget.validator?.call(parsed);
    });
    widget.onChanged(parsed);
  }

  void _increment() {
    if (!widget.enabled) return;

    final current = _currentValue ?? 0;
    if (current < widget.maxInstallments) {
      final newValue = current + 1;
      _controller.text = newValue.toString();
      _validateAndUpdate(newValue.toString());
    }
  }

  void _decrement() {
    if (!widget.enabled) return;

    final current = _currentValue ?? 0;
    if (current > widget.minInstallments) {
      final newValue = current - 1;
      _controller.text = newValue.toString();
      _validateAndUpdate(newValue.toString());
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
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                onChanged: _validateAndUpdate,
                decoration: InputDecoration(
                  hintText: 'Enter number',
                  hintStyle: const TextStyle(color: Color(0xFF888898)),
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
            if (widget.showIncrementButtons) ...[
              const SizedBox(width: 12),
              Column(
                children: [
                  InkWell(
                    onTap: _increment,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 40,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.enabled &&
                            (_currentValue ?? 0) < widget.maxInstallments
                            ? const Color(0xFF0060A6)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 18,
                        color: widget.enabled &&
                            (_currentValue ?? 0) < widget.maxInstallments
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: _decrement,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 40,
                      height: 28,
                      decoration: BoxDecoration(
                        color: widget.enabled &&
                            (_currentValue ?? 0) > widget.minInstallments
                            ? const Color(0xFF0060A6)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 18,
                        color: widget.enabled &&
                            (_currentValue ?? 0) > widget.minInstallments
                            ? Colors.white
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// Example validators for installments
class InstallmentValidators {
  static String? required(int? value) {
    if (value == null) {
      return 'Please enter number of installments';
    }
    return null;
  }

  static String? Function(int?) minValue(int min) {
    return (value) {
      if (value == null) {
        return 'Please enter number of installments';
      }
      if (value < min) {
        return 'Minimum $min installments required';
      }
      return null;
    };
  }

  static String? Function(int?) maxValue(int max) {
    return (value) {
      if (value == null) {
        return 'Please enter number of installments';
      }
      if (value > max) {
        return 'Maximum $max installments allowed';
      }
      return null;
    };
  }

  static String? Function(int?) range(int min, int max) {
    return (value) {
      if (value == null) {
        return 'Please enter number of installments';
      }
      if (value < min || value > max) {
        return 'Enter between $min and $max installments';
      }
      return null;
    };
  }

  static String? Function(int?) multipleOf(int multiple) {
    return (value) {
      if (value == null) {
        return 'Please enter number of installments';
      }
      if (value % multiple != 0) {
        return 'Must be a multiple of $multiple';
      }
      return null;
    };
  }

  static String? Function(int?) combinedValidators(
      List<String? Function(int?)> validators,
      ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}