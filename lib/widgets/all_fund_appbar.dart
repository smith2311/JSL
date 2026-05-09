import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../constants/strings.dart';
import '../widgets/animated_save_button.dart';

class FundDetailAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final int fundId;
  final String fundName;
  final VoidCallback? onBack;

  const FundDetailAppBar({
    super.key,
    required this.fundId,
    required this.fundName,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 25),
      child: Container(
        color: const Color(0xFFF6F8FB),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  AppStrings.back_icon,
                  width: 24,
                  height: 24,
                ),
                onPressed: () {
                  if (onBack != null) {
                    onBack!();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              // Save button now fully reactive with watchlist
              AnimatedSaveButton(
                fundName: fundName,
                fundId: fundId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}