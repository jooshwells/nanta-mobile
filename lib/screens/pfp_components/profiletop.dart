import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nanta_mobile/screens/login_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Profiletop extends StatefulWidget {
  const Profiletop({super.key});

  @override
  State<Profiletop> createState() => _ProfileTopState();
}

class _ProfileTopState extends State<Profiletop> {
  String firstName = "First Name";
  String lastName = "Last Name";
  String email = "email@gmail.com";

  // ---------------- PROFILE PIC STATE ----------------
  bool showPicOptions = false;
  int selectedIndex = 0;

  final List<String> profilePics = List.generate(
    12,
    (index) => "assets/profile${index + 1}.jpg",
  );

  // ---------------- API CONFIG ----------------
  String baseURL = 'https://aedogroupfour-lamp.xyz';

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<String?> fetchUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> fetchUserData() async {
    try {
      final token = await fetchUserToken();
      if (token == null) {
        print("No token");
      }
      if (token != null) {
        final response = await http.get(
          Uri.parse("$baseURL/api/auth/user"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        final jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          setState(() {
            email = jsonResponse['data']['user']['email'] ?? 'Email';
            firstName =
                jsonResponse['data']['user']['first_name'] ?? 'First Name';
            lastName = jsonResponse['data']['user']['last_name'] ?? 'Last Name';
            selectedIndex = jsonResponse['data']['user']['profile_pic'] ?? 0;

            // Ensure selectedIndex is within bounds
            if (selectedIndex < 0 || selectedIndex >= profilePics.length) {
              selectedIndex = 0;
            }
          });
        } else {
          throw Exception('Failed to load user data: ${response.statusCode}');
        }
      }
    } catch (error) {
      print("Error fetching user data: $error");
    }
  }

  // ---------------- UPDATE PROFILE PIC ----------------
  Future<void> updateProfilePic(int index) async {
    try {
      final token = await fetchUserToken();
      if (token != null) {
        final response = await http.put(
          Uri.parse("$baseURL/api/profile/update-info"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'profile_pic': index}),
        );

        if (response.statusCode == 200) {
          setState(() {
            selectedIndex = index;
          });
        } else {
          print("Failed saving profile picture change");
        }
      }
    } catch (error) {
      print("Error updating profile picture: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ---------------- PROFILE PICTURE ----------------
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(profilePics[selectedIndex]),
                backgroundColor: isDark
                    ? Colors.white
                    : const Color.fromARGB(255, 173, 214, 255),
              ),

              // Pencil button
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => setState(() => showPicOptions = !showPicOptions),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // -------- GRID OF SELECTABLE PFPS --------
          if (showPicOptions)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                profilePics.length,
                (index) => GestureDetector(
                  onTap: () {
                    selectedIndex = index;
                    updateProfilePic(index); // save to backend
                    setState(() => showPicOptions = false);
                  },
                  child: ClipOval(
                    child: Image.asset(
                      profilePics[index],
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ---------------- TEXT INFO ----------------
          Text(
            firstName,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          ),
          Text(lastName),
          Text(email),
        ],
      ),
    );
  }
}
