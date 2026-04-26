import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  bool isLoading = false;

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final res = await http.post(
      Uri.parse("http://127.0.0.1:8001/auth/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name.text.trim(),
        "email": email.text.trim(),
        "phone_number": phone.text.trim(),
        "password": password.text.trim(),
      }),
    );

    setState(() => isLoading = false);

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['detail'] ?? "Signup failed ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final primary = const Color(0xFF5C6BC0);
  final accent = const Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // HEADER
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: primary.withOpacity(0.1),
                            child: Icon(Icons.person_add, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              const Text(
                                "Sign up to continue",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      // NAME
                      TextFormField(
                        controller: name,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Name required" : null,
                        decoration: inputStyle("Full Name", Icons.person),
                      ),

                      const SizedBox(height: 12),

                      // EMAIL
                      TextFormField(
                        controller: email,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Email required";
                          if (!v.contains("@")) return "Invalid email";
                          return null;
                        },
                        decoration: inputStyle("Email", Icons.email),
                      ),

                      const SizedBox(height: 12),

                      // PHONE
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Phone required" : null,
                        decoration: inputStyle("Phone Number", Icons.phone),
                      ),

                      const SizedBox(height: 12),

                      // PASSWORD
                      TextFormField(
                        controller: password,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Password required";
                          if (v.length < 6) return "Min 6 characters";
                          return null;
                        },
                        decoration: inputStyle("Password", Icons.lock),
                      ),

                      const SizedBox(height: 20),

                      // BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Already have an account? Login"),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}