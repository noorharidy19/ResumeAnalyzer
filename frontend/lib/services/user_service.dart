import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserService {
<<<<<<< HEAD
  static const String baseUrl = 'http://192.168.1.5:8001/api';
=======
  static const String baseUrl = 'http://localhost:8001/api';
>>>>>>> 682891f9250cfcc965551e506d5d38534697d4e1

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Upload profile picture
  static Future<Map<String, dynamic>> uploadProfilePicture(List<int> fileBytes, String fileName) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/profile-picture/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        return {'error': 'Failed to upload profile picture'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Delete profile picture
  static Future<Map<String, dynamic>> deleteProfilePicture() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/users/profile-picture'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        try {
          final body = jsonDecode(response.body);
          return {'error': body['detail'] ?? body};
        } catch (_) {
          return {'error': 'Failed to delete profile picture: ${response.statusCode} - ${response.body}'};
        }
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch user profile'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Try to include server-provided detail if available
        try {
          final body = jsonDecode(response.body);
          return {'error': body['detail'] ?? body};
        } catch (_) {
          return {'error': 'Failed to update profile: ${response.statusCode} - ${response.body}'};
        }
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
