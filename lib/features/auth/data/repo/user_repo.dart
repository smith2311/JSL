import 'package:jhaveri_jsl_app/core/network/http_client.dart';
import 'package:jhaveri_jsl_app/features/auth/data/repo/auth_repo.dart';
class UserRepo {
  final HttpClient _client = HttpClient();
  final AuthRepo _authRepo = AuthRepo();

  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final token = await _authRepo.getValidToken();

    if (token == null) {
      print("❌ Not logged in or token expired");
      return null;
    }

    final response = await _client.get(
      "/user/profile",
      headers: {"Authorization": "Bearer $token"},
    );

    print("✅ Profile: $response");
    return response;
  }
}