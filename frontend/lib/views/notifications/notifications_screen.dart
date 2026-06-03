import 'package:flutter/material.dart';
import '../../services/notification_service.dart' as notif_service;
import '../../utils/responsive_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<notif_service.Notification> notifications = [];
  bool    isLoading  = true;
  int     unreadCount = 0;

  // ── Local state for interactivity ─────────────────────────────────────────
  final Set<String>    _favorites   = {};          // favorited notification ids
  String               _sortBy      = 'newest';    // newest | oldest | unread

  // ── Sort options ──────────────────────────────────────────────────────────
  static const _sortOptions = {
    'newest': 'Newest First',
    'oldest': 'Oldest First',
    'unread': 'Unread First',
  };

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => isLoading = true);
    final result = await notif_service.NotificationService.getNotifications();
    if (!result.containsKey('error')) {
      setState(() {
        notifications = result['notifications'] ?? [];
        unreadCount   = result['unread_count']  ?? 0;
        isLoading     = false;
      });
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Error: ${result['error']}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final result =
        await notif_service.NotificationService.markAsRead(notificationId);
    if (!result.containsKey('error')) _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    final result = await notif_service.NotificationService.markAllAsRead();
    if (!result.containsKey('error')) _loadNotifications();
  }

  // ── Favorite toggle ───────────────────────────────────────────────────────
  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  // ── Delete with undo ──────────────────────────────────────────────────────
  void _deleteNotification(notif_service.Notification notif, int index) {
  setState(() => notifications.removeAt(index));

  bool undone = false;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content:  const Text('Notification deleted'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label:     'Undo',
        textColor: Colors.yellow,
        onPressed: () {
          undone = true;
          setState(() => notifications.insert(index, notif));
        },
      ),
    ),
  ).closed.then((_) async {
    if (!undone) {
      await notif_service.NotificationService.deleteNotification(notif.id);
    }
  });
}

  // ── Sorted list ───────────────────────────────────────────────────────────
  List<notif_service.Notification> get _sorted {
    final list = List<notif_service.Notification>.from(notifications);
    switch (_sortBy) {
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'unread':
        list.sort((a, b) {
          if (a.isRead == b.isRead) return b.createdAt.compareTo(a.createdAt);
          return a.isRead ? 1 : -1;
        });
      default: // newest
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _getNotificationTitle(String type) {
    switch (type) {
      case 'connection_request':  return 'Connection Request';
      case 'connection_accepted': return 'Connection Accepted';
      case 'message':             return 'New Message';
      case 'post':                return 'New Post';
      case 'post_like':           return 'Liked Your Post';
      default:                    return 'Notification';
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'connection_request':  return '👤';
      case 'connection_accepted': return '✓';
      case 'message':             return '💬';
      case 'post':                return '📝';
      case 'post_like':           return '❤️';
      default:                    return '🔔';
    }
  }

  String _formatTime(DateTime dateTime) {
    final utcTime   = dateTime.isUtc ? dateTime : dateTime.toUtc();
    final nowUtc    = DateTime.now().toUtc();
    final diff      = nowUtc.difference(utcTime);
    if (diff.inSeconds < 60)  return 'now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24)  return '${diff.inHours}h ago';
    if (diff.inDays    == 1)  return 'Yesterday';
    if (diff.inDays    < 7)   return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile     = ResponsiveHelper.isMobile(context);
    final primary      = Theme.of(context).primaryColor;
    final cardColor    = Theme.of(context).cardColor;
    final hintColor    = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;
    final sorted       = _sorted;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:           const Text('Notifications'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
        centerTitle:     isMobile,
        actions: [
          // ── Sort dropdown ─────────────────────────────────────────
          PopupMenuButton<String>(
            icon:         const Icon(Icons.sort, color: Colors.white),
            tooltip:      'Sort',
            onSelected:   (v) => setState(() => _sortBy = v),
            itemBuilder:  (_) => _sortOptions.entries
                .map((e) => PopupMenuItem(
                      value: e.key,
                      child: Row(children: [
                        if (_sortBy == e.key)
                          const Icon(Icons.check, size: 16)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(e.value),
                      ]),
                    ))
                .toList(),
          ),
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon:      const Icon(Icons.done_all, size: 20),
              label:     const Text('Mark all read'),
              style:     TextButton.styleFrom(foregroundColor: Colors.white),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primary)))
          : sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: isMobile ? 36 : 48, color: hintColor),
                      const SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(
                              color:    hintColor,
                              fontSize: isMobile ? 14 : 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:   EdgeInsets.all(isMobile ? 8 : 12),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final notif      = sorted[index];
                    final isFav      = _favorites.contains(notif.id);
                    // find real index in mutable list for delete/undo
                    final realIndex  = notifications.indexOf(notif);

                    return Dismissible(
                      key:             ValueKey(notif.id),
                      direction:       DismissDirection.endToStart,
                      onDismissed:     (_) =>
                          _deleteNotification(notif, realIndex),
                      // ── Swipe background ─────────────────────────
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding:   const EdgeInsets.symmetric(horizontal: 20),
                        margin:    EdgeInsets.only(bottom: isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color:        Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.white, size: 22),
                            SizedBox(width: 6),
                            Text('Delete',
                                style: TextStyle(
                                    color:      Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
                        decoration: BoxDecoration(
                          color: notif.isRead
                              ? cardColor
                              : primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: notif.isRead
                                ? dividerColor
                                : primary.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.all(isMobile ? 8 : 12),
                          // ── Icon ─────────────────────────────────
                          leading: Container(
                            width:  isMobile ? 40 : 48,
                            height: isMobile ? 40 : 48,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _getNotificationIcon(
                                    notif.notificationType),
                                style: TextStyle(
                                    fontSize: isMobile ? 18 : 24),
                              ),
                            ),
                          ),
                          title: Text(
                            '${notif.triggeredBy?['name'] ?? 'Someone'} '
                            '${_getNotificationTitle(notif.notificationType).toLowerCase()}',
                            style: TextStyle(
                              fontWeight: notif.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _formatTime(notif.createdAt),
                            style: TextStyle(
                                color: hintColor, fontSize: 12),
                          ),
                          // ── Trailing: favorite + unread dot ──────
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Favorite button
                              GestureDetector(
                                onTap: () => _toggleFavorite(notif.id),
                                child: Icon(
                                  isFav
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: isFav
                                      ? Colors.amber
                                      : hintColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              GestureDetector(
                                onTap: () => _deleteNotification(
                                    notif, realIndex),
                                child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20),
                              ),
                              // Unread dot
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _markAsRead(notif.id),
                                  child: Container(
                                    width:  8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () => _markAsRead(notif.id),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}