import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Notification {
  final String id;
  final String userId;
  final String notificationType;
  final String relatedId;
  final String? triggeredById;
  bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? triggeredBy;

  Notification({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.relatedId,
    this.triggeredById,
    required this.isRead,
    required this.createdAt,
    this.triggeredBy,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      notificationType: json['notification_type'],
      relatedId: json['related_id'],
      triggeredById: json['triggered_by_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      triggeredBy: json['triggered_by'],
    );
  }
}

class NotificationService {
  static const String baseUrl = 'http://localhost:8001/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get notifications
  static Future<Map<String, dynamic>> getNotifications({int limit = 20, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'notifications': (data['notifications'] as List).map((n) => Notification.fromJson(n)).toList(),
          'unread_count': data['unread_count'],
        };
      } else {
        return {'error': 'Failed to fetch notifications'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get unread count
  static Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch unread count'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Mark as read
  static Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to mark as read'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Mark all as read
  static Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to mark all as read'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Delete notification
  static Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to delete notification'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
