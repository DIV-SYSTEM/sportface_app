import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../services/firebase_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/text_field.dart';
import '../model/user_model.dart';
import '../providers/user_provider.dart';
import '../utils/helpers.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  XFile? _aadhaarImage;
  XFile? _liveImage;
  bool _isMatching = false;
  bool _isRegistering = false;
  String? _dob;
  int? _matchedAge;

  // Face++ API credentials
  final String _apiKey = 'M--3IqwyiBUIDn_gVgKnc9jsTCacghA6';
  final String _apiSecret = 'XYwJlPWvbOBRoEiR85D9-zVRbHiuTLxM';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  int _extractAgeFromDOB(String dob) {
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final birthDate = DateTime(year, month, day);
        final now = DateTime.now();
        int age = now.year - birthDate.year;
        if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
        return age;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _pickAadhaarImage() async {
    final status = kIsWeb ? PermissionStatus.granted : await Permission.photos.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _aadhaarImage = pickedFile);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery permission denied')),
      );
    }
  }

  Future<void> _pickLiveImage() async {
    if (kIsWeb) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _liveImage = pickedFile);
      }
    } else {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: ImageSource.camera);
        if (pickedFile != null) {
          setState(() => _liveImage = pickedFile);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission denied')),
        );
      }
    }
  }

  Future<void> _matchImages() async {
    if (_aadhaarImage == null || _liveImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload both images')),
      );
      return;
    }

    setState(() => _isMatching = true);

    try {
      final uri = Uri.parse('https://api-us.faceplusplus.com/facepp/v3/compare');
      final request = http.MultipartRequest('POST', uri);

      request.fields['api_key'] = _apiKey;
      request.fields['api_secret'] = _apiSecret;

      // Add images as files (highest precedence)
      final aadhaarFile = File(_aadhaarImage!.path);
      final liveFile = File(_liveImage!.path);

      request.files.add(
        await http.MultipartFile.fromPath('image_file1', aadhaarFile.path),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image_file2', liveFile.path),
      );

      // Add timeout handling
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data.containsKey('error_message')) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Verification Failed'),
            content: Text(data['error_message'] ?? 'Unknown error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Check confidence against threshold
        final confidence = data['confidence'] as double?;
        final thresholds = data['thresholds'] as Map<String, dynamic>?;
        final threshold = thresholds?['1e-4'] as double? ?? 71.8;

        if (confidence != null && confidence >= threshold) {
          // Assuming DOB is provided externally or hardcoded for demo
          setState(() {
            _dob = '01/01/1990'; // Replace with actual DOB extraction if available
            _matchedAge = _extractAgeFromDOB(_dob!);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Face matched! Age: $_matchedAge')),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Verification Failed'),
              content: const Text('Faces do not match with sufficient confidence'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error: Server unreachable')),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timeout: Server took too long to respond')),
      );
    } on http.ClientException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Client Error: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected Error: $e')),
      );
    }

    setState(() => _isMatching = false);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _matchedAge != null && _liveImage != null) {
      setState(() => _isRegistering = true);
      try {
        final user = UserModel(
          id: const Uuid().v4(),
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          age: _matchedAge,
        );
        final image = File(_liveImage!.path);
        await FirebaseService().registerUser(user, image);
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isRegistering = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete form and match images first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                label: 'Name',
                controller: _nameController,
                validator: Helpers.validateName,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                controller: _emailController,
                validator: Helpers.validateEmail,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                controller: _passwordController,
                obscureText: true,
                validator: Helpers.validatePassword,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(
                    text: 'Upload Aadhaar/PAN',
                    onPressed: _pickAadhaarImage,
                  ),
                  CustomButton(
                    text: 'Capture Live Photo',
                    onPressed: _pickLiveImage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_aadhaarImage != null) const Text('Aadhaar/PAN Image Selected'),
              if (_liveImage != null) const Text('Live Photo Selected'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Match Images',
                onPressed: _matchImages,
                isLoading: _isMatching,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Register',
                onPressed: _register,
                isLoading: _isRegistering,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
