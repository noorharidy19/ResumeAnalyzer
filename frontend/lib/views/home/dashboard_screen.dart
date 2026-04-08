import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';
import '../resume/upload_resume_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primary = const Color(0xFF5C6BC0); // pastel blue
  final Color bg = const Color(0xFFF4F7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      body: Row(
        children: [

          // 🟦 Sidebar
          Container(
            width: 220,
            color: const Color(0xFFF8FAFF),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: Icon(Icons.analytics, color: primary),
                  ),
                  title: const Text(
                    "Resume Analyzer",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                _menuItem(Icons.dashboard, "Dashboard", true),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Resume Analyzer'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UploadResumeScreen()));
                  },
                ),
                _menuItem(Icons.people, "Candidates", false),
                _menuItem(Icons.work, "Jobs", false),
                _menuItem(Icons.message_outlined, "Messages", false),
                _menuItem(Icons.forum_outlined, "Community", false),
                _menuItem(Icons.bar_chart, "Analytics", false),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login'),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                ),
              ],
            ),
          ),

          // 🟦 Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🔝 Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Resume Analyzer",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🟦 Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(width: 6, height: 42, decoration: BoxDecoration(color: primary.withOpacity(0.12), borderRadius: BorderRadius.circular(4))),
                        const SizedBox(width: 12),
                        const Expanded(child: Text("Welcome back — here's your dashboard.")),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 📊 Stats Cards
                  Row(
                    children: [
                      _statCard("Total Resumes", "12", Icons.description),
                      _statCard("Candidates", "8", Icons.people),
                      _statCard("Match Score", "90%", Icons.star),
                      _statCard("Processing", "2 days", Icons.timer),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // 📈 Charts Section
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _bigCard("Monthly Applications")),
                        const SizedBox(width: 20),
                        Expanded(child: _bigCard("Top Skills")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🧩 Sidebar Item
  Widget _menuItem(IconData icon, String title, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: active ? primary : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            color: active ? primary : Colors.grey[700],
          ),
        ),
        onTap: () {},
      ),
    );
  }

  // 📊 Small Cards
  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // 📈 Big Cards
  Widget _bigCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Center(child: Text("Chart Placeholder")),
        ],
      ),
    );
  }
}