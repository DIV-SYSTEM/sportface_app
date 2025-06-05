import 'package:flutter/material.dart';
import 'screen/home_screen.dart';
import 'screen/auth_screen.dart';

void main() {
  runApp(const SportCompanionApp());
}

class SportCompanionApp extends StatelessWidget {
  const SportCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Companion Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: SafeArea(
        //child: HomeScreen(initialUser: "Demo User"),
        child: AuthScreen(),
      ),
    );
  }
}