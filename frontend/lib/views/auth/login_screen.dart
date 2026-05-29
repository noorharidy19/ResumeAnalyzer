import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';
import '../home/dashboard_screen.dart';
import '../company/company_dashboard_screen.dart';
import '../../utils/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import '../home/dashboard_screen.dart';
import '../../providers/app_providers.dart';

// ── Changed: StatefulWidget → ConsumerStatefulWidget ──
class LoginScreen extends ConsumerStatefulWidget {
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

<<<<<<< HEAD
class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final email    = TextEditingController();
  final password = TextEditingController();

  bool isLoading      = false;
  bool obscurePassword = true;

  // ── Same colors as SignupScreen ──────────────────────────────────────────
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
    setState(() => isLoading = true);
=======
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
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2

    try {
      final res = await http.post(
        Uri.parse("http://localhost:8001/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
<<<<<<< HEAD
          "email":    email.text.trim(),
          "password": password.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        // ── Save token + user info ─────────────────────────────────────────
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('user_role',    data['user']['role']  ?? 'user');
        await prefs.setInt('user_id',         data['user']['id']);
        await prefs.setString('user_name',    data['user']['name']  ?? '');
        await prefs.setString('user_email',   data['user']['email'] ?? '');

        if (!mounted) return;

        // ── Route based on role ────────────────────────────────────────────
        final role = data['user']['role'] ?? 'user';

        if (role == 'company') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CompanyDashboardScreen()),
          );
        } else {
          // role == 'user' (or anything else)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
=======
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
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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
<<<<<<< HEAD
      if (!mounted) return;
=======
      ref.read(isLoadingProvider.notifier).state = false;

      if (!mounted) return; // ── FIX ──

>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Connection error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── NEW: ref.watch in build — rebuilds button when isLoading changes ──
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
<<<<<<< HEAD
                      // ── HEADER ────────────────────────────────────────
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
<<<<<<< HEAD
                            backgroundColor: primary.withOpacity(0.1),
                            child: const Icon(Icons.lock_outline, color: primary),
=======
                            // ── FIX: withOpacity → withValues ──
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Icon(Icons.person, color: primary),
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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

<<<<<<< HEAD
                      // ── EMAIL ─────────────────────────────────────────
                      TextFormField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Email required";
                          if (!v.contains("@")) return "Invalid email";
=======
                      TextFormField(
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Email required";
                          if (!value.contains("@")) return "Invalid email";
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
                          return null;
                        },
                        decoration: _inputStyle("Email", Icons.email_outlined),
                      ),

                      const SizedBox(height: 12),

<<<<<<< HEAD
                      // ── PASSWORD ──────────────────────────────────────
                      TextFormField(
                        controller: password,
                        obscureText: obscurePassword,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Password required" : null,
                        decoration: _inputStyle(
                          "Password",
                          Icons.lock_outline,
                        ).copyWith(
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
=======
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Password required";
                          return null;
                        },
                        decoration: inputStyle("Password", Icons.lock),
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
                      ),

                      const SizedBox(height: 24),

<<<<<<< HEAD
                      // ── LOGIN BUTTON ──────────────────────────────────
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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

                      // ── SIGNUP LINK ───────────────────────────────────
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