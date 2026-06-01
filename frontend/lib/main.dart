import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/home/dashboard_screen.dart';
import 'core/theme_manager.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  final prefs  = await SharedPreferences.getInstance();
  final token  = prefs.getString('access_token');
  final email  = prefs.getString('user_email');
  final name   = prefs.getString('user_name');
  final userId = prefs.getString('user_id');
  final pic    = prefs.getString('profile_picture');

  if (token != null && email != null) {
    container.read(authProvider.notifier).restoreSession(
      token:          token,
      userId:         userId ?? '',
      userName:       name   ?? '',
      userEmail:      email,
      profilePicture: pic,
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child:     const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: fontNotifier,
          builder: (context, fontScale, __) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              themeMode: mode,

              // ── Light theme ──────────────────────────────────────────
              theme: ThemeData(
                brightness:              Brightness.light,
                primaryColor:            const Color(0xFF7C8CF8),
                scaffoldBackgroundColor: const Color(0xFFF5F7FF),
                cardColor:               Colors.white,
                dividerColor:            const Color(0xFFE0E0E0),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF7C8CF8),
                  foregroundColor: Colors.white,
                  elevation:       0,
                ),
                colorScheme: const ColorScheme.light(
                  primary:   Color(0xFF7C8CF8),
                  surface:   Colors.white,
                  onSurface: Colors.black87,
                  onPrimary: Colors.white,
                ),
                textTheme: const TextTheme(
                  bodySmall:  TextStyle(color: Color(0xFF757575)),
                  bodyMedium: TextStyle(color: Color(0xFF424242)),
                  bodyLarge:  TextStyle(color: Colors.black87),
                ),
              ),

              // ── Dark theme ───────────────────────────────────────────
              darkTheme: ThemeData(
                brightness:              Brightness.dark,
                primaryColor:            const Color(0xFF7C8CF8),
                scaffoldBackgroundColor: const Color(0xFF0F1724),
                cardColor:               const Color(0xFF1E2A3A),
                dividerColor:            const Color(0xFF2E3D50),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF7C8CF8),
                  foregroundColor: Colors.white,
                  elevation:       0,
                ),
                dialogBackgroundColor: const Color(0xFF1E2A3A),
                canvasColor:           const Color(0xFF1E2A3A),
                colorScheme: const ColorScheme.dark(
                  primary:   Color(0xFF7C8CF8),
                  surface:   Color(0xFF1E2A3A),
                  onSurface: Colors.white,
                  onPrimary: Colors.white,
                ),
                textTheme: const TextTheme(
                  bodySmall:  TextStyle(color: Color(0xFF9BA8B8)),
                  bodyMedium: TextStyle(color: Color(0xFFCDD5E0)),
                  bodyLarge:  TextStyle(color: Colors.white),
                ),
              ),

              home: const DashboardScreen(),
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(textScaler: TextScaler.linear(fontScale)),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        );
      },
    );
  }
}