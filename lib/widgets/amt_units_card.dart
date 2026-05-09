import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountUnitsInputWidget extends StatefulWidget {
  final bool isAmount;
  final double availableAmount;
  final double availableUnits;
  final double minAmount;
  final double maxAmount;
  final double minUnits;
  final double maxUnits;
  final bool switchAll;
  final ValueChanged<bool> onSwitchAllChanged;
  final ValueChanged<String>? onValueChanged;

  const AmountUnitsInputWidget({
    super.key,
    required this.isAmount,
    required this.availableAmount,
    required this.availableUnits,
    required this.minAmount,
    required this.maxAmount,
    required this.minUnits,
    required this.maxUnits,
    required this.switchAll,
    required this.onSwitchAllChanged,
    this.onValueChanged,
  });

  @override
  State<AmountUnitsInputWidget> createState() => _AmountUnitsInputWidgetState();
}

class _AmountUnitsInputWidgetState extends State<AmountUnitsInputWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(AmountUnitsInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle switch all toggle
    if (widget.switchAll != oldWidget.switchAll) {
      if (widget.switchAll) {
        final effectiveMax = _getEffectiveMax();
        final decimals = widget.isAmount ? 2 : 3;
        final value = effectiveMax.toStringAsFixed(decimals);
        _controller.text = value;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onValueChanged?.call(value);
        });
      } else {
        _controller.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onValueChanged?.call('');
        });
      }
    }

    // Clear input when switching between Amount/Units
    if (widget.isAmount != oldWidget.isAmount) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onValueChanged?.call('');
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getEffectiveMax() {
    if (widget.isAmount) {
      return widget.availableAmount < widget.maxAmount
          ? widget.availableAmount
          : widget.maxAmount;
    } else {
      return widget.availableUnits < widget.maxUnits
          ? widget.availableUnits
          : widget.maxUnits;
    }
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.isAmount ? widget.minAmount : widget.minUnits;
    final effectiveMax = _getEffectiveMax();
    final decimals = widget.isAmount ? 2 : 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isAmount ? 'Investment Amount' : 'Investment Units',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888898),
            ),
          ),
          const SizedBox(height: 16),

          // Input Field
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isAmount)
                const Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              if (widget.isAmount) const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[300],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && widget.switchAll) {
                      widget.onSwitchAllChanged(false);
                    }

                    // Validate input against effectiveMax
                    if (value.isNotEmpty) {
                      try {
                        final inputValue = double.parse(value);
                        if (inputValue > effectiveMax) {
                          _controller.text = effectiveMax.toStringAsFixed(decimals);
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _controller.text.length),
                          );
                          widget.onValueChanged?.call(_controller.text);
                        } else {
                          widget.onValueChanged?.call(value);
                        }
                      } catch (e) {
                        widget.onValueChanged?.call('');
                      }
                    } else {
                      widget.onValueChanged?.call('');
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),

          const SizedBox(height: 16),

          // Min/Max Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min. ${widget.isAmount ? '₹' : ''}${min.toStringAsFixed(decimals)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888898),
                ),
              ),
              Text(
                'Max. ${widget.isAmount ? '₹' : ''}${effectiveMax.toStringAsFixed(decimals)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888898),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Switch All Checkbox
          InkWell(
            onTap: () {
              widget.onSwitchAllChanged(!widget.switchAll);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: widget.switchAll,
                    onChanged: (value) {
                      widget.onSwitchAllChanged(value ?? false);
                    },
                    activeColor: const Color(0xFF0060A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Switch all',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
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