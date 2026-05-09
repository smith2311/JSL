import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/mandates.dart';
import '../features/auth/data/repo/mandates_repo.dart';

/// ✅ Repository Provider (Singleton)
final mandateRepositoryProvider = Provider<MandateRepository>((ref) {
  return MandateRepository();
});

/// ✅ Mandates StateNotifier Provider (using `family` for per-client control)
final mandatesProvider = StateNotifierProvider.family<
    MandatesNotifier,
    AsyncValue<List<Mandate>>,
    String>(
      (ref, clientCode) {
    final repo = ref.read(mandateRepositoryProvider);
    return MandatesNotifier(repo, clientCode);
  },
);

/// ✅ Mandates Notifier — Handles Fetching + Refresh Logic
class MandatesNotifier extends StateNotifier<AsyncValue<List<Mandate>>> {
  final MandateRepository _repository;
  final String clientCode;

  MandatesNotifier(this._repository, this.clientCode)
      : super(const AsyncValue.loading()) {
    _fetchMandates();
  }

  /// 🔄 Fetch all mandates for the given client
  Future<void> _fetchMandates() async {
    debugPrint('[MandatesNotifier] 🔄 Fetching mandates for $clientCode...');
    state = const AsyncValue.loading();

    try {
      final mandates = await _repository.fetchAllMandates(
        clientCode: clientCode,
      );

      state = AsyncValue.data(mandates);
      debugPrint('[MandatesNotifier] ✅ Loaded ${mandates.length} mandates');
    } catch (error, stack) {
      debugPrint('[MandatesNotifier] ❌ Error: $error');
      state = AsyncValue.error(error, stack);
    }
  }

  /// 🔁 Public refresh method
  Future<void> refresh() async {
    await _fetchMandates();
  }
}