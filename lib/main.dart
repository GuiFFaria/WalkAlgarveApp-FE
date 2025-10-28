import 'package:flutter/material.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/screens/homepage_screen.dart';
import 'package:walk_algarve_app/views/screens/landingpage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  await authProvider.loadToken();

  runApp(
    ChangeNotifierProvider(
      create: (_) => authProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      title: 'Walk Algarve App',
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            // Se já estiver logado, ir direto para a tela principal
            return const HomepageScreen();
          } else {
            return const LandingpageScreen();
          }
        },
      ),
    );
  }
}
