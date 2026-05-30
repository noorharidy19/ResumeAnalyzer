import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../home/dashboard_screen.dart';
import '../company/company_dashboard_screen.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final email    = TextEditingController();
  final password = TextEditingController();

  bool obscurePassword = true;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);
  static const bg      = Color(0xFFF0F7FF);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final res = await http.post(
        Uri.parse("http://localhost:8001/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email":    email.text.trim(),
          "password": password.text.trim(),
        }),
      );

      ref.read(isLoadingProvider.notifier).state = false;
      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final user = data['user'] as Map<String, dynamic>?;

        ref.read(authProvider.notifier).login(
          token:          data['access_token'] ?? '',
          userId:         user?['id']          ?? '',
          userName:       user?['name']            ?? '',
          userEmail:      user?['email']           ?? '',
          profilePicture: user?['profile_picture'],
        );

        try {
          final prefs = await SharedPreferences.getInstance();
          if (user?['id'] != null) await prefs.setString('user_id', user!['id']);
          if (!mounted) return;
          await prefs.setString('access_token', data['access_token'] ?? '');
          await prefs.setString('user_role',    user?['role']  ?? 'user');
          await prefs.setString('user_name',    user?['name']  ?? '');
          await prefs.setString('user_email',   user?['email'] ?? '');
          if (user?['profile_picture'] != null) {
            await prefs.setString('profile_picture', user!['profile_picture']);
          }
        } catch (e) {
          debugPrint("Error saving prefs: $e");
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful ✅"),
            backgroundColor: Colors.green,
          ),
        );

        final role = user?['role'] ?? 'user';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => role == 'company'
                ? const CompanyDashboardScreen()
                : const DashboardScreen(),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? "Login failed ❌"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ref.read(isLoadingProvider.notifier).state = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.lock_outline, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Welcome Back",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primary,
                                ),
                              ),
                              Text(
                                "Sign in to continue",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Email required";
                          if (!v.contains("@")) return "Invalid email";
                          return null;
                        },
                        decoration: _inputStyle("Email", Icons.email_outlined),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: password,
                        obscureText: obscurePassword,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Password required" : null,
                        decoration: _inputStyle("Password", Icons.lock_outline)
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

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  "Login",
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen()),
                        ),
                        child: const Text(
                          "Don't have an account? Sign Up",
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

  InputDecoration _inputStyle(String hint, IconData icon) {
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