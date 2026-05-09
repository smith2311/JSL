import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import 'package:jhaveri_jsl_app/widgets/top_bar_widget.dart';
import 'package:jhaveri_jsl_app/widgets/onboarding_image_widget.dart';
import 'package:jhaveri_jsl_app/widgets/page_indicator_widget.dart';
import 'package:jhaveri_jsl_app/widgets/onboarding_card_widget.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Lock orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("onboarding_complete", true);

      debugPrint("✅ Onboarding_Screen completed, navigating to login");

      if (!mounted) return;

      // Navigate to login screen
      context.go('/login');
    } catch (e) {
      debugPrint("❌ Error completing onboarding: $e");
    }
  }

  void _next() {
    if (currentIndex < AppStrings.onboardingData.length - 1) {
      setState(() => currentIndex++);
    } else {
      _completeOnboarding();
    }
  }

  void _previous() {
    if (currentIndex > 0) {
      setState(() => currentIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AppStrings.onboardingData[currentIndex];
    final isLastPage = currentIndex == AppStrings.onboardingData.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppStrings.onboardingBG),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar (Skip → login)
              TopBarWidget(onSkip: _completeOnboarding),

              // Animated Image Section
              Expanded(
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.2, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: OnboardingImageWidget(
                        key: ValueKey<int>(currentIndex),
                        imagePath: data["image"]!,
                        index: currentIndex,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // Page indicator ABOVE card
              PageIndicatorWidget(
                currentIndex: currentIndex,
                length: AppStrings.onboardingData.length,
              ),
              const SizedBox(height: 12),

              // Animated Card Section
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: OnboardingCardWidget(
                  key: ValueKey<int>(currentIndex),
                  title: data["title"]!,
                  description: data["description"]!,
                  showBack: currentIndex > 0,
                  isLastPage: isLastPage,
                  onNext: _next,
                  onPrevious: _previous,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}