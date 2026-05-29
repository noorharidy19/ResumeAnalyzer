import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';
import '../resume/resume_upload_screen.dart';
import '../candidates/candidates_screen.dart';
import '../community/community_screen.dart';
import '../messages/messages_screen.dart';
import '../feed/feed_screen.dart';
import '../analytics/analytics_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_picture_viewer.dart';
import '../profile/my_profile_screen.dart';
import '../../services/message_service.dart';
import '../../services/notification_service.dart';
import '../cv_enhancement/cv_enhancement_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../core/providers.dart';           // teammate's profileProvider — unchanged
import '../../providers/app_providers.dart';  // our authProvider + isLoadingProvider

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ── REMOVED: String? userEmail, userName, profilePictureUrl, bool isLoggedIn ──
  // All of that now comes from ref.watch(authProvider) in build()

  // Unread counts stay as local state — they are NOT auth data
  int totalUnreadMessages      = 0;
  int totalUnreadNotifications = 0;

  final Color primary = const Color(0xFF7C8CF8);
  final Color bg      = const Color(0xFFF5F7FF);

  @override
  void initState() {
    super.initState();
    // ── REMOVED: loadUser() — no longer needed, auth comes from authProvider ──
    // Refresh unread counts once the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isLoggedIn) {
        _refreshUnreadCount();
        _refreshUnreadNotifications();
      }
    });
  }

  Future<void> _refreshUnreadCount() async {
    // ── Changed: read isLoggedIn from authProvider ──
    if (ref.read(authProvider).isLoggedIn) {
      final result = await MessageService.getUnreadCount();
      if (!mounted) return;
      if (!result.containsKey('error')) {
        setState(() {
          totalUnreadMessages = result['unread_count'] ?? 0;
        });
      }
    }
  }

  Future<void> _refreshUnreadNotifications() async {
    if (ref.read(authProvider).isLoggedIn) {
      final result = await NotificationService.getUnreadCount();
      if (!mounted) return;
      if (!result.containsKey('error')) {
        setState(() {
          totalUnreadNotifications = result['unread_count'] ?? 0;
        });
      }
    }
  }

  // ── REMOVED: loadUser() ──

  void requireAuth(VoidCallback callback) {
    // ── Changed: read isLoggedIn from authProvider ──
    if (ref.read(authProvider).isLoggedIn) {
      callback();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      // No .then(loadUser) needed — authProvider updates automatically on login
    }
  }

  Future<void> _logout() async {
    // 1. Clear Riverpod auth state
    ref.read(authProvider.notifier).logout();

    // 2. Clear SharedPreferences so session doesn't restore on next app start
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('profile_picture');
  }

  @override
  Widget build(BuildContext context) {
    // ── NEW: ref.watch — rebuilds whenever auth state changes ──
    final auth = ref.watch(authProvider);

    final isMobile      = ResponsiveHelper.isMobile(context);
    final isTablet      = ResponsiveHelper.isTablet(context);
    final padding       = ResponsiveHelper.getResponsivePadding(context);
    final titleFontSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobileSize:  20,
      tabletSize:  24,
      desktopSize: 32,
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: const Text("Resume Analyzer"),
          backgroundColor: primary,
          elevation: 0,
          centerTitle: true,
        ),
        drawer: _buildSidebar(auth),
        body: SingleChildScrollView(
          padding: padding,
          child: _buildMainContent(titleFontSize),
        ),
      );
    } else if (isTablet) {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  )
                ],
              ),
              child: _buildSidebarContent(auth),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: padding,
                child: _buildMainContent(titleFontSize),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: bg,
        body: Row(
          children: [
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(2, 0),
                  )
                ],
              ),
              child: _buildSidebarContent(auth),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: padding,
                child: _buildMainContent(titleFontSize),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSidebar(AuthState auth) {
    return Drawer(child: _buildSidebarContent(auth));
  }

  // ── Changed: receives AuthState as parameter instead of reading local vars ──
  Widget _buildSidebarContent(AuthState auth) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Teammate's ProfilePictureViewer logic — fully preserved ──
              GestureDetector(
                onTap: auth.isLoggedIn
                    ? () async {
                        await showDialog(
                          context: context,
                          builder: (_) => ProfilePictureViewer(
                            // ── Changed: reads from auth instead of local vars ──
                            profilePictureUrl: auth.profilePicture ?? '',
                            userName:          auth.userName       ?? '',
                            userEmail:         auth.userEmail      ?? '',
                            onPictureUpdated: () async {
                              // ── Teammate's profileProvider refresh — unchanged ──
                              await ref.read(profileProvider.notifier).refresh();
                              final profile = ref.read(profileProvider);
                              // Also update authProvider so sidebar refreshes
                              if (profile.profilePicture != null) {
                                ref.read(authProvider.notifier).updateProfilePicture(
                                  profile.profilePicture!,
                                );
                              }
                            },
                          ),
                        );
                      }
                    : null,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    // ── Changed: auth.profilePicture instead of profilePictureUrl ──
                    image: auth.profilePicture != null &&
                            auth.profilePicture!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(
<<<<<<< HEAD
                              'http://localhost:8001/${profilePictureUrl!.replaceAll(r'\\', '/')}',
=======
                              'http://10.0.2.2:8001/${auth.profilePicture!.replaceAll(r'\\', '/')}',
>>>>>>> 03014fbd869b5f87bab394423e18c6467473d0c2
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: auth.profilePicture == null ||
                          auth.profilePicture!.isEmpty
                      ? Icon(Icons.person, color: primary, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // ── Changed: auth.userName instead of userName ──
              Text(
                auth.userName ?? 'Guest User',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              // ── Changed: auth.userEmail instead of userEmail ──
              Text(
                auth.userEmail ?? 'not logged in',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // ── Changed: auth.isLoggedIn instead of isLoggedIn ──
              if (!auth.isLoggedIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                    ),
                    child: const Text('Login'),
                  ),
                ),

              if (auth.isLoggedIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // ── Changed: calls _logout() which uses ref.read ──
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Logout'),
                  ),
                ),
            ],
          ),
        ),

        // Menu items — unchanged
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _sideItem(Icons.home,          "Dashboard",       true),
              _sideItem(Icons.person,        "My Profile",      false),
              _sideItem(Icons.description,   "Resume Analyzer", false),
              _sideItem(Icons.people,        "Candidates",      false),
              _sideItem(Icons.forum,         "Community",       false),
              _sideItem(Icons.mail,          "Messages",        false, badgeCount: totalUnreadMessages),
              _sideItem(Icons.feed,          "Feed",            false),
              _sideItem(Icons.notifications, "Notifications",   false, badgeCount: totalUnreadNotifications),
              _sideItem(Icons.analytics,     "Analytics",       false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(double titleFontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome to Resume Analyzer",
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your AI-powered recruitment platform.",
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Getting Started",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                ResponsiveHelper.isMobile(context)
                    ? "Tap the menu to navigate features:"
                    : "Use the menu on the left to navigate through different features:",
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              _featureItem("📄", "Resume Analyzer",  "Upload and analyze your resume with AI-powered insights"),
              _featureItem("👥", "Candidates",        "Browse and connect with other professionals"),
              _featureItem("💬", "Community",         "Join discussions and share your experience"),
              _featureItem("✉️", "Messages",          "Communicate with connections"),
              _featureItem("📰", "Feed",              "View posts from your network"),
              _featureItem("📊", "Analytics",         "View detailed analytics and history"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(IconData icon, String title, bool active,
      {int badgeCount = 0}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? primary.withValues(alpha: 0.15)
            : Colors.transparent,
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
                  decoration: const BoxDecoration(
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
          if (title == "My Profile") {
            requireAuth(() => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyProfileScreen())));
          } else if (title == "Resume Analyzer") {
            requireAuth(() => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ResumeUploadScreen())));
          } else if (title == "Candidates") {
            requireAuth(() => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CandidatesScreen())));
          } else if (title == "Community") {
            requireAuth(() => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CommunityScreen())));
          } else if (title == "Messages") {
            requireAuth(() => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MessagesScreen()))
                .then((_) => _refreshUnreadCount()));
          } else if (title == "Feed") {
            requireAuth(() => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FeedScreen())));
          } else if (title == "Notifications") {
            requireAuth(() => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()))
                .then((_) => _refreshUnreadNotifications()));
          } else if (title == "Analytics") {
            requireAuth(() => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen())));
          }
        },
      ),
    );
  }
}