import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../providers/family_members_provider.dart';

class PortfolioCustomAppBar extends ConsumerWidget {
  final void Function({List<int>? clientIds})? onUserChanged;

  const PortfolioCustomAppBar({super.key, this.onUserChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMemberState = ref.watch(selectedMemberProvider);
    final familyMembersState = ref.watch(familyMembersProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Flexible(
            flex: 2,
            child: Text(
              AppStrings.portfolio_lbl,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          familyMembersState.when(
            data: (familyData) {
              if (familyData.allMembers.length <= 1) {
                return const SizedBox.shrink();
              }
              return Flexible(
                flex: 4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0060A6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: _buildSwitchOption(
                          context: context,
                          ref: ref,
                          label: AppStrings.me,
                          iconPath: AppStrings.curr_user,
                          isSelected: selectedMemberState.isMeSelected,
                          onTap: () {
                            if (!selectedMemberState.isMeSelected) {
                              ref.read(selectedMemberProvider.notifier).selectMe();
                              onUserChanged?.call(clientIds: []);
                            }
                          },
                        ),
                      ),
                      Flexible(
                        child: _buildSwitchOption(
                          context: context,
                          ref: ref,
                          label: selectedMemberState.displayName == AppStrings.me
                              ? AppStrings.all
                              : selectedMemberState.displayName,
                          iconPath: AppStrings.user_group,
                          isSelected: !selectedMemberState.isMeSelected,
                          showDropdownIcon: !selectedMemberState.isMeSelected,
                          onTap: () {
                            _showFamilyMemberDialog(context, ref);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => _buildShimmerSwitcher(),
            error: (err, stack) => _buildErrorSwitcher(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerSwitcher() {
    return Flexible(
      flex: 4,
      child: Shimmer.fromColors(
        baseColor: Colors.white.withOpacity(0.3),
        highlightColor: Colors.white.withOpacity(0.5),
        child: Container(
          constraints: const BoxConstraints(minWidth: 100),
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSwitcher(WidgetRef ref) {
    return Flexible(
      flex: 4,
      child: GestureDetector(
        onTap: () {
          ref.read(familyMembersProvider.notifier).fetchFamilyMembers();
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0060A6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchOption({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required String iconPath,
    required bool isSelected,
    required VoidCallback onTap,
    bool showDropdownIcon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF0060A6) : Colors.white,
                BlendMode.srcIn,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0060A6) : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showDropdownIcon) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down,
                  color: const Color(0xFF0060A6),
                  size: 20,
                ),
              ],
            ],
          ],
        ),
      ),
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
                              _buildMemberOption(
                                dialogContext,
                                ref,
                                AppStrings.user_group,
                                AppStrings.all,
                                selectedMemberState.displayName == AppStrings.all,
                                    () {
                                  Navigator.pop(dialogContext);
                                  final allIds = familyData.allMembers
                                      .map((m) => m.clientId)
                                      .toList();
                                  ref.read(selectedMemberProvider.notifier).selectAll(allIds);
                                  onUserChanged?.call(clientIds: allIds);
                                },
                              ),
                              const Divider(height: 1),

                              ...familyData.otherMembers.map((member) {
                                final isSelected =
                                    selectedMemberState.displayName == member.clientName;
                                return _buildMemberOption(
                                  dialogContext,
                                  ref,
                                  AppStrings.curr_user,
                                  member.clientName,
                                  isSelected,
                                      () {
                                    Navigator.pop(dialogContext);
                                    ref
                                        .read(selectedMemberProvider.notifier)
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

  Widget _buildMemberOption(
      BuildContext context,
      WidgetRef ref,
      String iconPath,
      String title,
      bool isSelected,
      VoidCallback onTap,
      ) {
    return Container(
      color: isSelected ? Colors.grey[300] : Colors.transparent,
      child: ListTile(
        leading: SvgPicture.asset(
          iconPath,
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
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
                'Unable to load family members',
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