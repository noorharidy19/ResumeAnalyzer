import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Post {
  final String id;
  final String creatorId;
  final String content;
  int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? creator;

  Post({
    required this.id,
    required this.creatorId,
    required this.content,
    required this.likesCount,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      creatorId: json['creator_id'],
      content: json['content'],
      likesCount: json['likes_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      creator: json['creator'],
    );
  }
}

class PostService {
  static const String baseUrl = 'http://localhost:8001/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Create a post
  static Future<Map<String, dynamic>> createPost(String content) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/posts/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to create post'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get feed
  static Future<Map<String, dynamic>> getFeed({int limit = 20, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/posts/feed?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'posts': (data['posts'] as List).map((p) => Post.fromJson(p)).toList(),
          'total_count': data['total_count'],
        };
      } else {
        return {'error': 'Failed to fetch feed'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get user's posts
  static Future<Map<String, dynamic>> getMyPosts({int limit = 20, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/posts/my-posts?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'posts': (data['posts'] as List).map((p) => Post.fromJson(p)).toList(),
          'total_count': data['total_count'],
        };
      } else {
        return {'error': 'Failed to fetch user posts'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Like a post
  static Future<Map<String, dynamic>> likePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to like post'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Delete post
  static Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to delete post'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
