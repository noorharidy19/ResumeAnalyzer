import 'package:flutter/material.dart';
import 'views/home/dashboard_screen.dart';
import 'core/theme_manager.dart';

void main() {
  runApp(const MyApp());
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
              theme: ThemeData(
                brightness: Brightness.light,
                primaryColor: const Color(0xFF5C6BC0),
                scaffoldBackgroundColor: const Color(0xFFF6F8FF),
                appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(0xFF5C6BC0),
                // Softer dark palette (not pure black)
                scaffoldBackgroundColor: const Color(0xFF0F1724),
                cardColor: const Color(0xFF111827),
                appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F1724), foregroundColor: Colors.white70, elevation: 0),
                dialogBackgroundColor: const Color(0xFF0B1622),
                canvasColor: const Color(0xFF0B1622),
              ),
              home: const DashboardScreen(),
              builder: (context, child) {
                // Apply global text scale factor
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