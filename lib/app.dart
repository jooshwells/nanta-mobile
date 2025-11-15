import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 71, 183)),
        textTheme: GoogleFonts.oswaldTextTheme(
          Theme.of(context).textTheme,
        )
      ),
      // It passes control to HomePage
      home: const HomePage(title: 'API Demo'), 
    );
  }
}