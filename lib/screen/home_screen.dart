import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/circular_avatar.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(Constants.appName),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularAvatar(imageUrl: user?.imageUrl),
            ),
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to SportFace!')),
    );
  }
}
