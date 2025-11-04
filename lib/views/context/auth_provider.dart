import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  String? _refreshToken;

  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// 🔹 Carrega tokens do SharedPreferences ao iniciar
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');

    print("🔄 [AuthProvider] Loading saved tokens...");
    if (_token != null) {
      print("✅ Access token found: ${_token!.substring(0, 15)}...");
      if (_isTokenExpired(_token!)) {
        print("⚠️ Access token expired. Attempting refresh...");
        await _refreshAccessToken();
      } else {
        print("🟢 Access token is still valid.");
      }
    } else {
      print("❌ No access token found.");
    }

    notifyListeners();
  }

  /// 🔹 Guarda tokens após login
  Future<void> setToken(String accessToken, {String? refreshToken}) async {
    _token = accessToken;
    _refreshToken = refreshToken ?? _refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _token!);
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }

    print("💾 Tokens saved to SharedPreferences.");
    notifyListeners();
  }

  /// 🔹 Remove tokens (logout)
  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    print("🚪 Logged out, tokens cleared.");
    notifyListeners();
  }

  /// 🔹 Verifica se o token expirou
  bool _isTokenExpired(String token) {
    print("⏱️ Checking if token is expired...");
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        print("❌ Invalid token format.");
        return true;
      }

      final payload =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'];
      print("🧾 Token payload exp: $exp");

      if (exp == null) {
        print("⚠️ No expiration time found in token.");
        return true;
      }

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();

      print("🕒 Token expires at: $expiryDate");
      print("🕒 Current time: $now");

      final expired = now.isAfter(expiryDate);
      print(expired ? "❌ Token expired." : "✅ Token still valid.");
      return expired;
    } catch (e) {
      print("❌ Error decoding token: $e");
      return true;
    }
  }

  /// 🔹 Atualiza o access token usando o refresh token
  Future<void> _refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      print("❌ No refresh token available. User must log in again.");
      await logout();
      return;
    }

    final baseUrl = dotenv.env['API_BASE_URL']!;
    final url = Uri.parse("$baseUrl/auth/token/refresh/");
    print("🔄 Attempting token refresh at: $url");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': _refreshToken}),
      );

      print("📡 Refresh response status: ${response.statusCode}");
      print("📦 Refresh response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          print("✅ Token successfully refreshed.");
          await setToken(newAccessToken);
        } else {
          print("⚠️ No access token in refresh response.");
          await logout();
        }
      } else {
        print("❌ Failed to refresh token: ${response.body}");
        await logout();
      }
    } catch (e) {
      print("❌ Exception while refreshing token: $e");
      await logout();
    }
  }
}
