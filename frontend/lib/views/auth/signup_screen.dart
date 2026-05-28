import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import '../../providers/app_providers.dart';

// ── Changed: StatefulWidget → ConsumerStatefulWidget ──
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

// ── Changed: State → ConsumerState ──
class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final name     = TextEditingController();
  final email    = TextEditingController();
  final phone    = TextEditingController();
  final password = TextEditingController();

  final primary = const Color(0xFF5C6BC0);
  final accent  = const Color(0xFF3F51B5);

  // ── REMOVED: bool isLoading — now lives in isLoadingProvider ──

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    // ── Changed: setState → ref.read ──
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final res = await http.post(
        Uri.parse("http://10.0.2.2:8001/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name":         name.text.trim(),
          "email":        email.text.trim(),
          "phone_number": phone.text.trim(),
          "password":     password.text.trim(),
        }),
      );

      ref.read(isLoadingProvider.notifier).state = false;

      // ── FIX: check mounted after every await before touching context ──
      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully ✅"),
            backgroundColor: Colors.green,
          ),
        );

        if (!mounted) return; // ── FIX: check before Navigator ──

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
      ref.read(isLoadingProvider.notifier).state = false;

      if (!mounted) return; // ── FIX ──

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection Error ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── NEW: ref.watch in build ──
    final isLoading = ref.watch(isLoadingProvider);

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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            // ── FIX: withOpacity → withValues ──
                            backgroundColor: primary.withValues(alpha: 0.1),
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

                      TextFormField(
                        controller: name,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Name required" : null,
                        decoration: inputStyle("Full Name", Icons.person),
                      ),

                      const SizedBox(height: 12),

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

                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Phone required" : null,
                        decoration: inputStyle("Phone Number", Icons.phone),
                      ),

                      const SizedBox(height: 12),

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