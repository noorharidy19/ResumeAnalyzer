import 'package:flutter/material.dart';
import '../../core/theme_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation:       0,
        leading: BackButton(color: Theme.of(context).primaryColor),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Card(
                    elevation: 4,
                    color:     Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Appearance ──────────────────────────────
                          const Text('Appearance',
                              style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (context, mode, _) {
                              final isDark = mode == ThemeMode.dark;
                              return SwitchListTile(
                                title:     const Text('Dark Mode'),
                                value:     isDark,
                                activeColor: Theme.of(context).primaryColor,
                                onChanged: (v) {
                                  themeNotifier.value =
                                      v ? ThemeMode.dark : ThemeMode.light;
                                },
                              );
                            },
                          ),
                          ListTile(
                            title: const Text('Font size'),
                            subtitle: ValueListenableBuilder<double>(
                              valueListenable: fontNotifier,
                              builder: (context, fontValue, _) {
                                return Slider(
                                  value:     fontValue,
                                  min:       0.8,
                                  max:       1.4,
                                  divisions: 6,
                                  activeColor: Theme.of(context).primaryColor,
                                  label:     '${(fontValue * 100).round()}%',
                                  onChanged: (v) => fontNotifier.value = v,
                                );
                              },
                            ),
                          ),

                          const Divider(),

                          // ── Preferences ─────────────────────────────
                          const Text('Preferences',
                              style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title:       const Text('Enable notifications'),
                            value:       _notifications,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged:   (v) =>
                                setState(() => _notifications = v),
                          ),

                          const Divider(),

                          // ── Account ─────────────────────────────────
                          const Text('Account',
                              style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title:   const Text('Edit profile'),
                            onTap:   () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title:   const Text('Change password'),
                            onTap:   () {},
                          ),

                          const Divider(),

                          // ── Storage & Privacy ────────────────────────
                          const Text('Storage & Privacy',
                              style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title:   const Text('Clear cache'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Cache cleared (mock)')));
                            },
                          ),

                          const Divider(),

                          // ── About ────────────────────────────────────
                          const Text('About',
                              style: TextStyle(
                                  fontSize:   16,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const ListTile(
                            leading:  Icon(Icons.info_outline),
                            title:    Text('App version'),
                            subtitle: Text('0.1.0'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}