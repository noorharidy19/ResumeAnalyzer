import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/resume_analyzer_service.dart';
import '../resume/resume_analysis_screen.dart';
import '../../utils/responsive_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final Color primary = const Color(0xFF7C8CF8);
  final Color bg = const Color(0xFFF5F7FF);

  bool isLoading = true;
  String? error;
  String? userEmail;
  bool isLoggedIn = false;

  List<Map<String, dynamic>> history = [];
  List<Map<String, dynamic>> fullAnalyses = [];

  int totalResumes = 0;
  int totalJobsMatched = 0;
  int totalSkillsMentions = 0;
  double avgMatchScore = 0;
  double avgExperienceYears = 0;

  Map<String, int> topSkills = {};
  List<Map<String, dynamic>> recentScores = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndAnalytics();
  }

  Future<void> _loadUserAndAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString("user_email");
      isLoggedIn = userEmail != null;
    });
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final analyses = await ResumeAnalyzerService.listAnalyses();

      // Fetch full details for all analyses
      List<Map<String, dynamic>> details = [];
      if (analyses.isNotEmpty) {
        final ids = analyses
            .map((e) => e['analysis_id']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();

        final fetched = await Future.wait(
          ids.map((id) => ResumeAnalyzerService.getAnalysis(id)),
        );
        details = fetched;
      }

      // Filter by current user's email
      List<Map<String, dynamic>> filteredAnalyses = [];
      if (isLoggedIn && userEmail != null && userEmail!.trim().isNotEmpty) {
        final normalized = userEmail!.trim().toLowerCase();
        filteredAnalyses = details.where((detail) {
          final phase1 = detail['phase1'] as Map<String, dynamic>? ?? {};
          final email = (phase1['email']?.toString() ?? '').trim().toLowerCase();
          return email == normalized;
        }).toList();
      }

      // Use filtered analyses for calculations
      final analysesToUse = filteredAnalyses.isNotEmpty ? filteredAnalyses : details;

      final skillCounter = <String, int>{};
      int jobsMatched = 0;
      int skillsMentions = 0;
      double scoreSum = 0;
      int scoreCount = 0;
      double expSum = 0;
      int expCount = 0;
      final scoreRows = <Map<String, dynamic>>[];

      for (int i = 0; i < analysesToUse.length; i++) {
        final item = analysesToUse[i];
        final phase1 = item['phase1'] as Map<String, dynamic>? ?? {};
        final phase2 = item['phase2'] as Map<String, dynamic>? ?? {};

        final skills = phase1['skills'] as List<dynamic>? ?? [];
        final matches = phase2['matches'] as List<dynamic>? ?? [];
        final expYears = phase1['experience_years'];

        skillsMentions += skills.length;
        jobsMatched += matches.length;

        if (expYears is num) {
          expSum += expYears.toDouble();
          expCount++;
        }

        for (final s in skills) {
          final key = s.toString().trim().toLowerCase();
          if (key.isEmpty) continue;
          skillCounter[key] = (skillCounter[key] ?? 0) + 1;
        }

        if (matches.isNotEmpty) {
          double localTotal = 0;
          int localCount = 0;
          for (final m in matches) {
            final score = (m as Map<String, dynamic>)['match_score'];
            if (score is num) {
              localTotal += score.toDouble();
              localCount++;
              scoreSum += score.toDouble();
              scoreCount++;
            }
          }

          if (localCount > 0) {
            scoreRows.add({
              'analysis_id': item['analysis_id']?.toString() ?? '',
              'filename': item['filename']?.toString() ?? 'Unknown CV',
              'score': localTotal / localCount,
            });
          }
        }
      }

      final top = skillCounter.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (!mounted) return;
      setState(() {
        history = filteredAnalyses.isNotEmpty ? filteredAnalyses : analyses;
        fullAnalyses = analysesToUse;
        totalResumes = analysesToUse.length;
        totalJobsMatched = jobsMatched;
        totalSkillsMentions = skillsMentions;
        avgMatchScore = scoreCount == 0 ? 0 : (scoreSum / scoreCount);
        avgExperienceYears = expCount == 0 ? 0 : (expSum / expCount);
        topSkills = {for (final e in top.take(8)) e.key: e.value};
        recentScores = scoreRows.take(6).toList();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        error = e.toString();
      });
    }
  }

  String _formatAnalysisTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parts = raw.split('_');
    if (parts.length != 2) return raw;

    final date = parts[0];
    final time = parts[1];
    if (date.length != 8 || time.length != 6) return raw;

    final yyyy = date.substring(0, 4);
    final mm = date.substring(4, 6);
    final dd = date.substring(6, 8);
    final hh = time.substring(0, 2);
    final min = time.substring(2, 4);
    return '$dd/$mm/$yyyy  $hh:$min';
  }

  Future<void> _openAnalysis(String analysisId) async {
    try {
      final data = await ResumeAnalyzerService.getAnalysis(analysisId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResumeAnalysisScreen(analysisData: data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAnalysis(String analysisId, String fileName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete CV Analysis'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ResumeAnalyzerService.deleteAnalysis(analysisId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV analysis deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAnalytics();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete analysis: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _metricCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: primary),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final titleSize = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobileSize: 18,
      tabletSize: 20,
      desktopSize: 24,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Analytics'),
        centerTitle: isMobile,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: padding,
                    child: Text(
                      'Failed to load analytics:\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume Analytics From Saved CV History',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All metrics are calculated from uploaded and saved analyses.',
                        style: TextStyle(color: Colors.grey[700], fontSize: isMobile ? 13 : 14),
                      ),
                      const SizedBox(height: 20),
                      if (isMobile)
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard(totalResumes.toString(), 'Total Resumes', Icons.description),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _metricCard(totalJobsMatched.toString(), 'Jobs Matched', Icons.work),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard('${avgMatchScore.toStringAsFixed(1)}%', 'Avg Match', Icons.star),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _metricCard(totalSkillsMentions.toString(), 'Skills', Icons.psychology),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard('${avgExperienceYears.toStringAsFixed(1)}', 'Avg Exp Yrs', Icons.timeline),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                _metricCard(totalResumes.toString(), 'Total Resumes', Icons.description),
                                _metricCard(totalJobsMatched.toString(), 'Jobs Matched', Icons.work),
                                _metricCard('${avgMatchScore.toStringAsFixed(1)}%', 'Avg Match Score', Icons.star),
                                _metricCard(totalSkillsMentions.toString(), 'Skills Mentions', Icons.psychology),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _metricCard('${avgExperienceYears.toStringAsFixed(1)}', 'Avg Experience Years', Icons.timeline),
                                const Expanded(child: SizedBox()),
                                const Expanded(child: SizedBox()),
                                const Expanded(child: SizedBox()),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top Skills Across CVs',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  if (topSkills.isEmpty)
                                    Text('No skills data yet.', style: TextStyle(color: Colors.grey[600]))
                                  else
                                    ...topSkills.entries.map((e) {
                                      final maxCount = topSkills.values.isEmpty
                                          ? 1
                                          : topSkills.values.reduce((a, b) => a > b ? a : b);
                                      final progress = maxCount == 0 ? 0.0 : (e.value / maxCount);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(e.key),
                                                Text('${e.value}'),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: double.infinity,
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor: primary.withOpacity(0.15),
                                                valueColor: AlwaysStoppedAnimation(primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Top Skills Across CVs',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 12),
                                  if (topSkills.isEmpty)
                                    Text('No skills data yet.', style: TextStyle(color: Colors.grey[600]))
                                  else
                                    ...topSkills.entries.map((e) {
                                      final maxCount = topSkills.values.isEmpty
                                          ? 1
                                          : topSkills.values.reduce((a, b) => a > b ? a : b);
                                      final progress = maxCount == 0 ? 0.0 : (e.value / maxCount);
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(e.key),
                                                Text('${e.value}'),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: double.infinity,
                                              child: LinearProgressIndicator(
                                                value: progress,
                                                backgroundColor: primary.withOpacity(0.15),
                                                valueColor: AlwaysStoppedAnimation(primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Recent Match Scores',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    if (recentScores.isEmpty)
                                      Text('No match scores yet.', style: TextStyle(color: Colors.grey[600]))
                                    else
                                      Expanded(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: [
                                              ...recentScores.map((row) {
                                                final filename = row['filename']?.toString() ?? 'Unknown';
                                                final score = (row['score'] as num?)?.toDouble() ?? 0;
                                                return ListTile(
                                                  contentPadding: EdgeInsets.zero,
                                                  leading: CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: primary.withOpacity(0.15),
                                                    child: Icon(Icons.assessment, size: 14, color: primary),
                                                  ),
                                                  title: Text(
                                                    filename,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  ),
                                                  subtitle: Text('Score: ${score.toStringAsFixed(1)}%'),
                                                );
                                              }),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saved Analysis History',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (history.isEmpty)
                              Text('No saved analyses found.', style: TextStyle(color: Colors.grey[600]))
                            else
                              ...history.take(10).map((item) {
                                final id = item['analysis_id']?.toString() ?? '';
                                final filename = item['filename']?.toString() ?? 'Unknown CV';
                                final ts = _formatAnalysisTimestamp(item['timestamp']?.toString());

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: primary.withOpacity(0.15),
                                    child: Icon(Icons.description, size: 16, color: primary),
                                  ),
                                  title: Text(
                                    filename,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(ts),
                                  trailing: id.isEmpty
                                      ? null
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: () => _openAnalysis(id),
                                              child: const Text('Open'),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                              onPressed: () => _deleteAnalysis(id, filename),
                                              tooltip: 'Delete',
                                            ),
                                          ],
                                        ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  
  }
}