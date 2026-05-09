import 'package:flutter/material.dart';

class PageIndicatorWidget extends StatelessWidget {
  final int currentIndex;
  final int length; // 👈 renamed to length

  const PageIndicatorWidget({
    super.key,
    required this.currentIndex,
    required this.length,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: currentIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? const Color(0xFF0060A6)
                : const Color(0xFF1A415D),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}