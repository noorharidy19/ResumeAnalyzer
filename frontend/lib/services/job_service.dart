import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JobService {
  static const String _baseUrl = 'http://localhost:8001';

  // ── Auth token ────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── GET /api/jobs/  — browse all open jobs ────────────────────────────────
  Future<List<dynamic>> getAllJobs({int skip = 0, int limit = 50}) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/jobs/?skip=$skip&limit=$limit');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load jobs: ${response.body}');
  }

  // ── GET /api/jobs/my-posts  — company's own posts ─────────────────────────
  Future<List<dynamic>> getMyJobPosts() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/jobs/my-posts');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load job posts: ${response.body}');
  }

  // ── GET /api/jobs/{id}  — single job detail ───────────────────────────────
  Future<Map<String, dynamic>> getJobById(int jobId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/jobs/$jobId');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load job: ${response.body}');
  }

  // ── POST /api/jobs/create  — company creates a job ────────────────────────
  Future<Map<String, dynamic>> createJob({
    required String title,
    required String description,
    required List<String> requirements,
    String? location,
    String? jobType,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/jobs/create');
    final response = await http.post(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({
        'title': title,
        'description': description,
        'requirements': requirements,
        if (location != null) 'location': location,
        if (jobType != null) 'job_type': jobType,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create job: ${response.body}');
  }

  // ── PATCH /api/jobs/{id}  — update a job post ─────────────────────────────
  Future<Map<String, dynamic>> updateJob(
    int jobId,
    Map<String, dynamic> updates,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/jobs/$jobId');
    final response = await http.patch(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update job: ${response.body}');
  }

  // ── DELETE /api/jobs/{id} ─────────────────────────────────────────────────
  Future<void> deleteJob(int jobId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/jobs/$jobId');
    final response = await http.delete(uri, headers: _authHeaders(token));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete job: ${response.body}');
    }
  }
}