import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CircularAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const CircularAvatar({super.key, this.imageUrl, this.radius = 20.0});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getImage(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: const CircularProgressIndicator(),
          );
        }
        final imageUrl = snapshot.data;
        if (imageUrl == null || imageUrl.isEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: radius, color: Colors.grey[600]),
          );
        }
        try {
          if (imageUrl.startsWith('data:image')) {
            // Handle base64 image
            final base64String = imageUrl.split(',').last;
            final imageBytes = base64Decode(base64String);
            return CircleAvatar(
              radius: radius,
              backgroundImage: MemoryImage(imageBytes),
              backgroundColor: Colors.grey[300],
            );
          } else {
            // Fallback for network images (if any legacy data exists)
            return CircleAvatar(
              radius: radius,
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Colors.grey[300],
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading image: $e');
          }
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.error, size: radius, color: Colors.red),
          );
        }
      },
    );
  }

  Future<String?> _getImage() async {
    if (imageUrl != null) return imageUrl;
    // Fallback to SharedPreferences if imageUrl is null
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user?.id == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_${user!.id}_image');
  }
}
