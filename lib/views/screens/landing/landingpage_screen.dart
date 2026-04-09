import 'package:flutter/material.dart';
import 'package:walk_algarve_app/views/screens/login/login_screen.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

class LandingpageScreen extends StatefulWidget {
  const LandingpageScreen({super.key});

  @override
  State<LandingpageScreen> createState() => _LandingpageScreenState();
}

class _LandingpageScreenState extends State<LandingpageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [ Image.asset(
            'assets/images/walk_algarve_logo.jpg', 
            width: 300
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ));
            },
            child: Text(AppLocalizations.of(context)!.login,),
          ),
          ]
        ),

    );
  }
}
