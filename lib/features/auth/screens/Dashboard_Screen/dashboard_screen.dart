import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/constants/strings.dart';
import '../../../../../core/network/connection.dart';
import '../../../../widgets/Dashboard/Tools/tools_panel.dart';
import '../../../../../providers/user_provider.dart';
import '../../../../../providers/family_members_provider.dart';
import '../../../../../providers/portfolio_provider.dart';
import '../../../../../widgets/Dashboard/collection_panel.dart';
import '../../../../../widgets/horizontal_card_list.dart';
import '../../../../../widgets/Dashboard/market_marquee_listview.dart';
import '../../../../../widgets/Dashboard/success_status_hero.dart';
import '../../../../../widgets/Dashboard/app_top_bar.dart';
import '../../../../../widgets/portfolio_card.dart';
import '../../data/models/portfolio.dart';
import '../../data/repo/user_repo.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasShownReconnection = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Fetch user profile
    await ConnectionHelper.executeWithAutoRetry(
      operation: () async {
        final currentUser = ref.read(userProvider);
        if (currentUser.userName == 'User' || currentUser.userName.isEmpty) {
          await _fetchUserProfile();
        }
      },
      onSuccess: () {
        if (_isRetrying && mounted) {
          _showReconnectedNotification();
          _isRetrying = false;
        }
      },
      onRetrying: () {
        _isRetrying = true;
      },
    );

    // Fetch family members
    await ConnectionHelper.executeWithAutoRetry(
      operation: () => ref.read(familyMembersProvider.notifier).fetchFamilyMembers(),
      onSuccess: () {
        if (_isRetrying && mounted) {
          _showReconnectedNotification();
          _isRetrying = false;
        }
      },
      onRetrying: () {
        _isRetrying = true;
      },
    );

    // Fetch portfolio data
    final selectedMemberState = ref.read(selectedMemberProvider);
    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds.cast<int>();

    await ConnectionHelper.executeWithAutoRetry(
      operation: () async {
        await Future.wait([
          ref.read(portfolioProvider.notifier).fetchPortfolio(clientIds: clientIds),
          ref.read(xirrProvider.notifier).fetchXirr(clientIds: clientIds),
        ]);
      },
      onSuccess: () {
        if (_isRetrying && mounted) {
          _showReconnectedNotification();
          _isRetrying = false;
        }
      },
      onRetrying: () {
        _isRetrying = true;
      },
    );
  }

  void _showReconnectedNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              'Connected',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _fetchUserProfile() async {
    final userRepo = UserRepo();
    final profileData = await userRepo.fetchUserProfile();

    if (profileData != null && mounted) {
      final userName = profileData['user_name'] ?? profileData['name'] ?? 'User';
      final avatarUrl = profileData['image_url'] ?? profileData['avatar'];

      ref.read(userProvider.notifier).setUserName(userName);
      if (avatarUrl != null) {
        ref.read(userProvider.notifier).setAvatar(avatarUrl);
      }
    }
  }

  void _navigateToPopularFunds(BuildContext context) {
    debugPrint("📱 [DashboardScreen] Navigating to popular funds");
    try {
      context.push('/popular-funds');
    } catch (e) {
      debugPrint("⚠️ [DashboardScreen] Navigation error: $e");
      context.push('/popular-funds');
    }
  }

  void _navigateToPortfolio(
      BuildContext context, SelectedMemberState selectedMemberState) {
    debugPrint(
        "📱 [DashboardScreen] Navigating to portfolio for: ${selectedMemberState.displayName}");

    final clientIds = selectedMemberState.isMeSelected
        ? <int>[]
        : selectedMemberState.clientIds;

    try {
      context.push('/portfolio', extra: {
        'clientIds': clientIds,
        'displayName': selectedMemberState.displayName,
      });
    } catch (e) {
      debugPrint("⚠️ [DashboardScreen] Portfolio navigation error: $e");
      context.go('/portfolio');
    }
  }

  void _onFamilyMemberChanged({List<int>? clientIds}) {
    ConnectionHelper.executeWithAutoRetry(
      operation: () async {
        await Future.wait([
          ref.read(portfolioProvider.notifier).fetchPortfolio(clientIds: clientIds),
          ref.read(xirrProvider.notifier).fetchXirr(clientIds: clientIds),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final familyMembersState = ref.watch(familyMembersProvider);
    final portfolioState = ref.watch(portfolioProvider);
    final xirrState = ref.watch(xirrProvider);
    final selectedMemberState = ref.watch(selectedMemberProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section with Blue Background
              Container(
                width: double.infinity,
                color: const Color(0xFF0060A6),
                child: Column(
                  children: [
                    // AppTopBar with white icons
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: AppTopBar(
                        userName: user.userName,
                        avatarUrl: user.avatarUrl,
                        onUserTap: () => context.push('/user_profile'),
                        iconColor: Colors.white,
                      ),
                    ),

                    // Portfolio Card - Always show shimmer on error
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: familyMembersState.when(
                        data: (familyData) {
                          final memberCount = familyData.allMembers.length;
                          if (memberCount > 1) {
                            return _buildPortfolioCardWithState(
                              portfolioState,
                              xirrState,
                              selectedMemberState,
                              true,
                            );
                          } else {
                            return portfolioState.when(
                              data: (portfolio) {
                                if (portfolio.currentValue == 0) {
                                  return _buildKycPrompt();
                                } else {
                                  return PortfolioCard(
                                    portfolio: portfolio,
                                    xirr: xirrState.maybeWhen(
                                      data: (v) => v,
                                      orElse: () => null,
                                    ),
                                    displayTitle: _getPortfolioTitle(selectedMemberState),
                                    showFamilySwitcher: false,
                                    showOneDayReturn: false,
                                    useCompactLayout: true,
                                  );
                                }
                              },
                              loading: () => const PortfolioCard(
                                displayTitle: 'Loading...',
                                isLoading: true,
                              ),
                              error: (err, _) => const PortfolioCard(
                                displayTitle: 'Loading...',
                                isLoading: true,
                              ),
                            );
                          }
                        },
                        loading: () => const PortfolioCard(
                          displayTitle: 'Loading...',
                          isLoading: true,
                        ),
                        error: (err, _) => const PortfolioCard(
                          displayTitle: 'Loading...',
                          isLoading: true,
                        ),
                      ),
                    ),

                    // View Portfolio Link
                    familyMembersState.maybeWhen(
                      data: (familyData) => familyData.allMembers.isNotEmpty,
                      orElse: () => false,
                    )
                        ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                      child: GestureDetector(
                        onTap: () => _navigateToPortfolio(
                            context, selectedMemberState),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'View Portfolio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    )
                        : const SizedBox(height: 30),
                  ],
                ),
              ),

              const SizedBox(height: 2),
              const MarketMarqueeList(),
              const SizedBox(height: 8),

              // Popular Funds
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.pop_funds,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          GestureDetector(
                            onTap: () => _navigateToPopularFunds(context),
                            child: const Text(
                              AppStrings.view_all_funds,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 16),
                child: HorizontalCardList(
                  previousRoute: '/dashboard',
                ),
              ),

              // Collections + Tools
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      AppStrings.dashboard_collections,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const CollectionsPanel(),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.tools,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    const ToolsPanel(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycPrompt() {
    return SuccessStatusHero(
      imagePath: AppStrings.img_complete_kyc,
      title: AppStrings.comp_kyc_lbl,
      subtitle: AppStrings.comp_kyc_subtitle,
      ctaText: AppStrings.inv_now,
      onPressed: () => _navigateToPopularFunds(context),
    );
  }

  Widget _buildPortfolioCardWithState(
      AsyncValue<PortfolioModel> portfolioState,
      AsyncValue<double> xirrState,
      SelectedMemberState selectedMemberState,
      bool showFamilySwitcher,
      ) {
    return portfolioState.when(
      data: (portfolio) => PortfolioCard(
        portfolio: portfolio,
        xirr: xirrState.maybeWhen(data: (v) => v, orElse: () => null),
        displayTitle: _getPortfolioTitle(selectedMemberState),
        showFamilySwitcher: showFamilySwitcher,
        showOneDayReturn: false,
        onUserChanged: _onFamilyMemberChanged,
        useCompactLayout: true,
      ),
      loading: () => const PortfolioCard(
        displayTitle: 'Loading...',
        isLoading: true,
      ),
      error: (err, _) => const PortfolioCard(
        displayTitle: 'Loading...',
        isLoading: true,
      ),
    );
  }

  String _getPortfolioTitle(SelectedMemberState state) {
    if (state.isMeSelected) return AppStrings.my_inv;
    if (state.displayName == 'All') return AppStrings.my_fam_inv;
    return state.displayName;
  }
}