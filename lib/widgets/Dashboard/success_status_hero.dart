import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SuccessStatusHero extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final String ctaText;
  final VoidCallback onPressed;

  const SuccessStatusHero({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ✅ Success image
          SvgPicture.asset(
            imagePath,
            height: 80,
            width: 80,
          ),
          const SizedBox(height: 16),

          // ✅ Title with custom color
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black, // brand blue
            ),
          ),
          const SizedBox(height: 8),

          // ✅ Subtitle with softer grey
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey, // lighter subtitle color
            ),
          ),
          const SizedBox(height: 20),

          // ✅ CTA button
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 150,
              height: 50,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  ctaText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}