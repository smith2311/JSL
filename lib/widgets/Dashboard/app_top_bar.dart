import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/strings.dart';
import '../../providers/family_members_provider.dart';

class AppTopBar extends ConsumerWidget {
  final String userName;
  final String? avatarUrl;
  final VoidCallback? onUserTap;
  final Color? iconColor;
  final bool showFamilySwitcher;
  final void Function({List<int>? clientIds})? onUserChanged;

  const AppTopBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.onUserTap,
    this.iconColor,
    this.showFamilySwitcher = false,
    this.onUserChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveIconColor = iconColor ?? Colors.black;
    final selectedMemberState = ref.watch(selectedMemberProvider);
    final bool hasNetworkImage = avatarUrl != null && avatarUrl!.startsWith("http");

    return Row(
      children: [
        if (!showFamilySwitcher)
          Expanded(
            child: InkWell(
              onTap: onUserTap ?? () {
                context.push('/user_profile');
              },
              borderRadius: BorderRadius.circular(30),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFDEE6EE),
                    backgroundImage: hasNetworkImage ? NetworkImage(avatarUrl!) : null,
                    child: !hasNetworkImage
                        ? Icon(
                      Icons.person,
                      color: effectiveIconColor == Colors.white
                          ? const Color(0xFF0060A6)
                          : Colors.white,
                      size: 24,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "${AppStrings.greetings} $userName",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: effectiveIconColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        if (showFamilySwitcher)
          Expanded(
            child: InkWell(
              onTap: () => _showFamilyMemberDialog(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF0060A6),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        selectedMemberState.displayName.length > 20
                            ? '${selectedMemberState.displayName.substring(0, 20)}...'
                            : selectedMemberState.displayName,
                        style: const TextStyle(
                          color: Color(0xFF0060A6),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF0060A6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

        const SizedBox(width: 8),

        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: SvgPicture.asset(
            AppStrings.notify,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              effectiveIconColor,
              BlendMode.srcIn,
            ),
          ),
        ),

        IconButton(
          onPressed: () {
            // TODO: Handle search functionality
          },
          icon: SvgPicture.asset(
            AppStrings.search,
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              effectiveIconColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    );
  }

  void _showFamilyMemberDialog(BuildContext context, WidgetRef ref) {
    final familyMembersState = ref.read(familyMembersProvider);
    final selectedMemberState = ref.read(selectedMemberProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (BuildContext dialogContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppStrings.fam_lbl,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: familyMembersState.when(
                        data: (familyData) {
                          return ListView(
                            controller: scrollController,
                            children: [
                              if (!showFamilySwitcher) ...[
                                _buildListTile(
                                  context: dialogContext,
                                  ref: ref,
                                  icon: AppStrings.curr_user,
                                  title: AppStrings.me,
                                  isSelected: selectedMemberState.isMeSelected,
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    ref.read(selectedMemberProvider.notifier).selectMe();
                                    onUserChanged?.call(clientIds: []);
                                  },
                                ),
                                const Divider(height: 1),
                              ],

                              if (!showFamilySwitcher) ...[
                                _buildListTile(
                                  context: dialogContext,
                                  ref: ref,
                                  icon: AppStrings.user_group,
                                  title: AppStrings.all,
                                  isSelected: selectedMemberState.displayName == AppStrings.all,
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    final allIds = familyData.allMembers
                                        .map((m) => m.clientId)
                                        .toList();
                                    ref.read(selectedMemberProvider.notifier).selectAll(allIds);
                                    onUserChanged?.call(clientIds: allIds);
                                  },
                                ),
                                const Divider(height: 1),
                              ],

                              ...familyData.otherMembers.map((member) {
                                final isSelected = selectedMemberState.displayName == member.clientName;
                                return _buildListTile(
                                  context: dialogContext,
                                  ref: ref,
                                  icon: AppStrings.curr_user,
                                  title: member.clientName,
                                  isSelected: isSelected,
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    ref.read(selectedMemberProvider.notifier)
                                        .selectMember(member.clientId, member.clientName);
                                    onUserChanged?.call(clientIds: [member.clientId]);
                                  },
                                );
                              }).toList(),
                            ],
                          );
                        },
                        loading: () => _buildShimmerList(scrollController),
                        error: (err, _) => _buildErrorState(ref, scrollController),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required WidgetRef ref,
    required String icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isSelected ? Colors.grey[300] : Colors.transparent,
      child: ListTile(
        leading: SvgPicture.asset(
          icon,
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(
            Color(0xFF0060A6),
            BlendMode.srcIn,
          ),
        ),
        title: Text(title),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0060A6),
              width: 2,
            ),
            color: isSelected ? const Color(0xFF0060A6) : Colors.transparent,
          ),
          child: isSelected
              ? const Center(
            child: Icon(
              Icons.circle,
              size: 12,
              color: Colors.white,
            ),
          )
              : null,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildShimmerList(ScrollController scrollController) {
    return ListView.builder(
      controller: scrollController,
      itemCount: 5,
      itemBuilder: (_, i) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListTile(
          leading: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            color: Colors.white,
          ),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unable to fetch family members. Retrying...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(familyMembersProvider.notifier).fetchFamilyMembers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}