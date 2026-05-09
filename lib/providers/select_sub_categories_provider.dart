import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'jhaveri_picks_provider.dart';

final selectedSubCategoriesProvider =
StateNotifierProvider<SelectedSubCategoriesNotifier, List<int>>(
      (ref) => SelectedSubCategoriesNotifier(ref),
);

class SelectedSubCategoriesNotifier extends StateNotifier<List<int>> {
  final Ref ref;
  SelectedSubCategoriesNotifier(this.ref) : super([]) {
    // Listen to changes and fetch funds automatically
    addListener((selectedIds) {
      ref.read(jhaveriPicksProvider.notifier).fetchFunds();
    });
  }

  void update(List<int> ids) => state = ids;
}