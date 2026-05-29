import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CVEnhancementService {
  static const String _baseUrl = 'http://192.168.1.5:8001';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
      
  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Trigger enhancement ─────────────────────────────

  Future<void> enhanceResume(
    String analysisId, {
    String? targetJob,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse('$_baseUrl/api/cv/enhance'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'analysis_id': analysisId,
        if (targetJob != null) 'target_job': targetJob,
      }),
    );

    if (response.statusCode != 202 &&
        response.statusCode != 200) {
      throw Exception(
        'Failed to trigger enhancement: ${response.body}',
      );
    }
  }

  // ── Fetch enhancement ─────────────────────────────

  Future<Map<String, dynamic>?> getEnhancement(
    String analysisId,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/cv/$analysisId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 404) return null;

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch enhancement: ${response.body}',
      );
    }

    return jsonDecode(response.body)
        as Map<String, dynamic>;
  }

  // ── Poll enhancement ─────────────────────────────

  Future<Map<String, dynamic>> pollEnhancement(
    String analysisId, {
    int intervalSeconds = 4,
    int maxAttempts = 30,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final result = await getEnhancement(analysisId);

      if (result != null) return result;

      await Future.delayed(
        Duration(seconds: intervalSeconds),
      );
    }

    throw Exception(
      'Enhancement timed out. Please try again later.',
    );
  }

  // ── Download PDF ─────────────────────────────

  Future<File> downloadPDF(String analysisId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/cv/$analysisId/export/pdf',
      ),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'PDF export failed: ${response.body}',
      );
    }

    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      '${dir.path}/enhanced_cv_$analysisId.pdf',
    );

    await file.writeAsBytes(response.bodyBytes);

    return file;
  }
}