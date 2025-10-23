import 'package:flutter/material.dart';
import 'package:walk_algarve_app/views/components/navbar_widget.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Walk Algarve App', style: TextStyle(fontSize: 18)),

          centerTitle: true, 
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          
          child: Text('Welcome to Walk Algarve!'),
        ),

        bottomNavigationBar: NavbarWidget(),
      );
  }
}