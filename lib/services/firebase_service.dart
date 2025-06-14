import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../model/user_model.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> login(String email, String password) async {
    try {
      final snapshot = await _db.child('users').get().timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Database fetch timed out'),
          );
      if (snapshot.exists) {
        final users = snapshot.value as Map<dynamic, dynamic>;
        for (var entry in users.entries) {
          final userData = Map<String, dynamic>.from(entry.value as Map);
          if (userData['email'] == email &&
              userData['password'] == _hashPassword(password)) {
            return UserModel.fromJson(entry.key as String, userData);
          }
        }
      }
      throw Exception('Invalid email or password');
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<void> registerUser(UserModel user, File? image) async {
    try {
      if (kDebugMode) {
        print('Starting user registration: ${user.email}');
      }

      String? imageUrl;
      if (image != null) {
        if (!await image.exists()) {
          throw Exception('Image file does not exist: ${image.path}');
        }
        if (kDebugMode) {
          print('Uploading image to Firebase Storage: ${image.path}, size: ${await image.length()} bytes');
        }
        final ref = _storage.ref().child('users/${user.id}/profile.jpg');
        final uploadTask = ref.putFile(image);
        final snapshot = await uploadTask.timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Image upload timed out'),
        );
        imageUrl = await snapshot.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception('Download URL fetch timed out'),
        );
        if (kDebugMode) {
          print('Image uploaded, download URL: $imageUrl');
        }
      }

      final userData = UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        password: _hashPassword(user.password),
        age: user.age,
        imageUrl: imageUrl,
      ).toJson();

      if (kDebugMode) {
        print('Saving user data to Realtime Database: $userData');
      }

      await _db.child('users/${user.id}').set(userData).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Database write timed out'),
          );

      if (kDebugMode) {
        print('User registration successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      throw Exception('Registration failed: $e');
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
