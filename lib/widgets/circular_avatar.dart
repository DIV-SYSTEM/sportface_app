import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CircularAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const CircularAvatar({super.key, this.imageUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(imageUrl!)
          : const AssetImage('assets/images/default_profile.png'),
      child: imageUrl == null ? const Icon(Icons.person) : null,
    );
  }
}
