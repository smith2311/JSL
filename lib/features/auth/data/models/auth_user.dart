import 'package:jhaveri_jsl_app/core/config/env.dart';

class AuthRepo {
  Future<void> login(String email, String password) async {
    final url = "${EnvConfig.apiBaseUrl}/login";

    // now use url in your http client
    print("Calling API: $url");
  }
}