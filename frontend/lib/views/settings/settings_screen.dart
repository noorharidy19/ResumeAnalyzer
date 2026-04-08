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
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<ThemeMode>(
                            valueListenable: themeNotifier,
                            builder: (context, mode, _) {
                              final isDark = mode == ThemeMode.dark;
                              return SwitchListTile(
                                title: const Text('Dark Mode'),
                                value: isDark,
                                onChanged: (v) {
                                  themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
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
                                  value: fontValue,
                                  min: 0.8,
                                  max: 1.4,
                                  divisions: 6,
                                  label: '${(fontValue * 100).round()}%',
                                  onChanged: (v) => fontNotifier.value = v,
                                );
                              },
                            ),
                          ),

                          const Divider(),

                          const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Enable notifications'),
                            value: _notifications,
                            onChanged: (v) => setState(() => _notifications = v),
                          ),

                          const Divider(),

                          const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Edit profile'),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title: const Text('Change password'),
                            onTap: () {},
                          ),

                          const Divider(),

                          const Text('Storage & Privacy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.delete_outline),
                            title: const Text('Clear cache'),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared (mock)')));
                            },
                          ),

                          const Divider(),

                          const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: const Text('App version'),
                            subtitle: const Text('0.1.0'),
                          ),
                          // 'Send feedback' removed as requested
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
