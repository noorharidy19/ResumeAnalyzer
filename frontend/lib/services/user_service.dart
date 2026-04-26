import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserService {
  static const String baseUrl = 'http://localhost:8001/api';

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
}
