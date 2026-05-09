import 'package:flutter/material.dart';

class OnboardingImageWidget extends StatelessWidget {
  final String imagePath;
  final int index; // 👈 used for ValueKey

  const OnboardingImageWidget({
    super.key,
    required this.imagePath,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.2, 0),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Image.asset(
        imagePath,
        height: size.height * 0.3, // 👈 still responsive
        key: ValueKey<int>(index),
      ),
    );
  }
}