import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../constants/strings.dart';

class UserProfileAppBar extends StatelessWidget {
  final String userName;
  final String? avatarUrl;
  final String? token;
  final VoidCallback? onAvatarTap;

  const UserProfileAppBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.token,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasNetworkImage =
        avatarUrl != null && avatarUrl!.startsWith("http");

    return Column(
      children: [
        // 🔹 Blue Top Bar
        Container(
          width: double.infinity,
          height: 190,
          color: const Color(0xFF0060A6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 70),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                IconButton(
                  icon: SvgPicture.asset(
                    AppStrings.back_icon,
                    color: Colors.white,
                    width: 28,
                    height: 26,
                  ),
                  onPressed: () => context.push('/dashboard'),
                ),
                const SizedBox(width: 3),
                const Text(
                  AppStrings.profile_title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 🔹 Avatar + Username
        Transform.translate(
          offset: const Offset(0, -50),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 47,
                        backgroundColor: const Color(0xFFDEE6EE),
                        backgroundImage:
                        hasNetworkImage ? NetworkImage(avatarUrl!) : null,
                        child: !hasNetworkImage
                            ? const Icon(Icons.person,
                            size: 60, color: Colors.white)
                            : null,
                      ),
                    ),
                    // Edit Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onAvatarTap ?? () {},
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey, width: 1),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Color(0xFF0060A6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (userName.isNotEmpty)
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}