import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationService {
  static const String _baseUrl = 'http://192.168.1.28:8001';

  // ── Auth token ────────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── POST /api/applications/apply/{jobId}  — user applies ─────────────────
  Future<Map<String, dynamic>> applyToJob(int jobId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/applications/apply/$jobId');
    final response = await http.post(uri, headers: _authHeaders(token));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Surface backend error messages cleanly
    final error = jsonDecode(response.body);
    throw Exception(error['detail'] ?? 'Failed to submit application');
  }

  // ── GET /api/applications/mine  — user's own applications ────────────────
  Future<List<dynamic>> getMyApplications() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/applications/mine');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load applications: ${response.body}');
  }

  // ── GET /api/applications/job/{jobId}  — company views applicants ─────────
  Future<List<dynamic>> getApplicantsForJob(int jobId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/applications/job/$jobId');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception('Failed to load applicants: ${response.body}');
  }

  // ── GET /api/applications/{id}  — full detail (company) ──────────────────
  Future<Map<String, dynamic>> getApplicationDetail(int applicationId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/applications/$applicationId');
    final response = await http.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load application detail: ${response.body}');
  }

  // ── PATCH /api/applications/{id}/status  — accept / reject / shortlist ────
  Future<Map<String, dynamic>> updateApplicationStatus(
    int applicationId,
    String status, // 'accepted' | 'rejected' | 'shortlisted' | 'pending'
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$_baseUrl/api/applications/$applicationId/status');
    final response = await http.patch(
      uri,
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update status: ${response.body}');
  }
}