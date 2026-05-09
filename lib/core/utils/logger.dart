import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    debugPrint("🟦 $message");
  }

  static void error(String message, [Object? error]) {
    debugPrint("❌ $message ${error ?? ''}");
  }
}