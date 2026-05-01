import 'dart:convert';
import 'package:http/http.dart' as http;

class ResumeAnalyzerService {
  static const String baseUrl = 'http://localhost:8001/api/resume';

  /// Upload resume PDF and get full analysis (Phase 1, 2, 3)
  static Future<Map<String, dynamic>> analyzeResume(
    List<int> fileBytes,
    String fileName, {
    int topK = 3,
    bool useExternalJobs = true,
    String location = 'Egypt',
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/analyze'))
        ..fields['top_k'] = topK.toString()
        ..fields['use_external_jobs'] = useExternalJobs.toString()
        ..fields['location'] = location
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );

      var response = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Error: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Failed to analyze resume: $e');
    }
  }

  /// Get previously saved analysis
  static Future<Map<String, dynamic>> getAnalysis(String analysisId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history/$analysisId'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to get analysis: $e');
    }
  }

  /// List all saved analyses
  static Future<List<Map<String, dynamic>>> listAnalyses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['analyses'] ?? []);
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to list analyses: $e');
    }
  }

  /// Download analysis as JSON
  static Future<void> downloadAnalysis(String analysisId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/download/$analysisId'),
      );

      if (response.statusCode == 200) {
        // Handle download
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download analysis: $e');
    }
  }

  /// Delete analysis
  static Future<void> deleteAnalysis(String analysisId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/history/$analysisId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete analysis: $e');
    }
  }
}
