import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isBlue = false;
  int _counter = 0;
  Timer? _timer;

  // For exit animation
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup exit animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Start periodic color/logo switch
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _isBlue = !_isBlue;
        _counter++;
      });

      // After 4 switches → stop and animate exit
      if (_counter >= 4) {
        _timer?.cancel();
        _controller.forward().then((_) {
          // Navigate after animation finishes
          context.go('/onboarding');
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _isBlue
          ? _buildSplash(
        key: const ValueKey("blue"),
        bgColor: const Color(0xFF0056A6),
        logo: 'assets/images/white_logo.svg',
      )
          : _buildSplash(
        key: const ValueKey("white"),
        bgColor: const Color(0xFFF4F9FF),
        logo: 'assets/images/blue_logo.svg',
      ),
    );
  }

  Widget _buildSplash({
    required Key key,
    required Color bgColor,
    required String logo,
  }) {
    return Container(
      key: key,
      color: bgColor,
      alignment: Alignment.center,
      child: FadeTransition(
        opacity: _fadeAnimation.drive(Tween(begin: 1.0, end: 0.0)),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SvgPicture.asset(
            logo,
            width: 180,
          ),
        ),
      ),
    );
  }
}