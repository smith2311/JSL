import 'package:flutter/material.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class RiskBarWidget extends StatelessWidget {
  final String riskLevel; // 'Low', 'Moderately Low', 'Moderate', 'Moderately High', 'High'
  final double width;

  const RiskBarWidget({
    super.key,
    required this.riskLevel,
    required this.width, // smaller width
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, 10), // slim total height
      painter: _RiskBarPainter(riskLevel),
    );
  }
}

class _RiskBarPainter extends CustomPainter {
  final String riskLevel;
  final double barHeight = 12; // very slim bar

  _RiskBarPainter(this.riskLevel);

  final List<Color> _colors = [
    Color(0xFF8AC83D), // Low
    Color(0xFFDAE021), // Moderately Low
    Color(0xFFFDD120), // Moderate
    Color(0xFFF15A25), // Moderately High
    Color(0xFFC3272E), // High
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final segmentCount = _colors.length;
    final segmentWidth = size.width / segmentCount;
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw slim bar with rounded edges
    for (int i = 0; i < segmentCount; i++) {
      paint.color = _colors[i];
      final rect = Rect.fromLTWH(i * segmentWidth, 2, segmentWidth, barHeight);
      final rRect = RRect.fromRectAndCorners(
        rect,
        topLeft: i == 0 ? Radius.circular(3) : Radius.zero,
        bottomLeft: i == 0 ? Radius.circular(3) : Radius.zero,
        topRight: i == segmentCount - 1 ? Radius.circular(3) : Radius.zero,
        bottomRight: i == segmentCount - 1 ? Radius.circular(3) : Radius.zero,
      );
      canvas.drawRRect(rRect, paint);
    }

    // Draw triangle pointer
    int index = AppStrings.riskLabels.indexOf(riskLevel);
    if (index < 0) index = 2; // default to Moderate if unknown

    final trianglePaint = Paint()..color = _colors[index];
    final triangleWidth = 10.0; // smaller triangle
    final triangleHeight = 5.0; // shorter height
    final centerX = index * segmentWidth + segmentWidth / 2;

    final path = Path()
      ..moveTo(centerX - triangleWidth / 2, 2)
      ..lineTo(centerX + triangleWidth / 2, 2)
      ..lineTo(centerX, 2 - triangleHeight)
      ..close();
    canvas.drawPath(path, trianglePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}