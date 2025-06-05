import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';
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
  int? _matchedAge;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAadhaarImage() async {
    // Check permission status first
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _aadhaarImage = pickedFile);
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog('gallery');
    } else {
      _showPermissionRetrySnackBar('Gallery', _pickAadhaarImage);
    }
  }

  Future<void> _pickLiveImage() async {
    // Check permission status first
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() => _liveImage = pickedFile);
      }
    } else if (status.isPermanentlyDenied) {
      await _showPermissionModalDialog('Camera');
    } else {
      _showPermissionDeniedSnackBar('Camera', _pickLiveImage);
    }
  }

  void _showPermissionDeniedModalDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'Please enable $permissionType permission in app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackBar message, VoidCallback callback) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message permission denied'),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: callback,
        ),
      ),
    );
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
      final aadhaarBase64 = await Helpers.fileToBase64(_aadhaarImage);
      final liveBase64 = await Helpers.fileToBase64(_liveImage);
      if (aadhaarBase64 == null || liveBase64 == null) {
        throw Exception('Failed to process images');
      }
      final response = await ApiService().matchFaces(aadhaarBase64, liveBase64);
      if (response.status == 'success') {
        setState(() => _matchedAge = response.age);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Images matched! Age: ${response.age}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Images do not match: ${response.alert}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
          (_) => MaterialPageRoute(builder: const HomeScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      setState(() => _isRegistering = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(content: const SnackBar(
        'Complete form and match images first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  labelText: 'Name',
                  controller: _nameController,
                  validator: validateName,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Email',
                  controller: _emailController,
                  validator: validateEmail,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: validatePassword,
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
      ),
    );
  }
}
