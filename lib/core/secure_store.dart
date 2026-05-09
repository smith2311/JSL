import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = "auth_access_token";
  static const _refreshTokenKey = "auth_refresh_token";
  static const _expiryKey = "auth_expiry";

  static Future<void> saveToken({
    required String accessToken,
    String? expiry,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (expiry != null) await _storage.write(key: _expiryKey, value: expiry);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<TokenData?> getTokenData() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiry = await _storage.read(key: _expiryKey);

    if (accessToken == null) return null;
    return TokenData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
    );
  }

  static Future<bool> isTokenExpired() async {
    final expiry = await _storage.read(key: _expiryKey);
    if (expiry == null) return true;

    try {
      final expiryDate = DateTime.parse(expiry);
      return DateTime.now().isAfter(expiryDate);
    } catch (_) {
      return true;
    }
  }

  /// ✅ Add this to fix your HttpClient error
  static Future<void> setToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiryKey);
  }
}

class TokenData {
  final String accessToken;
  final String? refreshToken;
  final String? expiry;

  TokenData({
    required this.accessToken,
    this.refreshToken,
    this.expiry,
  });
}