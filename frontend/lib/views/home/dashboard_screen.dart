import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/login_screen.dart';
import '../resume/upload_resume_screen.dart';
import '../candidates/candidates_screen.dart';
import '../community/community_screen.dart';
import '../messages/messages_screen.dart';
import '../feed/feed_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_picture_viewer.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../../services/user_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userEmail;
  String? userName;
  String? profilePictureUrl;
  bool isLoggedIn = false;
  int totalUnreadMessages = 0;
  int totalUnreadNotifications = 0;

  final Color primary = const Color(0xFF7C8CF8); // pastel blue
  final Color bg = const Color(0xFFF5F7FF);

  @override
  void initState() {
    super.initState();
    loadUser();
    _refreshUnreadCount();
    _refreshUnreadNotifications();
  }

  Future<void> _refreshUnreadCount() async {
    if (isLoggedIn) {
      final result = await MessageService.getUnreadCount();
      if (!result.containsKey('error')) {
        setState(() {
          totalUnreadMessages = result['unread_count'] ?? 0;
        });
      }
    }
  }

  Future<void> _refreshUnreadNotifications() async {
    if (isLoggedIn) {
      final result = await NotificationService.getUnreadCount();
      if (!result.containsKey('error')) {
        setState(() {
          totalUnreadNotifications = result['unread_count'] ?? 0;
        });
      }
    }
  }

  void loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userEmail = prefs.getString("user_email");
      userName = prefs.getString("user_name");
      profilePictureUrl = prefs.getString("profile_picture");
      isLoggedIn = userEmail != null;
    });
    
    // Load unread count after login status is set
    if (isLoggedIn) {
      await Future.delayed(const Duration(milliseconds: 300));
      _refreshUnreadCount();
    }
  }

  void requireAuth(VoidCallback action) {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login first")),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      action();
    }
  }

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      isLoggedIn = false;
      userEmail = null;
      userName = null;
      profilePictureUrl = null;
    });
  }

  Future<void> _uploadProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile picture...')),
        );

        final result = await UserService.uploadProfilePicture(bytes, image.name);

        if (!result.containsKey('error')) {
          final profilePicture = result['profile_picture'] as String?;
          
          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          if (profilePicture != null) {
            await prefs.setString('profile_picture', profilePicture);
          }
          
          setState(() {
            profilePictureUrl = profilePicture;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated! ✓'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [

          // 🟣 SIDEBAR
          Container(
            width: 240,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [

                const SizedBox(height: 30),

                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primary.withOpacity(0.2),
                      child: Icon(Icons.auto_graph, color: primary),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "ATS Analyzer",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                // show logged-in user's name in sidebar
                if (isLoggedIn) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Hi, ${userName ?? userEmail ?? ''} 👋",
                      style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _sideItem(Icons.dashboard, "Dashboard", true),
                        _sideItem(Icons.description, "Resume Analyzer", false),
                        _sideItem(Icons.people, "Candidates", false),
                        _sideItem(Icons.work, "Jobs", false),
                        _sideItem(Icons.message, "Messages", false, badgeCount: totalUnreadMessages),
                        _sideItem(Icons.article, "Feed", false),
                        _sideItem(Icons.notifications, "Notifications", false, badgeCount: totalUnreadNotifications),
                        _sideItem(Icons.forum, "Community", false),
                        _sideItem(Icons.bar_chart, "Analytics", false),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(isLoggedIn ? "Logout" : "Login"),
                  onTap: () {
                    if (isLoggedIn) {
                      logout();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // 🟦 MAIN CONTENT
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "ATS Resume Analyzer",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isLoggedIn ? "Welcome, ${userName ?? userEmail ?? ''}" : "Welcome, Guest",
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: [
                          // User Profile Section
                          if (isLoggedIn)
                            Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        userName ?? userEmail ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        userEmail ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: profilePictureUrl != null
                                            ? () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => ProfilePictureViewer(
                                                    profilePictureUrl: profilePictureUrl!,
                                                    userName: userName ?? userEmail ?? 'User',
                                                    userEmail: userEmail ?? '',
                                                    onPictureUpdated: () {
                                                      setState(() {
                                                        // Reload the picture
                                                      });
                                                    },
                                                  ),
                                                );
                                              }
                                            : null,
                                        child: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: primary.withOpacity(0.2),
                                          backgroundImage: profilePictureUrl != null
                                              ? NetworkImage(
                                                  'http://localhost:8001/${profilePictureUrl!}'
                                                )
                                              : null,
                                          child: profilePictureUrl == null
                                              ? Text(
                                                  (userName ?? userEmail ?? 'U')[0].toUpperCase(),
                                                  style: TextStyle(
                                                    color: primary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: _uploadProfilePicture,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: primary,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          _topButton("Demo Mode"),
                          const SizedBox(width: 10),
                          _topButton("Connect"),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "AI-powered recruitment insights and candidate analysis.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 25),

                  // STATS
                  Row(
                    children: [
                      _statCard("2", "Total Resumes", Icons.description),
                      _statCard("2", "Candidates", Icons.people),
                      _statCard("90%", "Avg Match", Icons.star),
                      _statCard("12 days", "Processing", Icons.timer),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // CHART AREA (UI ONLY)
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _bigCard("Monthly Applications")),
                        const SizedBox(width: 20),
                        Expanded(child: _bigCard("Top Skills Detected")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ---------------- UI WIDGETS ----------------

  Widget _sideItem(IconData icon, String title, bool active, {int badgeCount = 0}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: active ? primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Icon(icon, color: active ? primary : Colors.grey),
            if (badgeCount > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(title),
        onTap: () {
          if (title == "Resume Analyzer") {
            requireAuth(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadResumeScreen()),
              );
            });
          } else if (title == "Candidates") {
            requireAuth(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CandidatesScreen()),
              );
            });
          } else if (title == "Community") {
            requireAuth(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CommunityScreen()),
              );
            });
          } else if (title == "Messages") {
            requireAuth(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              ).then((_) {
                _refreshUnreadCount();
              });
            });
          } else if (title == "Feed") {
            requireAuth(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FeedScreen()),
              );
            });
          } else if (title == "Notifications") {
            requireAuth(() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ).then((_) {
                _refreshUnreadNotifications();
              });
            });
          } else {
            // other navigation placeholders
          }
        },
      ),
    );
  }

  Widget _statCard(String value, String title, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

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
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Center(child: Text("Chart Placeholder")),
        ],
      ),
    );
  }

  Widget _topButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: primary)),
    );
  }
}