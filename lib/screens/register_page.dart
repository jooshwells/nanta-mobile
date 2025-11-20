import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'editor_page.dart'; // Import the editor page

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // STEP 1: Create the controller
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    // STEP 2: Initialize the controller
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    // STEP 3: Dispose of the controller
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<http.Response> _postRequest(
    firstName,
    lastName,
    email,
    password,
    confirmPassword,
  ) async {
    Map data = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
    };
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(
      Uri.https('aedogroupfour-lamp.xyz', '/api/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    // print("${response.statusCode}");
    // print(response.body);
    return response;
  }

  // Helper to perform login immediately after registration
  Future<void> _attemptAutoLogin(String email, String password) async {
    try {
      final loginResponse = await http.post(
        Uri.https('aedogroupfour-lamp.xyz', '/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'email': email, 'password': password}),
      );

      if (loginResponse.statusCode == 200) {
        final data = json.decode(loginResponse.body);

        if (data['token'] != null) {
          // Save token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);

          // Redirect to Editor Page
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const NoteEditorPage()),
              (route) => false, // Removes all previous routes (Login/Register)
            );
          }
        }
      } else {
        // Registration succeeded, but auto-login failed
        _showDialog('Registration successful, but auto-login failed. Please login manually.');
      }
    } catch (e) {
      _showDialog('Registration successful, but a network error occurred during login.');
    }
  }

  void _showDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notification'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _sendRegistrationRequest() async {
    // Get the current text from the controller
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    final http.Response response = await _postRequest(
      firstName,
      lastName,
      email,
      password,
      confirmPassword,
    );

    // Check for success (200 OK or 201 Created)
    if (response.statusCode == 200 || response.statusCode == 201) {
      // Registration Successful: Attempt to log in automatically
      await _attemptAutoLogin(email, password);
    } else {
      // Registration Failed
      int code = response.statusCode;
      String message = response.body;
      // Attempt to parse error message if it is JSON
      try {
         final msgJson = jsonDecode(message);
         if(msgJson['message'] != null) message = msgJson['message'];
         if(msgJson['errors'] != null) message = msgJson['errors'].toString();
      } catch (_) {}

      _showDialog('Error ($code): $message');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "NANTA",
          style: TextStyle(
            fontSize: 36, // adjust as needed
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Added ScrollView to prevent overflow on small screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
            children: <Widget>[
              const SizedBox(height: 40), // Adjusted spacing
              const Text(
                "Sign Up",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                ),
              ),
              const SizedBox(height: 20),

              // STEP 4: Add the TextField widget
              TextField(
                controller: _firstNameController, // Attach the controller
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'First Name',
                  hintText: 'Enter your first name',
                ),
              ),

              // You can add space
              const SizedBox(height: 20),

              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Last Name',
                  hintText: 'Enter your last name',
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                  hintText: 'Enter your email',
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                  hintText: 'Enter your password',
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Confirm Password',
                  hintText: 'Enter your password again',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendRegistrationRequest,
        tooltip: 'Register',
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: const Icon(Icons.send),
      ),
    );
  }
}