import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/data/models/family_member.dart';
import '../features/auth/data/repo/family_member_repo.dart';

/// Repository Provider
final familyMemberRepositoryProvider = Provider<FamilyMemberRepository>((ref) {
  return FamilyMemberRepository();
});

/// Main Family Members Provider
final familyMembersProvider =
StateNotifierProvider<FamilyMembersNotifier, AsyncValue<FamilyMembersState>>((ref) {
  return FamilyMembersNotifier(ref.read(familyMemberRepositoryProvider));
});

/// State Model for all family members
class FamilyMembersState {
  final List<FamilyMember> allMembers;
  final FamilyMember? currentUser;
  final List<FamilyMember> otherMembers;

  FamilyMembersState({
    required this.allMembers,
    this.currentUser,
    required this.otherMembers,
  });
}

/// State Notifier for managing family members list
class FamilyMembersNotifier extends StateNotifier<AsyncValue<FamilyMembersState>> {
  final FamilyMemberRepository repository;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int _maxRetries = 5;
  static const Duration _retryInterval = Duration(seconds: 5);

  FamilyMembersNotifier(this.repository) : super(const AsyncValue.loading()) {
    fetchFamilyMembers();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchFamilyMembers() async {
    state = const AsyncValue.loading();

    try {
      final members = await repository.fetchFamilyMembers();

      // Identify current user
      final currentUser = members.firstWhere(
            (m) => m.isCurrentUser,
        orElse: () => members.first,
      );

      final otherMembers = members.where((m) => !m.isCurrentUser).toList();

      state = AsyncValue.data(
        FamilyMembersState(
          allMembers: members,
          currentUser: currentUser,
          otherMembers: otherMembers,
        ),
      );

      // Reset retry count on success
      _retryCount = 0;
      _retryTimer?.cancel();

      debugPrint('✅ Family members fetched successfully: ${members.length} members');
    } on SocketException catch (e, st) {
      debugPrint('🌐 Network error fetching family members: $e');
      _handleError(e, st);
    } on TimeoutException catch (e, st) {
      debugPrint('⏱️ Timeout error fetching family members: $e');
      _handleError(e, st);
    } catch (e, st) {
      debugPrint('❌ Error fetching family members: $e');
      _handleError(e, st);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = AsyncValue.error(error, stackTrace);

    // Schedule automatic retry
    if (_retryCount < _maxRetries) {
      _retryCount++;
      final delay = _retryInterval * _retryCount;

      debugPrint('🔄 Retrying family members fetch in ${delay.inSeconds}s (Attempt $_retryCount/$_maxRetries)');

      _retryTimer?.cancel();
      _retryTimer = Timer(delay, () {
        if (mounted) {
          fetchFamilyMembers();
        }
      });
    } else {
      debugPrint('⛔ Max retry attempts reached for family members fetch');
    }
  }

  void resetRetry() {
    _retryCount = 0;
    _retryTimer?.cancel();
  }
}

/// Selected Member Provider (to track user selection)
final selectedMemberProvider =
StateNotifierProvider<SelectedMemberNotifier, SelectedMemberState>((ref) {
  return SelectedMemberNotifier();
});

/// State Model for currently selected member
class SelectedMemberState {
  final bool isMeSelected;
  final List<int> clientIds;
  final String displayName;

  SelectedMemberState({
    required this.isMeSelected,
    required this.clientIds,
    required this.displayName,
  });

  SelectedMemberState copyWith({
    bool? isMeSelected,
    List<int>? clientIds,
    String? displayName,
  }) {
    return SelectedMemberState(
      isMeSelected: isMeSelected ?? this.isMeSelected,
      clientIds: clientIds ?? this.clientIds,
      displayName: displayName ?? this.displayName,
    );
  }
}

/// State Notifier for managing selection logic
class SelectedMemberNotifier extends StateNotifier<SelectedMemberState> {
  SelectedMemberNotifier()
      : super(
    SelectedMemberState(
      isMeSelected: true,
      clientIds: [],
      displayName: 'Me',
    ),
  );

  void selectMe() {
    state = SelectedMemberState(
      isMeSelected: true,
      clientIds: [],
      displayName: 'Me',
    );
    debugPrint('👤 Selected: Me');
  }

  void selectAll(List<int> allClientIds) {
    state = SelectedMemberState(
      isMeSelected: false,
      clientIds: allClientIds,
      displayName: 'All',
    );
    debugPrint('👥 Selected: All (${allClientIds.length} members)');
  }

  void selectMember(int clientId, String memberName) {
    state = SelectedMemberState(
      isMeSelected: false,
      clientIds: [clientId],
      displayName: memberName,
    );
    debugPrint('👤 Selected: $memberName (ID: $clientId)');
  }
}