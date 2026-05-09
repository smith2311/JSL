import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../../constants/strings.dart';
import '../../../../../core/auth_helper.dart';
import '../../../../../providers/user_provider.dart';
import '../../../../../widgets/user_profile_appbar.dart';

class UserProfile extends ConsumerWidget {
  const UserProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: Column(
        children: [
          UserProfileAppBar(
            userName: user.userName,
            avatarUrl: user.avatarUrl,
            token: user.token,
            onAvatarTap: () {},
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: AppStrings.profileOptions.length,
              itemBuilder: (context, index) {
                final option = AppStrings.profileOptions[index];
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        if (option['title'] == 'Log out') {
                          // Step 1: Confirm logout
                          final shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFFFFFFFF),
                              title: const Text('Confirm Logout'),
                              content: const Text(
                                  'Are you sure you want to log out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel',style: TextStyle(color: Color(0xFF0060A6)),),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Logout',style: TextStyle(color: Color(0xFF0060A6)),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            // Step 2: Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              // Step 3: Call logout (which clears user state + calls API)
                              await AuthHelper.logout(context, ref);
                            } finally {
                              // Step 4: Dismiss loader if still open
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        } else if (option['route'] != null) {
                          context.push(option['route']);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xffe3f3fe),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  option['icon'],
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                option['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (option['showArrow'] as bool)
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}