import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:walk_algarve_app/views/context/auth_provider.dart';
import 'package:walk_algarve_app/views/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🔄 Loading .env file...");
  await dotenv.load(fileName: ".env");
  print("✅ .env loaded successfully!");

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walk Algarve',
      debugShowCheckedModeBanner: false,

      //
      // 🌈 Tema principal baseado na paleta "Algarve Explorer"
      //
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF1BA6A1), // Azul turquesa — cor principal
          onPrimary: Colors.white,
          secondary: Color(0xFFF4A261), // Laranja dourado
          onSecondary: Colors.white,
          error: Color(0xFFE63946),
          onError: Colors.white,
          surface: Color(0xFFFAF8F3),
          onSurface: Color(0xFF2F2F2F),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1BA6A1),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF2F2F2F),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF4A261),
          foregroundColor: Colors.white,
        ),
      ),

      //
      // 🌙 Tema escuro opcional — modo "noturno" suave
      //
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF264653),
          secondary: Color(0xFFF4A261),
          surface: Color(0xFF1C1C1C),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,

      //
      // 👇 Novo ponto inicial (SplashScreen)
      //
      home: const SplashScreen(),
    );
  }
}
