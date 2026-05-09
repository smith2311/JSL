import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const CustomButton({
    super.key,
    this.text,
    this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null && !isPrimary) {
      // Back button
      return InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF0060A6), width: 2),
          ),
          child: Icon(icon, color: const Color(0xFF0060A6)),
        ),
      );
    }

    // Primary button
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0056A6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text ?? "",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}