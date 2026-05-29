import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import '../../utils/responsive_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final name     = TextEditingController();
  final email    = TextEditingController();
  final phone    = TextEditingController();
  final password = TextEditingController();

  bool isLoading       = false;
  bool obscurePassword = true;
  String selectedRole  = 'user';   // 'user' or 'company'

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);
  static const bg      = Color(0xFFF0F7FF);

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("http://127.0.0.1:8001/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name":         name.text.trim(),
          "email":        email.text.trim(),
          "phone_number": phone.text.trim(),
          "password":     password.text.trim(),
          "role":         selectedRole,           // ← sends role to backend
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
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

                      // ── HEADER ────────────────────────────────────────
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: primary.withOpacity(0.1),
                            child: const Icon(Icons.person_add, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Create Account",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              Text(
                                "Sign up to continue",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── ACCOUNT TYPE TOGGLE ───────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primary.withOpacity(0.2)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _RoleTab(
                              label: "Job Seeker",
                              icon: Icons.person_outline,
                              selected: selectedRole == 'user',
                              onTap: () => setState(() => selectedRole = 'user'),
                            ),
                            _RoleTab(
                              label: "Company",
                              icon: Icons.business_outlined,
                              selected: selectedRole == 'company',
                              onTap: () => setState(() => selectedRole = 'company'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── NAME ──────────────────────────────────────────
                      TextFormField(
                        controller: name,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Name required" : null,
                        decoration: inputStyle(
                          selectedRole == 'company'
                              ? "Company Name"
                              : "Full Name",
                          selectedRole == 'company'
                              ? Icons.business_outlined
                              : Icons.person_outline,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── EMAIL ─────────────────────────────────────────
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Email required";
                          if (!v.contains("@")) return "Invalid email";
                          return null;
                        },
                        decoration: inputStyle("Email", Icons.email_outlined),
                      ),

                      const SizedBox(height: 12),

                      // ── PHONE ─────────────────────────────────────────
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Phone required" : null,
                        decoration: inputStyle("Phone Number", Icons.phone_outlined),
                      ),

                      const SizedBox(height: 12),

                      // ── PASSWORD ──────────────────────────────────────
                      TextFormField(
                        controller: password,
                        obscureText: obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Password required";
                          if (v.length < 6) return "Min 6 characters";
                          return null;
                        },
                        decoration: inputStyle("Password", Icons.lock_outline)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: primary,
                            ),
                            onPressed: () =>
                                setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── SIGN UP BUTTON ────────────────────────────────
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
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  selectedRole == 'company'
                                      ? "Create Company Account"
                                      : "Sign Up",
                                  style: const TextStyle(
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
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(color: primary),
                        ),
                      ),
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

// ── Role tab widget ────────────────────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}