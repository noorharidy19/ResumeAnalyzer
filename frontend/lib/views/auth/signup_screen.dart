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

<<<<<<< HEAD
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
=======
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
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name":         name.text.trim(),
          "email":        email.text.trim(),
          "phone_number": phone.text.trim(),
          "password":     password.text.trim(),
<<<<<<< HEAD
          "role":         selectedRole,           // ← sends role to backend
        }),
      );

      final data = jsonDecode(res.body);

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
=======
        }),
      );

      ref.read(isLoadingProvider.notifier).state = false;

      // ── FIX: check mounted after every await before touching context ──
      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully ✅"),
            backgroundColor: Colors.green,
          ),
        );
<<<<<<< HEAD
=======

        if (!mounted) return; // ── FIX: check before Navigator ──

>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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
<<<<<<< HEAD
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
=======
      ref.read(isLoadingProvider.notifier).state = false;

      if (!mounted) return; // ── FIX ──

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection Error ❌"),
          backgroundColor: Colors.red,
        ),
      );
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── NEW: ref.watch in build ──
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
                            child: const Icon(Icons.person_add, color: primary),
=======
                            // ── FIX: withOpacity → withValues ──
                            backgroundColor: primary.withValues(alpha: 0.1),
                            child: Icon(Icons.person_add, color: primary),
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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

<<<<<<< HEAD
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
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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

<<<<<<< HEAD
                      // ── EMAIL ─────────────────────────────────────────
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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

<<<<<<< HEAD
                      // ── PHONE ─────────────────────────────────────────
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? "Phone required" : null,
                        decoration: inputStyle("Phone Number", Icons.phone_outlined),
                      ),

                      const SizedBox(height: 12),

<<<<<<< HEAD
                      // ── PASSWORD ──────────────────────────────────────
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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

<<<<<<< HEAD
                      // ── SIGN UP BUTTON ────────────────────────────────
=======
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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
<<<<<<< HEAD
                              : Text(
                                  selectedRole == 'company'
                                      ? "Create Company Account"
                                      : "Sign Up",
                                  style: const TextStyle(
=======
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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
<<<<<<< HEAD
                        child: const Text(
                          "Already have an account? Login",
                          style: TextStyle(color: primary),
                        ),
=======
                        child: const Text("Already have an account? Login"),
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
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