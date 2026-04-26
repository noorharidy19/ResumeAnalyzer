import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? receiver;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.sender,
    this.receiver,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      sender: json['sender'],
      receiver: json['receiver'],
    );
  }
}

class MessageService {
  static const String baseUrl = 'http://localhost:8001/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Send a message
  static Future<Map<String, dynamic>> sendMessage(
    String connectionId,
    String content,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/messages/send/$connectionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['detail'] ?? 'Failed to send message'};
      } else {
        return {'error': 'Failed to send message (${response.statusCode})'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get chat history
  static Future<Map<String, dynamic>> getChatHistory(
    String connectionId, {
    int limit = 50,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/chat/$connectionId?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'messages': (data['messages'] as List)
              .map((m) => Message.fromJson(m))
              .toList(),
          'other_user': data['other_user'],
          'unread_count': data['unread_count'],
        };
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['detail'] ?? 'Failed to fetch chat history'};
      } else {
        return {'error': 'Failed to fetch chat history (${response.statusCode})'};
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
        Uri.parse('$baseUrl/messages/unread-count'),
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

  // Get unread count for a specific connection (without marking as read)
  static Future<Map<String, dynamic>> getUnreadCountForConnection(String connectionId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/messages/unread-count/$connectionId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch unread count for connection'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Mark message as read
  static Future<Map<String, dynamic>> markAsRead(String messageId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.patch(
        Uri.parse('$baseUrl/messages/$messageId/read'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to mark message as read'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Delete message
  static Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to delete message'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
