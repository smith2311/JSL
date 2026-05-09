// Updated custom_slider.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom slider thumb shape with an inner white circle
class CustomSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double innerCircleRadius;

  const CustomSliderThumbShape({
    required this.enabledThumbRadius,
    required this.innerCircleRadius,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
      PaintingContext context,
      Offset center, {
        required Animation<double> activationAnimation,
        required Animation<double> enableAnimation,
        required bool isDiscrete,
        required TextPainter labelPainter,
        required RenderBox parentBox,
        required SliderThemeData sliderTheme,
        required TextDirection textDirection,
        required double value,
        required double textScaleFactor,
        required Size sizeWithOverflow,
      }) {
    final Canvas canvas = context.canvas;

    // Draw outer circle (blue)
    final outerPaint = Paint()
      ..color = sliderTheme.thumbColor ?? const Color(0xFF0060A6)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, enabledThumbRadius, outerPaint);

    // Draw inner circle (white)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, innerCircleRadius, innerPaint);
  }
}

/// Text field input widget with label and error handling
class TextFieldInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Function(String) onChanged;
  final String? suffix;
  final String? errorText;

  const TextFieldInput({
    super.key,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.suffix,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0060A6), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

/// Slider widget with an editable text input field
class SliderWithInput extends StatelessWidget {
  final String label;
  final double value;
  final TextEditingController controller;
  final double min;
  final double max;
  final int divisions;
  final Function(double) onSliderChanged;
  final Function(String) onTextChanged;
  final String? prefix;
  final String? suffix;
  final String? errorText;
  final bool showTicks;

  const SliderWithInput({
    super.key,
    required this.label,
    required this.value,
    required this.controller,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onSliderChanged,
    required this.onTextChanged,
    this.prefix,
    this.suffix,
    this.errorText,
    this.showTicks = true,
  });

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and input field on same row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(
              width: 100,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onTextChanged,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                decoration: InputDecoration(
                  prefixText: prefix,
                  suffixText: suffix,
                  prefixStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  suffixStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF6F8FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0060A6), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Slider aligned from the left
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF0060A6),
            inactiveTrackColor: Colors.grey.shade300,
            thumbColor: const Color(0xFF0060A6),
            overlayColor: const Color(0xFF0060A6).withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const CustomSliderThumbShape(
              enabledThumbRadius: 10.0,
              innerCircleRadius: 4.0,
            ),
            tickMarkShape: showTicks ? null : SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: clampedValue,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onSliderChanged,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}