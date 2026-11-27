import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/helpers/trail_cache.dart';

enum _Renewal { renewed, rejected, unavailable }

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

  /// 🔹 Remove tokens e dados da conta (logout)
  Future<void> logout() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    await prefs.remove('cached_user_zones');
    await TrailCache.clear();
    print("🚪 Logged out, tokens cleared.");
    notifyListeners();
  }

  /// 🔹 Verifica se o token expirou
  bool _isTokenExpired(String token, {Duration within = Duration.zero}) {
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

      final expired = now.add(within).isAfter(expiryDate);
      print(expired ? "❌ Token expired." : "✅ Token still valid.");
      return expired;
    } catch (e) {
      print("❌ Error decoding token: $e");
      return true;
    }
  }

  /// 🔹 Atualiza o access token usando o refresh token
  /// A session that only couldn't be renewed, as when offline, is kept.
  Future<void> _refreshAccessToken() async {
    if (await _renew() == _Renewal.rejected) await logout();
  }

  /// Renews an access token that has expired or is about to, and says whether
  /// there is one to use. For calls the API answers without a 401.
  Future<bool> ensureFreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    const margin = Duration(minutes: 1);
    if (token != null && !_isTokenExpired(token, within: margin)) return true;
    return tryRefreshAccessToken();
  }

  /// Renews the access token without signing out on failure, for callers that
  /// must not interrupt the user, such as a walk in progress.
  Future<bool> tryRefreshAccessToken() async =>
      await _renew() == _Renewal.renewed;

  Future<_Renewal> _renew() async {
    // Login writes the refresh token straight to storage, so read it from there.
    final prefs = await SharedPreferences.getInstance();
    final refresh = prefs.getString('refresh_token');
    if (refresh == null || refresh.isEmpty) return _Renewal.rejected;

    final url = Uri.parse("${dotenv.env['API_BASE_URL']!}/auth/token/refresh/");

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print("❌ Failed to refresh token: ${response.statusCode}");
        return response.statusCode == 401
            ? _Renewal.rejected
            : _Renewal.unavailable;
      }

      final access = jsonDecode(response.body)['access'];
      if (access is! String || access.isEmpty) return _Renewal.unavailable;

      await setToken(access, refreshToken: refresh);
      return _Renewal.renewed;
    } catch (e) {
      print("❌ Exception while refreshing token: $e");
      return _Renewal.unavailable;
    }
  }
}
