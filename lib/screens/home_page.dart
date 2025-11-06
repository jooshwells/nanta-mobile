import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NANTA: Not Another Note Taking App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }, 
              child: const Text('Login'),
            ),
            const SizedBox(
              height: 20
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegisterPage()),
                );
              }, 
              child: const Text('Sign Up'),
            ),
          ],
        )
      )
    );
  }
}