import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Get current route
    final location = GoRouterState.of(context).uri.toString();

    // ✅ Map location to index
    int currentIndex = 0;
    if (location.startsWith('/dashboard')) currentIndex = 0;
    if (location.startsWith('/portfolio')) currentIndex = 1;
    if (location.startsWith('/discover')) currentIndex = 2;
    if (location.startsWith('/notifications')) currentIndex = 3;

    // ✅ Handle taps
    void _onTap(int index) {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/portfolio');
          break;
        case 2:
          context.go('/discover');
          break;
        // case 3:
        //   context.go('/notifications');
        //   break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(left: 18,right: 18,bottom: 26), // shrink from left/right
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: AppStrings.home,
            activeIcon: AppStrings.filled_home,
            label: AppStrings.home_lbl,
            onTap: _onTap,
          ),
          _buildNavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: AppStrings.portfolio,
            activeIcon: AppStrings.filled_portfolio,
            label: AppStrings.portfolio_lbl,
            onTap: _onTap,
          ),
          _buildNavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: AppStrings.discover,
            activeIcon: AppStrings.filled_discover,
            label: AppStrings.discover_lbl,
            onTap: _onTap,
          ),
          // _buildNavItem(
          //   index: 3,
          //   currentIndex: currentIndex,
          //   icon: AppStrings.notify,
          //   activeIcon: AppStrings.filled_notifications,
          //   label: AppStrings.notifications_lbl,
          //   onTap: _onTap,
          // ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required String icon,
    required String activeIcon,
    required String label,
    required Function(int) onTap,
  }) {
    final isActive = index == currentIndex;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onTap(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                isActive ? activeIcon : icon,
                height: 26,
                width: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? const Color(0xFF0060A6) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}