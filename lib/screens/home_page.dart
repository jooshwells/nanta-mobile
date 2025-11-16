import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDark = brightness == Brightness.dark;

    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      // Set the status bar background color
      statusBarColor: Colors.transparent,

      // Set the status bar icon brightness
      // Brightness.light = Light icons (for dark backgrounds)
      // Brightness.dark = Dark icons (for light backgrounds)
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,

      // For iOS (handles the notch area)
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion(
      value: overlayStyle,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "N A N T A",
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 80,
                  wordSpacing: 22,
                  // color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Not Another Note Taking App",
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 30,
                  wordSpacing: 10,
                  // color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 20,
                    // color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(fixedSize: const Size(125, 50)),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 20,
                    // color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Profilepage(),
                    ),
                  );
                },
                child: Text(
                  'Profile(Testing)',
                  style: TextStyle(
                    fontSize: 20,
                    // color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
