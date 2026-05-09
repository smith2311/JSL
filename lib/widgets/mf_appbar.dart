// MutualFundsAppBar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jhaveri_jsl_app/core/config/env.dart';
import '../constants/strings.dart';
import '../widgets/bottom_filter_mf.dart';

class MutualFundsAppBar extends ConsumerStatefulWidget {
  final String title;
  final Function(Map<String, Set<String>> filters) onFiltersApplied;

  const MutualFundsAppBar({
    super.key,
    required this.title,
    required this.onFiltersApplied,
  });

  @override
  ConsumerState<MutualFundsAppBar> createState() => _MutualFundsAppBarState();
}

class _MutualFundsAppBarState extends ConsumerState<MutualFundsAppBar> {
  bool _hasAppliedFilters = false;
  final String baseUrl = EnvConfig.apiBaseUrl;
  Map<String, Set<String>> _currentFilters = {};

  /// Opens the bottom sheet filter
  Future<void> _openFilters(BuildContext context) async {
    debugPrint("\n🔧 [MutualFundsAppBar] Opening filter dialog");
    debugPrint("🌐 Base URL: $baseUrl");
    debugPrint("📊 Current filters before opening:");
    _currentFilters.forEach((key, value) {
      if (value.isNotEmpty) {
        debugPrint("   $key: $value");
      }
    });

    final result = await showModalBottomSheet<Map<String, Set<String>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BottomFilterMF(
        apiBaseUrl: baseUrl,
        initialAppliedFilters: _currentFilters,
      ),
    );

    debugPrint("📤 [Filter Dialog] Result received");

    if (result != null) {
      debugPrint("✅ [Filter Dialog] New filters applied:");

      // Debug the received filters
      result.forEach((category, filterSet) {
        if (filterSet.isNotEmpty) {
          debugPrint("   📌 $category: $filterSet (${filterSet.length} items)");
        } else {
          debugPrint("   📌 $category: (empty)");
        }
      });

      // Check if filters actually changed
      bool filtersChanged = false;
      if (_currentFilters.keys.length != result.keys.length) {
        filtersChanged = true;
      } else {
        for (var key in result.keys) {
          final currentSet = _currentFilters[key] ?? <String>{};
          final newSet = result[key] ?? <String>{};
          if (currentSet.length != newSet.length || !currentSet.containsAll(newSet)) {
            filtersChanged = true;
            break;
          }
        }
      }

      debugPrint("🔄 Filters changed: $filtersChanged");

      // Count total applied filters safely
      final totalFilters = result.values.fold<int>(0, (sum, set) => sum + set.length);
      debugPrint("🔢 Total filter count: $totalFilters");

      // Update red dot visibility
      setState(() {
        _hasAppliedFilters = result.values.any((set) => set.isNotEmpty);
        _currentFilters = Map<String, Set<String>>.from(result.map(
              (key, value) => MapEntry(key, Set<String>.from(value)),
        ));
      });

      debugPrint("🔴 Red dot visible: $_hasAppliedFilters");
      debugPrint("📡 Calling onFiltersApplied callback...");

      widget.onFiltersApplied(result);

      debugPrint("✅ [Filter Dialog] Processing complete");

    } else {
      debugPrint("❌ [Filter Dialog] No result (user cancelled)");
    }
  }

  /// Back button behavior using GoRouter
  void _handleBack(BuildContext context) {
    debugPrint("🔙 [Navigation] Back button pressed");

    final router = GoRouter.of(context);
    if (router.canPop()) {
      debugPrint("📱 [Navigation] Popping to previous screen");
      router.pop(); // Go back to previous screen in stack
    } else {
      debugPrint("🏠 [Navigation] No previous screen, going to /discover");
      router.go('/discover'); // Fallback if no previous screen
    }
  }

  @override
  void initState() {
    super.initState();
    debugPrint("🎬 [MutualFundsAppBar] Initialized with title: '${widget.title}'");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 16, right: 16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => _handleBack(context),
            child: SvgPicture.asset(
              AppStrings.back_icon,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // Debug filter count badge (optional - remove in production)
          if (_hasAppliedFilters)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Text(
                '${_currentFilters.values.map((s) => s.length).reduce((a, b) => a + b)}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),

          // Filter Button with Red Dot
          GestureDetector(
            onTap: () {
              debugPrint("🔧 [UI] Filter button tapped");
              _openFilters(context);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  AppStrings.filter,
                  width: 24,
                  height: 24,
                ),
                if (_hasAppliedFilters)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}