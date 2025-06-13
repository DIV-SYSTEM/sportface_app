import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
  final _nameController = TextEditingController(text: 'John Doe'); // Dummy name
  final _emailController = TextEditingController(text: 'john.doe@example.com'); // Dummy email
  final _passwordController = TextEditingController(text: 'Password123!'); // Dummy password
  XFile? _aadhaarImage;
  XFile? _liveImage;
  bool _isMatching = false;
  bool _isRegistering = false;
  String? _dob = '01/01/1990'; // Dummy DOB
  int? _matchedAge = 35; // Dummy age

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickAadhaarImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _aadhaarImage = pickedFile);
    }
  }

  Future<void> _pickLiveImage() async {
    final picker = ImagePicker();
    final pickedFile = kIsWeb
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _liveImage = pickedFile);
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

    // Simulate successful image matching
    await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
    setState(() {
      _dob = '01/01/1990'; // Dummy DOB
      _matchedAge = 35; // Dummy age
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Face matched! Age: $_matchedAge')),
    );

    setState(() => _isMatching = false);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isRegistering = true);
      try {
        final user = UserModel(
          id: const Uuid().v4(),
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          age: _matchedAge ?? 35, // Use dummy age if not set
        );

        // Simulate Firebase registration
        if (_liveImage != null) {
          final image = File(_liveImage!.path);
          await FirebaseService().registerUser(user, image); // Assuming this works or is mocked
        } else {
          // Even if no image, proceed with dummy data
          await Future.delayed(const Duration(seconds: 1)); // Simulate delay
        }

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
        const SnackBar(content: Text('Please complete the form')),
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
              const SizedBox(height: 16),
              CustomButton(
                text: 'Skip to HomeScreen',
                onPressed: () {
                  final user = UserModel(
                    id: const Uuid().v4(),
                    name: 'Dummy User',
                    email: 'dummy@example.com',
                    password: 'DummyPass123!',
                    age: 35,
                  );
                  Provider.of<UserProvider>(context, listen: false).setUser(user);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
