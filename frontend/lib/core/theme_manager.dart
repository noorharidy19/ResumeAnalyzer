import 'package:flutter/material.dart';

/// Global theme notifier used across the app.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

/// Global font scale notifier (1.0 = 100%).
final ValueNotifier<double> fontNotifier = ValueNotifier<double>(1.0);
