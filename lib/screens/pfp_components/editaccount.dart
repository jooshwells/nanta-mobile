import "dart:convert";

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";
import 'package:http/http.dart' as http;
import 'package:nanta_mobile/screens/login_page.dart';
import '../profile_page.dart';

class EditAccount extends StatefulWidget {
  const EditAccount({super.key});
  @override
  State<EditAccount> createState() => _EditAccount();
}

class _EditAccount extends State<EditAccount> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPWController = TextEditingController();

  final TextEditingController _changePWController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool showEditPW = false;

  String firstName = "First Name";
  String lastName = "Last Name";
  String email = "email@gmail.com";
  String changePW = "";

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _emailController.dispose();
    _changePWController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  //Initialize API info and token
  String baseURL = 'https://aedogroupfour-lamp.xyz';

  //Above is base URL for local testing

  Future<String?> fetchUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  //Function to fetch user data
  Future<void> fetchUserData() async {
    try {
      final token = await fetchUserToken();
      if (token != null) {
        final response = await http.get(
          Uri.parse("$baseURL/api/auth/user"),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        final jsonResponse = jsonDecode(response.body);
        if (response.statusCode == 200) {
          if (jsonResponse['success'] != true) {
            //Error
            return;
          }
          setState(() {
            email = jsonResponse['data']['user']['email'] ?? 'Email';
            firstName =
                jsonResponse['data']['user']['first_name'] ?? 'First Name';
            lastName = jsonResponse['data']['user']['last_name'] ?? 'Last Name';

            _fnameController.text = firstName;
            _lnameController.text = lastName;
            _emailController.text = email;
          });
        } else {
          /*
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }*/
          throw Exception('Failed to load user data: ${response.statusCode}');
        }
      }
    } catch (error) {
      //
      print("error fetching user data: $error");
    }
  }

  //Function to Update User Info
  Future<void> updateUserInfo() async {
    //Ensure there is something to change, and password validation
    //Values from controllers
    String formFirstName = _fnameController.text.trim();
    String formLastName = _lnameController.text.trim();
    String formEmail = _emailController.text.trim();
    String oldPassword = _oldPWController.text;
    String formPassword = _changePWController.text;
    String formConfirmPassword = _confirmController.text;

    if (formFirstName == "" && formLastName == "" && formEmail == "") {
      print("At least one valid edit is required");
      return;
    }

    if (showEditPW && formPassword.isNotEmpty) {
      if (oldPassword.isEmpty) {
        return;
      }

      if (formPassword.length < 8) {
        print("Password must be at least 8 characters.");
        return;
      }

      if (formPassword != formConfirmPassword) {
        print("Passwords do not match.");
        return;
      }
    }

    try {
      Map<String, dynamic> updatePayload = {
        'first_name': formFirstName,
        'last_name': formLastName,
        'email': formEmail,
      };
      if (showEditPW && formPassword.isNotEmpty) {
        updatePayload['password'] = formPassword;
        updatePayload['old_password'] = oldPassword;
      }

      final token = await fetchUserToken();
      if (token != null) {
        final response = await http.put(
          Uri.parse('$baseURL/api/profile/update-info'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(updatePayload),
        );
        final data = json.decode(response.body);

        if (response.statusCode == 200) {
          setState(() {
            firstName = formFirstName;
            lastName = formLastName;
            email = formEmail;
          });
          print("Profile updated ");

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => Profilepage(), // Your profile page widget
              ),
            );
          }
        }

        if (showEditPW) {
          setState(() {
            showEditPW = false;
            _changePWController.clear();
            _confirmController.clear();
          });
        }
      }
    } catch (error) {
      print("Error $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Card(
        color: isDark
            ? Color.fromARGB(255, 30, 33, 65)
            : Color.fromARGB(255, 255, 255, 255),
        elevation: 5,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 20),
              _inputField(_fnameController, "First Name"),
              SizedBox(height: 20),
              _inputField(_lnameController, "Last Name"),
              SizedBox(height: 20),
              _inputField(_emailController, "Email"),
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showEditPW = !showEditPW;
                  });
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: const Size(150, 50),
                ),
                child: Text("Change Password"),
              ),
              SizedBox(height: 20),

              if (showEditPW) ...[
                _passwordFields(_oldPWController, "Confirm Current Password"),
                SizedBox(height: 20),

                _passwordFields(_changePWController, "New Password"),
                SizedBox(height: 20),

                _passwordFields(_confirmController, "Confirm Password"),
              ],
              SizedBox(height: 20),

              ElevatedButton(
                onPressed: updateUserInfo,
                child: Text("Submit"),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController controller, String label) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(80)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(80),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 21, 41, 85),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordFields(TextEditingController controller, String label) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color.fromARGB(255, 21, 41, 85)),

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(80)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(80),
            borderSide: BorderSide(
              color: Color.fromARGB(255, 21, 41, 85),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
