import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Add this import
import 'package:flutter_quill/flutter_quill.dart'; // Add this import
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';

// --- LIGHT MODE COLORS ---
const Color kBackgroundLight = Color.fromARGB(255, 250, 250, 250);  // --background
const Color kForegroundLight = Color.fromARGB(255, 7, 24, 65);      // --foreground
const Color kPrimaryLight = Color.fromARGB(255, 171, 199, 240);       // --primary

// --- DARK MODE COLORS ---
const Color kBackgroundDark = Color.fromARGB(255, 9, 9, 11);         // .dark --background
const Color kForegroundDark = Color.fromARGB(255, 250, 250, 250);     // .dark --foreground
const Color kPrimaryDark = Color.fromARGB(255, 20, 71, 230);         // .dark --primary


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDark = brightness == Brightness.dark;
    
    return MaterialApp(
      title: 'Flutter Demo',
      // --- Add Localization Configuration Here ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate, // Required by flutter_quill
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        // Add other locales here if needed
      ],
 // --- LIGHT THEME ---
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: kBackgroundLight,
        primaryColor: kPrimaryLight,
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryLight,
          foregroundColor: kForegroundLight,
        ),
        textTheme: GoogleFonts.oswaldTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: kForegroundLight,
          displayColor: kForegroundLight,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryLight,
            foregroundColor: kForegroundLight,
            fixedSize: const Size(125, 50),
          ),
        ),
      ),

      // --- DARK THEME ---
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackgroundDark,
        primaryColor: kPrimaryDark,
        appBarTheme: AppBarTheme(
          backgroundColor: kPrimaryDark,
          foregroundColor: kForegroundDark,
        ),
        textTheme: GoogleFonts.oswaldTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: kForegroundDark,
          displayColor: kForegroundDark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryDark,
            foregroundColor: kForegroundDark,
            fixedSize: const Size(125, 50),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(title: 'API Demo'), 
      debugShowCheckedModeBanner: false,
    );
  }
}