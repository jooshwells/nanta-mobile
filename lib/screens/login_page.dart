import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _sendLoginRequest() async {
    // Get the current text from the controller
    String email = _emailController.text;
    String password = _passwordController.text;

    final http.Response response = await _postRequest(email, password);
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

  Future<http.Response> _postRequest(email, password) async {
    Map data = {
      'email' : email,
      'password' : password,
    };
    //encode Map to JSON
    var body = json.encode(data);

    var response = await http.post(Uri.http('aedogroupfour-lamp.xyz', '/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: body
    );
    print("${response.statusCode}");
    print("${response.body}");
    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login to your Existing Account')),
      body: Padding( // Add padding around the content
        padding: const EdgeInsets.all(16.0), 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            Text(
              "Login",
              style: TextStyle(
                fontSize: 20.0
              ),
            ),
            
            const SizedBox(height: 20),

            // STEP 4: Add the TextField widget
            TextField(
              controller: _emailController, // Attach the controller
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
            
            // You can add space
            const SizedBox(height: 20),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _sendLoginRequest, // We will create this method next
        tooltip: 'Login',
        child: const Icon(Icons.send),
      ),

    );
  }
}