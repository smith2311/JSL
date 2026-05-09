import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class TopBarWidget extends StatelessWidget {
  final VoidCallback onSkip;
  const TopBarWidget({super.key, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,right: 20,top: 26
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(AppStrings.whiteLogo, height: 40),
          TextButton(
            onPressed: onSkip,
            child: const Text(
              AppStrings.dashboard_skip,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}