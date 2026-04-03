import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/screens/zones_list_screen.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

import 'package:walk_algarve_app/views/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _loginUser() async {
    print("🔐 [Login] Login button pressed");
    final translations = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    String baseUrl = dotenv.env['API_BASE_URL']!;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(translations.fill_all_fields)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("$baseUrl/auth/login/");
      print("🌍 Sending login request to: $url");

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print("📡 Response status: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final accessToken = data['access'];
        final refreshToken = data['refresh'];
        final user = data['user'];

        print("✅ Access token: ${accessToken != null ? 'OK' : 'null'}");
        print("🔄 Refresh token: ${refreshToken != null ? 'OK' : 'null'}");
        print("👤 User: $user");

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception("Access token not found in response!");
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', accessToken);
        await prefs.setString('refresh_token', refreshToken ?? '');
        await prefs.setString('user', jsonEncode(user));
        await Provider.of<AuthProvider>(context, listen: false).setToken(accessToken);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(translations.login_success)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ZonesListScreen()),
        );
      } else {
        final data = jsonDecode(response.body);
        String errorMessage = data['detail'] ?? translations.login_failed;
        print("❌ Login error: $errorMessage");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e, stack) {
      print("❌ Exception during login: $e");
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${translations.login_failed}: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/walk_algarve_logo.jpg',
                width: 150,
              ),
              const SizedBox(height: 30),
              Text(
                translations.login,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Email Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: translations.email_label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Password Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: translations.password_label,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              SizedBox(
                width: 150,
                height: 40,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(translations.login),
                ),
              ),
              const SizedBox(height: 30),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(translations.account),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      translations.register,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
