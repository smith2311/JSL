import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../features/auth/data/models/portfolio.dart';
import '../providers/family_members_provider.dart';

class PortfolioCard extends ConsumerWidget {
  final PortfolioModel? portfolio;
  final double? xirr;
  final String displayTitle;
  final bool showFamilySwitcher;
  final void Function({List<int>? clientIds})? onUserChanged;
  final bool showOneDayReturn;
  final VoidCallback? onViewPortfolio;
  final bool useCompactLayout;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const PortfolioCard({
    super.key,
    this.portfolio,
    this.xirr,
    required this.displayTitle,
    this.showFamilySwitcher = false,
    this.onUserChanged,
    this.showOneDayReturn = true,
    this.onViewPortfolio,
    this.useCompactLayout = false,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMemberState = ref.watch(selectedMemberProvider);

    // Always show shimmer when loading or no data - never show error UI in card
    if (isLoading || portfolio == null) {
      return _buildShimmerCard();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: useCompactLayout
          ? _buildCompactLayout(context, ref, selectedMemberState)
          : _buildDefaultLayout(context, ref, selectedMemberState),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 80,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 28,
              width: 150,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 40, width: 100, color: Colors.white),
                Container(height: 40, width: 100, color: Colors.white),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 2, color: Colors.white),
            const SizedBox(height: 12),
            Container(height: 20, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, WidgetRef ref, SelectedMemberState selectedMemberState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Mutual Funds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (showFamilySwitcher)
              _buildFamilySwitcher(context, ref, selectedMemberState),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.returns,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center, // For better vertical alignment
                    children: [
                      Flexible(
                        child: Text(
                          '${portfolio!.totalReturn >= 0 ? '+' : ''}₹${_formatCurrency(portfolio!.totalReturn)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: portfolio!.totalReturn >= 0 ? Colors.green : Colors.red,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8), // A bit more space

                      // The return percentage Text is now wrapped in a styled Container
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (portfolio!.returnPercentage >= 0 ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${portfolio!.returnPercentage >= 0 ? '+' : ''}${portfolio!.returnPercentage.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 12, // Adjusted size to fit nicely in the container
                            fontWeight: FontWeight.w600,
                            color: portfolio!.returnPercentage >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  AppStrings.xirr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(xirr ?? 0).toStringAsFixed(2)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 2),

        const Divider(thickness: 1, color: Color(0xFFE0E0E0)),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.current,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatCurrency(portfolio!.currentValue)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  AppStrings.inv,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_formatCurrency(portfolio!.totalInvestment)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),

        if (onViewPortfolio != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onViewPortfolio,
            child: Row(
              children: [
                const Text(
                  'View Portfolio',
                  style: TextStyle(
                    color: Color(0xFF0060A6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF0060A6),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultLayout(BuildContext context, WidgetRef ref, SelectedMemberState selectedMemberState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppStrings.returns,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (showFamilySwitcher) ...[
              const SizedBox(width: 8),
              _buildFamilySwitcher(context, ref, selectedMemberState),
            ],
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Text(
              '${portfolio!.totalReturn >= 0 ? '+' : ''}₹${_formatCurrency(portfolio!.totalReturn)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: portfolio!.totalReturn >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (portfolio!.returnPercentage >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${portfolio!.returnPercentage >= 0 ? '+' : ''}${portfolio!.returnPercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: portfolio!.returnPercentage >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMetric(AppStrings.current, portfolio!.currentValue),
            _buildMetric(AppStrings.inv, portfolio!.totalInvestment),
          ],
        ),

        const SizedBox(height: 4),
        const Divider(thickness: 2, color: Color(0xFFF1F3F5)),

        if (showOneDayReturn) ...[
          _buildMetricRow(
            AppStrings.one_d_ret,
            portfolio!.oneDayReturn ?? 0,
            portfolio!.oneDayReturnPercentage ?? 0,
          ),
          const SizedBox(height: 8),
        ],

        _buildMetricRow(
          AppStrings.xirr,
          xirr ?? 0,
          null,
        ),

        if (onViewPortfolio != null) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: onViewPortfolio,
            child: Row(
              children: [
                const Text(
                  'View Portfolio',
                  style: TextStyle(
                    color: Color(0xFF0060A6),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward,
                  color: Color(0xFF0060A6),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFamilySwitcher(
      BuildContext context,
      WidgetRef ref,
      SelectedMemberState selectedMemberState,
      ) {
    String displayName = selectedMemberState.isMeSelected
        ? AppStrings.me
        : selectedMemberState.displayName;

    return InkWell(
      onTap: () => _showFamilyMemberDialog(context, ref),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                displayName.length > 12
                    ? '${displayName.substring(0, 12)}...'
                    : displayName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.black54,
              size: 16,
            ),
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
                              _buildFamilyOption(
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

                              ...familyData.allMembers.map((member) {
                                final isCurrentUser = familyData.currentUser != null &&
                                    member.clientId == familyData.currentUser!.clientId;

                                final isSelected = (selectedMemberState.isMeSelected && isCurrentUser)
                                    ? true
                                    : selectedMemberState.displayName == member.clientName;

                                return _buildFamilyOption(
                                  dialogContext,
                                  ref,
                                  AppStrings.curr_user,
                                  member.clientName,
                                  isSelected,
                                      () {
                                    Navigator.pop(dialogContext);
                                    if (isCurrentUser) {
                                      ref.read(selectedMemberProvider.notifier).selectMe();
                                      onUserChanged?.call(clientIds: []);
                                    } else {
                                      ref.read(selectedMemberProvider.notifier)
                                          .selectMember(member.clientId, member.clientName);
                                      onUserChanged?.call(clientIds: [member.clientId]);
                                    }
                                  },
                                );
                              }).toList(),
                            ],
                          );
                        },
                        loading: () => _buildShimmerFamilyList(scrollController),
                        error: (err, _) => _buildFamilyErrorState(ref, scrollController),
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

  Widget _buildFamilyOption(
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

  Widget _buildShimmerFamilyList(ScrollController scrollController) {
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

  Widget _buildFamilyErrorState(WidgetRef ref, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Connection Error'),
              const SizedBox(height: 8),
              const Text(
                'Unable to load family members',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(familyMembersProvider.notifier).fetchFamilyMembers();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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

  Widget _buildMetric(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          '₹${_formatCurrency(value)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, double value, double? percentage) {
    final isValuePositive = value >= 0;

    // Determine if the percentage is positive for its own styling
    final isPercentagePositive = percentage != null && percentage >= 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Row(
          children: [
            Text(
              '₹${_formatCurrency(value)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                // The value's color can be different from the percentage's color
                color: isValuePositive ? Colors.green : Colors.red,
              ),
            ),
            if (percentage != null) ...[
              const SizedBox(width: 8),
              // CHANGE: Wrap Text in a Container with conditional decoration
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  // Use light green for positive, light red for negative
                  color: (isPercentagePositive ? Colors.green : Colors.red)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPercentagePositive ? '+' : ''}${percentage.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    // Use dark green for positive, dark red for negative
                    color: isPercentagePositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,###.##');
    return formatter.format(amount);
  }
}