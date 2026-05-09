// providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User model
class User {
  final String userName;
  final String? avatarUrl;
  final String? token;

  User({
    required this.userName,
    this.avatarUrl,
    this.token,
  });

  User copyWith({
    String? userName,
    String? avatarUrl,
    String? token,
  }) {
    return User(
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      token: token ?? this.token,
    );
  }
}

// Riverpod StateNotifier for user
class UserNotifier extends StateNotifier<User> {
  UserNotifier() : super(User(userName: 'User')) {
    // Load user data when provider initializes
    _loadUserData();
  }

  // ✅ Load persisted user data on app start
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name');
      final avatarUrl = prefs.getString('avatar_url');
      final token = prefs.getString('user_token');

      // Only update if we have saved data
      if (userName != null) {
        state = User(
          userName: userName,
          avatarUrl: avatarUrl,
          token: token,
        );
        print('✅ User data loaded: $userName');
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  // ✅ Save username to both state and SharedPreferences
  Future<void> setUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      state = state.copyWith(userName: name);
      print('✅ Username saved: $name');
    } catch (e) {
      print('❌ Error saving username: $e');
      // Still update state even if save fails
      state = state.copyWith(userName: name);
    }
  }

  // ✅ Save avatar to both state and SharedPreferences
  Future<void> setAvatar(String? avatarUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (avatarUrl != null) {
        await prefs.setString('avatar_url', avatarUrl);
      } else {
        await prefs.remove('avatar_url');
      }
      state = state.copyWith(avatarUrl: avatarUrl);
      print('✅ Avatar saved: $avatarUrl');
    } catch (e) {
      print('❌ Error saving avatar: $e');
      // Still update state even if save fails
      state = state.copyWith(avatarUrl: avatarUrl);
    }
  }

  // ✅ Save token to both state and SharedPreferences
  Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', token);
      state = state.copyWith(token: token);
      print('✅ Token saved');
    } catch (e) {
      print('❌ Error saving token: $e');
      // Still update state even if save fails
      state = state.copyWith(token: token);
    }
  }

  // ✅ Clear all user data on logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('avatar_url');
      await prefs.remove('user_token');
      state = User(userName: 'User', avatarUrl: null, token: null);
      print('✅ User data cleared');
    } catch (e) {
      print('❌ Error clearing user data: $e');
      // Still reset state even if clear fails
      state = User(userName: 'User', avatarUrl: null, token: null);
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});