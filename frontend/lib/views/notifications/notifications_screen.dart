import 'package:flutter/material.dart';
import '../../services/notification_service.dart' as notif_service;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg = const Color(0xFFF5F7FF);
  
  List<notif_service.Notification> notifications = [];
  bool isLoading = true;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    final result = await notif_service.NotificationService.getNotifications();
    
    if (!result.containsKey('error')) {
      setState(() {
        notifications = result['notifications'] ?? [];
        unreadCount = result['unread_count'] ?? 0;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
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

  Future<void> _markAsRead(String notificationId) async {
    final result = await notif_service.NotificationService.markAsRead(notificationId);

    if (!result.containsKey('error')) {
      _loadNotifications();
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await notif_service.NotificationService.markAllAsRead();

    if (!result.containsKey('error')) {
      _loadNotifications();
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'connection_request':
        return 'Connection Request';
      case 'connection_accepted':
        return 'Connection Accepted';
      case 'message':
        return 'New Message';
      case 'post':
        return 'New Post';
      case 'post_like':
        return 'Liked Your Post';
      default:
        return 'Notification';
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'connection_request':
        return '👤';
      case 'connection_accepted':
        return '✓';
      case 'message':
        return '💬';
      case 'post':
        return '📝';
      case 'post_like':
        return '❤️';
      default:
        return '🔔';
    }
  }

  String _formatTime(DateTime dateTime) {
    final utcTime = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final nowUtc = DateTime.now().toUtc();
    final difference = nowUtc.difference(utcTime);

    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 20),
              label: const Text('Mark all read'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            )
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: notif.isRead ? Colors.white : primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: notif.isRead ? Colors.grey[200]! : primary.withOpacity(0.3),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _getNotificationIcon(notif.notificationType),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        title: Text(
                          '${notif.triggeredBy?['name'] ?? 'Someone'} ${_getNotificationTitle(notif.notificationType).toLowerCase()}',
                          style: TextStyle(
                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          _formatTime(notif.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        trailing: notif.isRead
                            ? null
                            : GestureDetector(
                                onTap: () => _markAsRead(notif.id),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                        onTap: () => _markAsRead(notif.id),
                      ),
                    );
                  },
                ),
    );
  }
}
