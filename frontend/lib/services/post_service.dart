import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Comment {
  final String id;
  final String postId;
  final String creatorId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? creator;

  Comment({
    required this.id,
    required this.postId,
    required this.creatorId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post_id'],
      creatorId: json['creator_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      creator: json['creator'],
    );
  }
}

class Post {
  final String id;
  final String creatorId;
  final String content;
  int likesCount;
  int commentsCount;
  int repostsCount;
  bool isLiked;
  bool isReposted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? creator;
  List<Comment>? comments;

  Post({
    required this.id,
    required this.creatorId,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
    this.isLiked = false,
    this.isReposted = false,
    required this.createdAt,
    required this.updatedAt,
    this.creator,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      content: json['content'] ?? '',
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      repostsCount: json['reposts_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isReposted: json['is_reposted'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      creator: json['creator'],
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((c) => Comment.fromJson(c))
              .toList()
          : null,
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
        try {
          final data = jsonDecode(response.body);
          print('📤 Feed API Response (truncated): ${response.body.length > 200 ? response.body.substring(0, 200) + '...' : response.body}');
          return {
            'posts': (data['posts'] as List).map((p) {
              // print('📝 Parsing post: $p'); // avoid extremely noisy logs
              return Post.fromJson(p);
            }).toList(),
            'total_count': data['total_count'],
          };
        } catch (e) {
          print('❌ Feed JSON decode error: $e');
          print('Response body: ${response.body}');
          return {'error': 'Failed to decode feed response: $e - ${response.body}'};
        }
      } else {
        print('❌ Feed API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'error': 'Failed to fetch feed: ${response.statusCode} - ${response.body}'};
      }
    } catch (e) {
      print('❌ Feed Exception: $e');
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
        try {
          final data = jsonDecode(response.body);
          return {
            'posts': (data['posts'] as List).map((p) => Post.fromJson(p)).toList(),
            'total_count': data['total_count'],
          };
        } catch (e) {
          print('❌ MyPosts JSON decode error: $e');
          print('Response body: ${response.body}');
          return {'error': 'Failed to decode user posts response: $e - ${response.body}'};
        }
      } else {
        print('❌ MyPosts API Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {'error': 'Failed to fetch user posts: ${response.statusCode} - ${response.body}'};
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

      print('❤️ Liking post: $postId');
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('❤️ Like response: ${response.statusCode}');
      print('❤️ Like body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Like failed: ${response.statusCode} - ${response.body}'};
      }
    } catch (e) {
      print('❌ Like error: $e');
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

  // Add comment
  static Future<Map<String, dynamic>> addComment(String postId, String content) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('💬 Adding comment to post: $postId');
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/comment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'content': content}),
      );

      print('💬 Comment response: ${response.statusCode}');
      print('💬 Comment body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Comment failed: ${response.statusCode} - ${response.body}'};
      }
    } catch (e) {
      print('❌ Comment error: $e');
      return {'error': e.toString()};
    }
  }

  // Get comments
  static Future<Map<String, dynamic>> getComments(String postId, {int limit = 20, int offset = 0}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/posts/$postId/comments?limit=$limit&offset=$offset'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'comments': (data['comments'] as List).map((c) => Comment.fromJson(c)).toList(),
          'total_count': data['total_count'],
        };
      } else {
        return {'error': 'Failed to fetch comments'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Delete comment
  static Future<Map<String, dynamic>> deleteComment(String postId, String commentId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId/comment/$commentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to delete comment'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Repost
  static Future<Map<String, dynamic>> repost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      print('🔁 Reposting post: $postId');
      final response = await http.post(
        Uri.parse('$baseUrl/posts/$postId/repost'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('🔁 Repost response: ${response.statusCode}');
      print('🔁 Repost body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Repost failed: ${response.statusCode} - ${response.body}'};
      }
    } catch (e) {
      print('❌ Repost error: $e');
      return {'error': e.toString()};
    }
  }
}
