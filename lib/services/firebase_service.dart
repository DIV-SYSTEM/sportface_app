import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:crypto/crypto.dart';
import '../model/user_model.dart';

class FirebaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<UserModel?> login(String email, String password) async {
    try {
      final snapshot = await _db.child('users').get();
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
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> registerUser(UserModel user, File? image) async {
    try {
      String? imageUrl;
      if (image != null) {
        final ref = _storage.ref().child('users/${user.id}/profile.jpg');
        await ref.putFile(image);
        imageUrl = await ref.getDownloadURL();
      }
      await _db.child('users/${user.id}').set(
            UserModel(
              id: user.id,
              name: user.name,
              email: user.email,
              password: _hashPassword(user.password),
              age: user.age,
              imageUrl: imageUrl,
            ).toJson(),
          );
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
