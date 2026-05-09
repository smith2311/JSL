import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../constants/strings.dart';
import '../../../../../core/auth_helper.dart';
import '../../../../../providers/mf_provider.dart';
import '../../../../../providers/jhaveri_picks_provider.dart';
import '../../../../../providers/watchlist_provider.dart';
import '../../../../../widgets/custom_tab_button.dart';
import '../../../../../widgets/discover_mutual_funds_section.dart';
import '../../../../../widgets/jhaveri_picks_section.dart';
import '../../../../../widgets/horizontal_card_list.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with AutomaticKeepAliveClientMixin {
  int _selectedTab = 0;
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    debugPrint("🚀 [DiscoverScreen] Initializing...");
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkAuthentication();

    // Fetch mutual funds (works without auth)
    if (mounted) {
      Future.microtask(() {
        ref.read(fundsProvider.notifier).fetchFunds(reset: true);
      });
    }

    // Fetch Jhaveri picks only if authenticated
    if (_isAuthenticated && mounted) {
      debugPrint("✅ [DiscoverScreen] User authenticated, fetching Jhaveri picks...");
      Future.microtask(() {
        ref.read(jhaveriPicksProvider.notifier).fetchFunds();
      });
    } else {
      debugPrint("⚠️ [DiscoverScreen] User not authenticated, skipping Jhaveri picks");
    }
  }

  Future<void> _checkAuthentication() async {
    try {
      final authenticated = await AuthHelper.isAuthenticated();
      if (mounted) {
        setState(() {
          _isAuthenticated = authenticated;
          _isCheckingAuth = false;
        });
      }
      debugPrint("🔐 [DiscoverScreen] Authentication status: $authenticated");
    } catch (e) {
      debugPrint("❌ [DiscoverScreen] Error checking auth: $e");
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isCheckingAuth = false;
        });
      }
    }
  }

  void _onTabChanged(int newTab) {
    if (_selectedTab != newTab) {
      setState(() => _selectedTab = newTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F5),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar - Extracted to separate widget
            const _DiscoverAppBar(),

            // Tabs - Extracted to separate widget
            _DiscoverTabs(
              selectedTab: _selectedTab,
              onTabChanged: _onTabChanged,
            ),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: _isCheckingAuth
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF0060A6),
                ),
              )
                  : IndexedStack(
                index: _selectedTab,
                children: [
                  _ExploreTab(isAuthenticated: _isAuthenticated),
                  _WatchlistTab(isAuthenticated: _isAuthenticated),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate widget for app bar to prevent rebuilds
class _DiscoverAppBar extends StatelessWidget {
  const _DiscoverAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            AppStrings.discover_title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            icon: SvgPicture.asset(
              AppStrings.search,
              height: 24,
              width: 24,
            ),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
    );
  }
}

// Separate widget for tabs to prevent rebuilds
class _DiscoverTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  const _DiscoverTabs({
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          CustomTabButton(
            label: AppStrings.discover_tab1,
            isSelected: selectedTab == 0,
            onTap: () => onTabChanged(0),
          ),
          CustomTabButton(
            label: AppStrings.discover_tab2,
            isSelected: selectedTab == 1,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

// Separate widget for explore tab
class _ExploreTab extends StatelessWidget {
  final bool isAuthenticated;

  const _ExploreTab({required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey("ExploreTab"),
      padding: EdgeInsets.zero,
      children: [
        // Most Popular Funds Header
        const _SectionHeader(
          title: AppStrings.most_pop_funds,
          actionText: AppStrings.view_all_funds,
          route: '/discover_most_popular_funds',
        ),

        // Horizontal Card List
        const Padding(
        padding: EdgeInsets.only(left: 16),
        child: HorizontalCardList(
        previousRoute: '/discover', // ✅ Add this
        ),
        ),
        const SizedBox(height: 20),

        // Authenticated content or login prompt
        if (isAuthenticated) ...[
          JhaveriPicksSection(
            title: AppStrings.discover_jhaveri_picks,
            onViewAllTap: () => context.go('/jhaveri_all_funds'),
            showShimmer: true,
            maxItems: 5,
          ),
          const SizedBox(height: 20),
          DiscoverFundsSection(
            title: AppStrings.discover_all_MF,
            maxPageSize: 5,
            onViewAllTap: () => context.go('/mutual_funds'),
          ),
          const SizedBox(height: 20),
        ] else
          const _LoginPrompt(),
      ],
    );
  }
}

// Reusable section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final String route;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          GestureDetector(
            onTap: () => context.go(route),
            child: Text(
              actionText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Separate widget for watchlist tab
class _WatchlistTab extends StatelessWidget {
  final bool isAuthenticated;

  const _WatchlistTab({required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return const _LoginRequired();
    }
    return const WatchlistFundsList();
  }
}

// Login required widget
class _LoginRequired extends StatelessWidget {
  const _LoginRequired();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            "Watchlist Requires Login",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Login to save and track your favorite funds",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0060A6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            onPressed: () => context.push('/login'),
            child: const Text("Login to Access Watchlist"),
          ),
        ],
      ),
    );
  }
}

// Login prompt widget
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                "Login to Access More Features",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Get personalized fund recommendations, detailed analytics, and save your favorite funds.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0060A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => context.push('/login'),
                child: const Text("Login Now"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}