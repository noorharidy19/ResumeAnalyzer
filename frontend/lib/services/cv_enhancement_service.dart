import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CVEnhancementService {
  static const String _baseUrl = 'http://localhost:8001';

  // ── Auth token helper ────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ── Trigger Phase 4 enhancement ─────────────────────────────────────────
  /// Posts to /api/cv/enhance. Backend returns 202 and runs in the background.
  /// Flutter should then call [pollEnhancement] until it resolves.
  Future<void> enhanceResume(int analysisId, {String? targetJob}) async {
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

    if (response.statusCode != 202 && response.statusCode != 200) {
      throw Exception('Failed to trigger enhancement: ${response.body}');
    }
  }

  // ── Fetch saved enhancement ───────────────────────────────────────────────
  /// Returns null while Phase 4 is still running (404 from backend).
  /// Flutter screens call this and show a loading state until non-null.
  Future<Map<String, dynamic>?> getEnhancement(int analysisId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/cv/$analysisId'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 404) return null;   // Still processing
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch enhancement: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── Poll until ready ──────────────────────────────────────────────────────
  /// Polls every [intervalSeconds] until enhancement is ready or [maxAttempts] is hit.
  Future<Map<String, dynamic>> pollEnhancement(
    int analysisId, {
    int intervalSeconds = 4,
    int maxAttempts = 30,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final result = await getEnhancement(analysisId);
      if (result != null) return result;
      await Future.delayed(Duration(seconds: intervalSeconds));
    }
    throw Exception('Enhancement timed out. Please try again later.');
  }

  // ── Download PDF ──────────────────────────────────────────────────────────
  /// Calls /api/cv/{analysisId}/export/pdf, saves the file to the device's
  /// Downloads directory, and returns the local [File] path.
  Future<File> downloadPDF(int analysisId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse('$_baseUrl/api/cv/$analysisId/export/pdf'),
      headers: _authHeaders(token),
    );

    if (response.statusCode != 200) {
      throw Exception('PDF export failed: ${response.body}');
    }

    // Save to app documents directory (cross-platform safe)
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/enhanced_cv_$analysisId.pdf');
    await file.writeAsBytes(response.bodyBytes);

    return file;
  }
}
