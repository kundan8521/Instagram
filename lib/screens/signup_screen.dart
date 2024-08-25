import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        _showToast("No image selected");
      }
    } catch (e) {
      _showToast("Failed to pick image: $e");
    }
  }

  Future<void> _signup() async {
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (!_validateInputs(name, phone, email, password)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Upload profile image
      String imageUrl = await _uploadImage(userCredential.user!.uid);

      // Save user details in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': name,
        'phone': phone,
        'email': email,
        'profileImageUrl': imageUrl,
      });

      // Show success toast and navigate after a delay
      await _showToast("Signup successful!", isSuccess: true);
      await Future.delayed(
          Duration(seconds: 1)); // Optional delay for better user experience
      _navigateToHomeScreen(); // Navigate to the home screen
    } catch (e) {
      _showToast("Signup failed. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _uploadImage(String userId) async {
    try {
      Reference ref = _storage.ref().child('user_images').child('$userId.jpg');
      UploadTask uploadTask = ref.putFile(_image!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      _showToast("Image upload failed. Please try again.");
      throw e;
    }
  }

  bool _validateInputs(
      String name, String phone, String email, String password) {
    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showToast("All fields are required.");
      return false;
    }
    if (password.length < 6) {
      _showToast("Password must be at least 6 characters long.");
      return false;
    }
    if (_image == null) {
      _showToast("Please select a profile image.");
      return false;
    }
    return true;
  }

  Future<void> _navigateToHomeScreen() async {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _showToast(String message, {bool isSuccess = false}) async {
    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal, // Gradient not directly applied in AppBar
        elevation: 10.0, // Shadow effect
      ),
      backgroundColor:
          Colors.grey[200], // Set body background color to grey[200]
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? Icon(Icons.add_a_photo,
                          size: 50, color: Colors.grey[800])
                      : null,
                ),
              ),
              SizedBox(height: 20),
              _buildTextField(_nameController, 'Name', Icons.person),
              SizedBox(height: 16),
              _buildTextField(_phoneController, 'Phone', Icons.phone),
              SizedBox(height: 16),
              _buildTextField(_emailController, 'Email', Icons.email),
              SizedBox(height: 16),
              _buildTextField(_passwordController, 'Password', Icons.lock,
                  obscureText: true),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal, // Gradient background
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text('Sign Up',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String labelText, IconData icon,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.teal, width: 1.5),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.teal, width: 2.0),
        ),
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.white, // Set TextField color to white
      ),
      obscureText: obscureText,
    );
  }
}
