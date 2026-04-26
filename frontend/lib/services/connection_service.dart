import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ConnectionService {
  static const String baseUrl = 'http://localhost:8001/api'; // Updated to port 8001
  
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Send connection request
  static Future<Map<String, dynamic>> sendConnectionRequest(String receiverId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$baseUrl/connections/request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'receiver_id': receiverId}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['detail'] ?? 'Failed to send request'};
      } else if (response.statusCode == 500) {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['detail'] ?? 'Server error'};
      } else {
        return {'error': 'Failed to send request (${response.statusCode})'};
      }
    } catch (e) {
      print('Error: $e');
      return {'error': e.toString()};
    }
  }

  // Accept connection request
  static Future<Map<String, dynamic>> acceptConnection(String connectionId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/connections/$connectionId/accept'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to accept connection'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Reject connection request
  static Future<Map<String, dynamic>> rejectConnection(String connectionId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.put(
        Uri.parse('$baseUrl/connections/$connectionId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        return {'error': errorBody['detail'] ?? 'Failed to reject connection'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get pending requests
  static Future<Map<String, dynamic>> getPendingRequests() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/connections/pending-requests'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to fetch pending requests'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get my connections
  static Future<List<dynamic>> getMyConnections() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/connections/my-connections'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get connection status
  static Future<Map<String, dynamic>> getConnectionStatus(String otherUserId) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/connections/status/$otherUserId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'none'};
      }
    } catch (e) {
      return {'status': 'none'};
    }
  }
}
