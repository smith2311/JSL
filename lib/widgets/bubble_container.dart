import 'package:flutter/material.dart';

class BubbleContainer extends StatelessWidget {
  final String text;
  final Color color;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final double borderRadius;
  final double triangleHeight;
  final double triangleWidth;
  final double triangleOffset; // <-- position of the triangle (default = center)

  const BubbleContainer({
    super.key,
    required this.text,
    this.color = const Color(0xFFDFF2FF),
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 8,
    this.triangleHeight = 8,
    this.triangleWidth = 16,
    this.triangleOffset = 0.5, // fraction of width (0.5 = center, 0.2 = left, etc.)
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        color: color,
        borderRadius: borderRadius,
        triangleHeight: triangleHeight,
        triangleWidth: triangleWidth,
        triangleOffset: triangleOffset,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: padding.left,
          right: padding.right,
          top: padding.top,
          bottom: padding.bottom + triangleHeight,
        ),
        child: Text(
          text,
          style: textStyle ??
              const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double triangleHeight;
  final double triangleWidth;
  final double triangleOffset; // 0.0 = left, 0.5 = center, 1.0 = right

  _BubblePainter({
    required this.color,
    required this.borderRadius,
    required this.triangleHeight,
    required this.triangleWidth,
    required this.triangleOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height - triangleHeight,
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);

    // ✅ Triangle X position based on triangleOffset fraction
    final triangleCenterX = size.width * triangleOffset;

    final trianglePath = Path();
    trianglePath.moveTo(triangleCenterX - triangleWidth / 2, size.height - triangleHeight);
    trianglePath.lineTo(triangleCenterX, size.height);
    trianglePath.lineTo(triangleCenterX + triangleWidth / 2, size.height - triangleHeight);
    trianglePath.close();

    path.addPath(trianglePath, Offset.zero);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}