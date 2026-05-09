import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../core/token_helper.dart';
import 'jhaveri_picks_repo_provider.dart';
import 'jhaveri_picks_provider.dart';

final subCategoriesProvider = AsyncNotifierProvider<SubCategoryNotifier, List<Map<String, dynamic>>>(
  SubCategoryNotifier.new,
);

class SubCategoryNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  static const int allCategoryId = -1;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    await fetchSubCategories();
    return state.value ?? [
      {"id": allCategoryId, "name": "All"}
    ];
  }

  Future<void> fetchSubCategories() async {
    state = const AsyncValue.loading();
    try {
      final token = await TokenHelper.getValidToken();
      if (token == null) {
        state = AsyncValue.data([
          {"id": allCategoryId, "name": "All"}
        ]);
        return;
      }

      final repo = ref.read(jhaveriPicksRepoProvider);
      final data = await repo.fetchSubCategories();

      state = AsyncValue.data([
        {"id": allCategoryId, "name": "All"},
        ...data
      ]);

      // Trigger funds fetch after categories load
      ref.read(jhaveriPicksProvider.notifier).fetchFunds();
    } catch (e) {
      debugPrint("❌ Error fetching sub-categories: $e");
      state = AsyncValue.data([
        {"id": allCategoryId, "name": "All"}
      ]);
    }
  }
}

/// Selected sub-category IDs (multi-select)
final selectedSubCategoriesProvider = StateProvider<List<int>>((ref) => []);