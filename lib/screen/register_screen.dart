// register_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
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
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _extractAgeFromDOB(String dob) {
    try {
      final parts = dob.split('/');
      if (parts.length == 3) {
        final birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        final now = DateTime.now();
        int age = now.year - birthDate.year;
        if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
        return age;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _pickAadhaarImage() async {
    final status = kIsWeb ? PermissionStatus.granted : await Permission.photos.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100, maxWidth: 1920, maxHeight: 1080);
      if (pickedFile != null) setState(() => _aadhaarImage = pickedFile);
    } else {
      _showSnack('Gallery permission denied');
    }
  }

  Future<void> _pickLiveImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: kIsWeb ? ImageSource.gallery : ImageSource.camera, imageQuality: 100, maxWidth: 1920, maxHeight: 1080);
    if (pickedFile != null) {
      setState(() => _liveImage = pickedFile);
    } else if (!kIsWeb) {
      final status = await Permission.camera.request();
      if (!status.isGranted) _showSnack('Camera permission denied');
    }
  }

  Future<File> _preprocessImage(XFile imageFile) async {
    final file = File(imageFile.path);
    final imageBytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(imageBytes);
    image = img.bakeOrientation(image!);
    final tempFile = File('${Directory.systemTemp.path}/${imageFile.name}.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(image, quality: 100));
    return tempFile;
  }

  Future<void> _matchImages() async {
    if (_aadhaarImage == null || _liveImage == null) return _showSnack('Please upload both images');

    setState(() => _isMatching = true);

    try {
      final uri = Uri.parse('https://9235-116-72-199-8.ngrok-free.app/api/verify/');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Content-Type'] = 'multipart/form-data'
        ..headers['Accept'] = 'application/json'
        ..files.add(await http.MultipartFile.fromPath('aadhaar_image', (await _preprocessImage(_aadhaarImage!)).path))
        ..files.add(await http.MultipartFile.fromPath('selfie_image', (await _preprocessImage(_liveImage!)).path));

      final response = await http.Response.fromStream(await request.send());

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['verified'] == true) {
        _dob = data['dob'] as String?;
        _matchedAge = _dob != null ? _extractAgeFromDOB(_dob!) : null;
        _showSnack('Face matched! Age: $_matchedAge');
      } else {
        _showDialog('Verification Failed', data['message'] ?? 'Unknown error');
      }
    } catch (e) {
      _showDialog('Error', e.toString());
    }

    setState(() => _isMatching = false);
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && _matchedAge != null && _liveImage != null) {
      setState(() => _isRegistering = true);
      try {
        final imageFile = File(_liveImage!.path);
        final imageUrl = 'data:image/jpeg;base64,${base64Encode(await imageFile.readAsBytes())}';

        final user = UserModel(
          id: const Uuid().v4(),
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          age: _matchedAge,
          imageUrl: imageUrl,
        );

        await FirebaseService().registerUser(user, imageFile);
        Provider.of<UserProvider>(context, listen: false).setUser(user);
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } catch (e) {
        _showSnack('Error: $e');
      }
      setState(() => _isRegistering = false);
    } else {
      _showSnack('Complete form and match images first');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showDialog(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  Widget _buildScanAnimation() {
    return Container(
      height: 150,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (_, __) => Positioned(
              top: 150 * _scanAnimation.value,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: Colors.blueAccent,
              ),
            ),
          ),
          const Center(child: Text('Scanning...', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(label: 'Name', controller: _nameController, validator: Helpers.validateName),
              const SizedBox(height: 16),
              CustomTextField(label: 'Email', controller: _emailController, validator: Helpers.validateEmail),
              const SizedBox(height: 16),
              CustomTextField(label: 'Password', controller: _passwordController, obscureText: true, validator: Helpers.validatePassword),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CustomButton(text: 'Upload Aadhaar/PAN', onPressed: _pickAadhaarImage),
                  CustomButton(text: 'Capture Live Photo', onPressed: _pickLiveImage),
                ],
              ),
              const SizedBox(height: 16),
              if (_aadhaarImage != null) const Text('Aadhaar/PAN Image Selected'),
              if (_liveImage != null) const Text('Live Photo Selected'),
              const SizedBox(height: 16),
              if (_isMatching) _buildScanAnimation(),
              CustomButton(text: 'Match Images', onPressed: _matchImages, isLoading: _isMatching),
              const SizedBox(height: 16),
              CustomButton(text: 'Register', onPressed: _register, isLoading: _isRegistering),
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
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
