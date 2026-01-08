import 'package:flutter/foundation.dart';

class DebugLogger {
  static const String _appTag = "[TrailApp]";

  /// ===========================
  /// INFO
  /// ===========================
  static void info(String context, String message) {
    if (!kDebugMode) return;
    debugPrint("ℹ️ $_appTag [$context] $message");
  }

  /// ===========================
  /// WARNING (não crítico)
  /// ===========================
  static void warn(String context, String message) {
    if (!kDebugMode) return;
    debugPrint("⚠️ $_appTag [$context] $message");
  }

  /// ===========================
  /// ERROR (erro tratado)
  /// ===========================
  static void error(
    String context,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (!kDebugMode) return;

    debugPrint("❌ $_appTag [$context] $message");

    if (error != null) {
      debugPrint("   ↳ Error: $error");
    }

    if (stackTrace != null) {
      debugPrint("   ↳ StackTrace:\n$stackTrace");
    }
  }
}
