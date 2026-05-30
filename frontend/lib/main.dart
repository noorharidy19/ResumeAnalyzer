import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'views/home/dashboard_screen.dart';
import 'core/theme_manager.dart';
import 'providers/app_providers.dart';

// ── Changed: main is now async so we can restore session before first build ──
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the provider container manually BEFORE runApp
  // so auth state is set before any widget builds (no "Guest User" flicker)
  final container = ProviderContainer();

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final email = prefs.getString('user_email');
  final name  = prefs.getString('user_name');
  final userId = prefs.getString('user_id');
  final pic   = prefs.getString('profile_picture');

  if (token != null && email != null) {
    container.read(authProvider.notifier).restoreSession(
      token:          token,
      userId:         userId ?? '', 
      userName:       name ?? '',
      userEmail:      email,
      profilePicture: pic,
    );
  }

  runApp(
    // UncontrolledProviderScope uses our pre-configured container
    // instead of creating a fresh one — this is how we pass the
    // already-restored auth state into the widget tree
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

// ── Unchanged: MyApp stays StatelessWidget, all team theme work preserved ──
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
              theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: const Color(0xFF5C6BC0),
                scaffoldBackgroundColor: const Color(0xFFF6F8FF),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(0xFF5C6BC0),
                scaffoldBackgroundColor: const Color(0xFF0F1724),
                cardColor: const Color(0xFF111827),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF0F1724),
                  foregroundColor: Colors.white70,
                  elevation: 0,
                ),
                dialogBackgroundColor: const Color(0xFF0B1622),
                canvasColor: const Color(0xFF0B1622),
              ),
              home: const DashboardScreen(),
              builder: (context, child) {
                final media = MediaQuery.of(context);
                return MediaQuery(
                  data: media.copyWith(textScaleFactor: fontScale),
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