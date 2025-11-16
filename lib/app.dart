import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDark = brightness == Brightness.dark;
    
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 16, 3, 31), brightness: isDark ? Brightness.dark : Brightness.light,),
        textTheme: GoogleFonts.oswaldTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: isDark ? Color.fromARGB(255, 255, 255, 255) : Color.fromARGB(255, 16, 3, 31),
          displayColor: isDark ? Color.fromARGB(255, 255, 255, 255) : Color.fromARGB(255, 16, 3, 31),
        ),
        scaffoldBackgroundColor: isDark ? Color.fromARGB(255, 16, 3, 31) : Color.fromARGB(255, 255, 255, 255),
        elevatedButtonTheme: ElevatedButtonThemeData(
         style: ElevatedButton.styleFrom(
            fixedSize: const Size(125, 50),
            backgroundColor: isDark ? Color.fromARGB(255, 255, 255, 255) : Color.fromARGB(255, 173, 214, 255),
            foregroundColor: isDark ? Color.fromARGB(255, 16, 3, 31) : Color.fromARGB(255, 16, 3, 31),
          ), 
        )
        // scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
      ),
      themeMode: ThemeMode.system,
      // It passes control to HomePage
      home: const HomePage(title: 'API Demo'), 
    );
  }
}