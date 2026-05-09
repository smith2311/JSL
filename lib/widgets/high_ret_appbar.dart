import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/strings.dart';
import '../core/config/env.dart';
import 'bottom_filter_mf.dart';

class CollectionsCategoryDetailScreenAppBar extends ConsumerStatefulWidget {
  final String title;
  final Function(Map<String, Set<String>> filters) onFiltersApplied;
  final VoidCallback onBack;

  const CollectionsCategoryDetailScreenAppBar({
    super.key,
    required this.title,
    required this.onFiltersApplied,
    required this.onBack,
  });

  @override
  ConsumerState<CollectionsCategoryDetailScreenAppBar> createState() => _CollectionsCategoryDetailScreenAppBarState();
}

class _CollectionsCategoryDetailScreenAppBarState extends ConsumerState<CollectionsCategoryDetailScreenAppBar> {
  bool _hasAppliedFilters = false;
  Map<String, Set<String>> _currentFilters = {};

  Future<void> _openFilters(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, Set<String>>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BottomFilterMF(
        apiBaseUrl: EnvConfig.apiBaseUrl,
        initialAppliedFilters: _currentFilters,
      ),
    );

    if (result != null) {
      setState(() {
        _hasAppliedFilters = result.values.any((set) => set.isNotEmpty);
        _currentFilters = Map<String, Set<String>>.from(result.map(
              (key, value) => MapEntry(key, Set<String>.from(value)),
        ));
      });
      widget.onFiltersApplied(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 35, left: 16, right: 16),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: widget.onBack,
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

          // Filter Count Badge
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
            onTap: () => _openFilters(context),
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