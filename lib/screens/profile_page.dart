import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:nanta_mobile/screens/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import './home_page.dart';
import './editor_page.dart';
import './pfp_components/profiletop.dart';
import './pfp_components/editaccount.dart';
import './editor_page.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  //Api call info
  final String baseUrl = 'https://aedogroupfour-lamp.xyz';

  Future<String?> fetchUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  //Function for logout
  Future<void> logout(BuildContext context) async {
    try {
      final token = await fetchUserToken();
      if (token != null) {
        final response = await http.post(
          Uri.parse("$baseUrl/api/auth/logout"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          //Clear token
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('auth_token');
        }
      }
      //Return back to home page
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage(title: 'NANTA')),
        );
      }
    } catch (error) {
      print("Error logging out $error");
    }
  }

  //Function for notes page
  void redirectNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorPage()),
    );
  }

  //Display errors to app

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 50),

            //Button to redirect to edit Notes and to logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => redirectNotes(context),
                  icon: Icon(FeatherIcons.bookOpen),
                ),
                IconButton(
                  onPressed: () {
                    logout(context);
                  },
                  icon: Icon(FeatherIcons.logOut),
                ),
              ],
            ),

            const Profiletop(),

            //Change color
            Divider(
              color: isDark ? Colors.white : Color.fromARGB(255, 16, 3, 31),
              thickness: 3,
            ),
            FractionallySizedBox(widthFactor: 0.8, child: const EditAccount()),
          ],
        ),
      ),
    );
  }
}
