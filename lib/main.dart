import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'API Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  Future<http.Response> _postRequest (firstName, lastName, email, password, confirmPassword) async {
    var url = 'https://aedogroupfour-lamp.xyz/api/auth/register';

    Map data = {
      'first_name' : firstName,
      'last_name' : lastName,
      'email' : email,
      'password' : password,
      'confirm_password' : confirmPassword
    };
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(Uri.http('aedogroupfour-lamp.xyz', '/api/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: body
    );
    print("${response.statusCode}");
    print("${response.body}");
    return response;
  }

  void _sendRegistrationRequest() async {
    // Get the current text from the controller
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    print("Am I running?");

    final http.Response response = await _postRequest(firstName, lastName, email, password, confirmPassword);
    int code = response.statusCode;
    String message = response.body;
    // Show a simple pop-up dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hello!'),
          content: Text('Response: ($code) - $message'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Closes the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding( // Add padding around the content
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Text(
              "Register your account",
              style: TextStyle(
                fontSize: 20.0
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Confirm Password',
                hintText: 'Enter your password again',
              ),
            ),

            // (You can remove the counter Text widgets)
            // const Text('You have pushed the button this many times:'),
            // Text( ... ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendRegistrationRequest, // We will create this method next
        tooltip: 'Register',
        child: const Icon(Icons.send),
      ),
    );
  }
}
