import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import '../../providers/app_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final name     = TextEditingController();
  final email    = TextEditingController();
  final phone    = TextEditingController();
  final password = TextEditingController();

  bool   obscurePassword = true;
  String selectedRole    = 'user';

  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

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
    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final res = await http.post(
        Uri.parse('http://localhost:8001/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name':         name.text.trim(),
          'email':        email.text.trim(),
          'phone_number': phone.text.trim(),
          'password':     password.text.trim(),
          'role':         selectedRole,
        }),
      );

      ref.read(isLoadingProvider.notifier).state = false;
      if (!mounted) return;

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:         Text('Account created successfully ✅'),
            backgroundColor: Colors.green,
          ),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(data['detail'] ?? 'Signup failed ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ref.read(isLoadingProvider.notifier).state = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF0F7FF),
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

                      // ── Header ───────────────────────────────────────
                      Row(
                        children: [
                          CircleAvatar(
                            radius:          28,
                            backgroundColor: _primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person_add, color: _primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize:   20,
                                  fontWeight: FontWeight.bold,
                                  color:      _primary,
                                ),
                              ),
                              Text(
                                'Sign up to continue',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Role selector ────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Theme.of(context).colorScheme.surface
                              : const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _primary.withValues(alpha: 0.2)),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            _RoleTab(
                              label:    'Job Seeker',
                              icon:     Icons.person_outline,
                              selected: selectedRole == 'user',
                              onTap:    () =>
                                  setState(() => selectedRole = 'user'),
                            ),
                            _RoleTab(
                              label:    'Company',
                              icon:     Icons.business_outlined,
                              selected: selectedRole == 'company',
                              onTap:    () =>
                                  setState(() => selectedRole = 'company'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Name ─────────────────────────────────────────
                      TextFormField(
                        controller: name,
                        validator:  (v) => (v == null || v.isEmpty)
                            ? 'Name required'
                            : null,
                        decoration: _inputStyle(
                          selectedRole == 'company'
                              ? 'Company Name'
                              : 'Full Name',
                          selectedRole == 'company'
                              ? Icons.business_outlined
                              : Icons.person_outline,
                          fillColor,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Email ────────────────────────────────────────
                      TextFormField(
                        controller:   email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                        decoration:
                            _inputStyle('Email', Icons.email_outlined, fillColor),
                      ),

                      const SizedBox(height: 12),

                      // ── Phone ────────────────────────────────────────
                      TextFormField(
                        controller:   phone,
                        keyboardType: TextInputType.phone,
                        validator:    (v) => (v == null || v.isEmpty)
                            ? 'Phone required'
                            : null,
                        decoration: _inputStyle(
                            'Phone Number', Icons.phone_outlined, fillColor),
                      ),

                      const SizedBox(height: 12),

                      // ── Password ─────────────────────────────────────
                      TextFormField(
                        controller:  password,
                        obscureText: obscurePassword,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password required';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                        decoration:
                            _inputStyle('Password', Icons.lock_outline, fillColor)
                                .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _primary,
                            ),
                            onPressed: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Submit ───────────────────────────────────────
                      SizedBox(
                        width:  double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(
                                  selectedRole == 'company'
                                      ? 'Create Company Account'
                                      : 'Sign Up',
                                  style: const TextStyle(
                                    color:      Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize:   16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(color: _primary),
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

  InputDecoration _inputStyle(String hint, IconData icon, Color fillColor) {
    return InputDecoration(
      hintText:   hint,
      prefixIcon: Icon(icon, color: _primary),
      filled:     true,
      fillColor:  fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:   BorderSide.none,
      ),
    );
  }
}

// ── Role tab widget ────────────────────────────────────────────────────────────
class _RoleTab extends StatelessWidget {
  final String       label;
  final IconData     icon;
  final bool         selected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

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
            color:        selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size:  18,
                  color: selected ? Colors.white : _primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize:   13,
                  color:      selected ? Colors.white : _primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}