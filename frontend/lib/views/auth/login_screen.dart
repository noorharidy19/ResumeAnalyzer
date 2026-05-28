import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../home/dashboard_screen.dart';
import '../../providers/app_providers.dart';

// ── Changed: StatefulWidget → ConsumerStatefulWidget ──
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

// ── Changed: State → ConsumerState (gives access to ref) ──
class _LoginScreenState extends ConsumerState<LoginScreen> {
  final primary = const Color(0xFF5C6BC0);
  final accent  = const Color(0xFF3F51B5);

  final _formKey          = GlobalKey<FormState>();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  // ── REMOVED: bool isLoading — now lives in isLoadingProvider ──

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    // ── Changed: setState → ref.read (callback, not build) ──
    ref.read(isLoadingProvider.notifier).state = true;

    final url = Uri.parse("http://10.0.2.2:8001/auth/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email":    emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      ref.read(isLoadingProvider.notifier).state = false;

      // ── FIX: check mounted after every await before touching context ──
      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'] as Map<String, dynamic>?;

        // ── NEW: store user in Riverpod so all screens see it instantly ──
        ref.read(authProvider.notifier).login(
          token:          data['access_token'] ?? '',
          userName:       user?['name']            ?? '',
          userEmail:      user?['email']           ?? '',
          profilePicture: user?['profile_picture'],
        );

        // Still save to SharedPreferences so session survives app restart
        try {
          final prefs = await SharedPreferences.getInstance();
          if (!mounted) return; // ── FIX: check after every await ──
          if (data['access_token'] != null) {
            await prefs.setString('access_token', data['access_token']);
          }
          if (user?['email']           != null) await prefs.setString('user_email',      user!['email']);
          if (user?['name']            != null) await prefs.setString('user_name',       user!['name']);
          if (user?['profile_picture'] != null) await prefs.setString('profile_picture', user!['profile_picture']);
        } catch (e) {
          debugPrint("Error saving prefs: $e");
        }

        if (!mounted) return; // ── FIX: check before Navigator and SnackBar ──

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful ✅"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['detail'] ?? "Login failed ❌"),
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
    // ── NEW: ref.watch in build — rebuilds button when isLoading changes ──
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                            child: Icon(Icons.person, color: primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Welcome Back",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: primary)),
                              const Text("Login to continue",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Email required";
                          if (!value.contains("@")) return "Invalid email";
                          return null;
                        },
                        decoration: inputStyle("Email", Icons.email),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Password required";
                          return null;
                        },
                        decoration: inputStyle("Password", Icons.lock),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
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

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text("Don't have an account? Sign Up"),
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