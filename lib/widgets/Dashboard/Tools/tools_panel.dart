import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';

class ToolsPanel extends StatelessWidget {
  const ToolsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // SIP Calculator
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/sip-calculator'),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppStrings.calculator,
                    height: 28,
                    width: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "SIP Calculator",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Fund Comparison
        Expanded(
          child: GestureDetector(
            onTap: () {
                context.push('/compare-funds');
            },
            child: Container(
              margin: const EdgeInsets.only(right: 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    AppStrings.fund_comp,
                    height: 28,
                    width: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Fund Comparison",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}