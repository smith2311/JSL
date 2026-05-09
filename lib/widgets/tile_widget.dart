import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DetailTile extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String? route;
  final VoidCallback? onTap;

  const DetailTile({
    super.key,
    this.icon,
    this.svgAsset,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    this.route,
    this.onTap,
  }) : assert(icon != null || svgAsset != null, 'Either icon or svgAsset must be provided');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: _buildIcon(),
                ),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (svgAsset != null) {
      return SvgPicture.asset(
        svgAsset!,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    } else if (icon != null) {
      return Icon(
        icon,
        color: iconColor,
        size: 24,
      );
    }
    return const SizedBox.shrink();
  }
}