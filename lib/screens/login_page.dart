import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import './editor_page.dart';

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
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', data['token']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditorPage()),
          );
        }
        return;
      }
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hello!'),
          content: Text('Error logging in'),
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
    /*
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
    );*/
  }

  Future<http.Response> _postRequest(email, password) async {
    Map data = {'email': email, 'password': password};
    //encode Map to JSON
    var body = json.encode(data);
    // Replace the first string with http://localhost:8080 for local testing and aedogroupfour-lamp.xyz regular
    var response = await http.post(
      Uri.https('aedogroupfour-lamp.xyz', '/api/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    print("${response.statusCode}");
    print(response.body);
    return response;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // center horizontally
        children: <Widget>[
          const SizedBox(height: 100),
          Text(
            "Login",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38, 
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
              obscureText: true,
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
        backgroundColor: Theme.of(context).primaryColor,    
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,     
        child: const Icon(Icons.send),
      ),
    );
  }
}
