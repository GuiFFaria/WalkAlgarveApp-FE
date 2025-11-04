import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/screens/homepage_screen.dart';
import 'package:walk_algarve_app/views/screens/landingpage_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadToken();

    // ⚡ Verifica conexão com a internet
    bool isOnline = true;
    try {
      final result = await InternetAddress.lookup('example.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        isOnline = false;
      }
    } catch (_) {
      isOnline = false;
    }

    await Future.delayed(const Duration(milliseconds: 800)); // Pequeno delay

    if (authProvider.isLoggedIn) {
      // Mesmo offline, o token guardado permite entrar
      print("User is logged in, navigating to HomepageScreen");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomepageScreen()),
      );
    } else {
      // Se não há token, mas está offline — mostra aviso
      if (!isOnline && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem conexão — precisa fazer login online primeiro.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LandingpageScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1BA6A1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              'A carregar...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
