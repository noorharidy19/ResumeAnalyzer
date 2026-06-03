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
  // getter — always reads from live theme
  Color get primary => Theme.of(context).primaryColor;

  bool isLoading = true;
  String? error;
  String? userEmail;
  bool isLoggedIn = false;

  List<Map<String, dynamic>> history      = [];
  List<Map<String, dynamic>> fullAnalyses = [];

  int totalResumes       = 0;
  int totalJobsMatched   = 0;
  int totalSkillsMentions = 0;

  double avgMatchScore      = 0;
  double avgExperienceYears = 0;

  Map<String, int>           topSkills    = {};
  List<Map<String, dynamic>> recentScores = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndAnalytics();
  }

  Future<void> _loadUserAndAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail  = prefs.getString('user_email');
      isLoggedIn = userEmail != null;
    });
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() { isLoading = true; error = null; });

    try {
      final analyses = await ResumeAnalyzerService.listAnalyses();
      List<Map<String, dynamic>> details = [];

      if (analyses.isNotEmpty) {
        final ids = analyses
            .map((e) => e['analysis_id']?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        final results = await Future.wait(
        ids.map((id) => ResumeAnalyzerService.getAnalysis(id)
            .catchError((_) => <String, dynamic>{})),  
      );
      details = results.where((r) => r.isNotEmpty).toList(); 
    }

      List<Map<String, dynamic>> filteredAnalyses = [];

      if (isLoggedIn && userEmail != null && userEmail!.trim().isNotEmpty) {
        final normalized = userEmail!.trim().toLowerCase();
        filteredAnalyses = details.where((detail) {
          final phase1 = detail['phase1'] as Map<String, dynamic>? ?? {};
          final email  = (phase1['email']?.toString() ?? '').trim().toLowerCase();
          return email == normalized;
        }).toList();
      }

      final analysesToUse =
          filteredAnalyses.isNotEmpty ? filteredAnalyses : details;

      final skillCounter = <String, int>{};
      int    jobsMatched     = 0;
      int    skillsMentions  = 0;
      double scoreSum        = 0;
      int    scoreCount      = 0;
      double expSum          = 0;
      int    expCount        = 0;
      final  scoreRows       = <Map<String, dynamic>>[];

      for (final item in analysesToUse) {
        final phase1  = item['phase1'] as Map<String, dynamic>? ?? {};
        final phase2  = item['phase2'] as Map<String, dynamic>? ?? {};
        final skills  = phase1['skills']  as List<dynamic>? ?? [];
        final matches = phase2['matches'] as List<dynamic>? ?? [];
        final expYears = phase1['experience_years'];

        skillsMentions += skills.length;
        jobsMatched    += matches.length;

        if (expYears is num) { expSum += expYears.toDouble(); expCount++; }

        for (final s in skills) {
          final key = s.toString().trim().toLowerCase();
          if (key.isEmpty) continue;
          skillCounter[key] = (skillCounter[key] ?? 0) + 1;
        }

        if (matches.isNotEmpty) {
          double localTotal = 0;
          int    localCount = 0;
          for (final m in matches) {
            final score = (m as Map<String, dynamic>)['match_score'];
            if (score is num) {
              localTotal += score.toDouble();
              localCount++;
              scoreSum   += score.toDouble();
              scoreCount++;
            }
          }
          if (localCount > 0) {
            scoreRows.add({
              'analysis_id': item['analysis_id']?.toString() ?? '',
              'filename':    item['filename']?.toString() ?? 'Unknown CV',
              'score':       localTotal / localCount,
            });
          }
        }
      }

      final top = skillCounter.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (!mounted) return;

      setState(() {
        history      = filteredAnalyses.isNotEmpty ? filteredAnalyses : analyses;
        fullAnalyses = analysesToUse;

        totalResumes        = analysesToUse.length;
        totalJobsMatched    = jobsMatched;
        totalSkillsMentions = skillsMentions;

        avgMatchScore      = scoreCount == 0 ? 0 : scoreSum / scoreCount;
        avgExperienceYears = expCount   == 0 ? 0 : expSum   / expCount;

        topSkills    = { for (final e in top.take(8)) e.key: e.value };
        recentScores = scoreRows.take(6).toList();
        isLoading    = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { isLoading = false; error = e.toString(); });
    }
  }

  String _formatAnalysisTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final parts = raw.split('_');
    if (parts.length != 2) return raw;
    final date = parts[0];
    final time = parts[1];
    if (date.length != 8 || time.length != 6) return raw;
    return '${date.substring(6, 8)}/${date.substring(4, 6)}/${date.substring(0, 4)}'
        '  ${time.substring(0, 2)}:${time.substring(2, 4)}';
  }

  Future<void> _openAnalysis(String analysisId) async {
    try {
      final data = await ResumeAnalyzerService.getAnalysis(analysisId);
      if (!mounted) return;
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResumeAnalysisScreen(analysisData: data)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open analysis: $e'),
              backgroundColor: Colors.red));
    }
  }

  // ── Clear all analytics data ──────────────────────────────────────────────
  Future<void> _clearAll() async {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Delete All Analyses?'),
      content: const Text(
          'This will permanently delete all your analyses from the server. This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            Navigator.pop(context);
            setState(() => isLoading = true);
            try {
              // Delete every analysis from the server
              final ids = fullAnalyses
                  .map((e) => e['analysis_id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toList();
              await Future.wait(
                  ids.map((id) => ResumeAnalyzerService.deleteAnalysis(id)));
              // Now clear local state
              setState(() {
                history = [];
                fullAnalyses = [];
                totalResumes = 0;
                totalJobsMatched = 0;
                totalSkillsMentions = 0;
                avgMatchScore = 0;
                avgExperienceYears = 0;
                topSkills = {};
                recentScores = [];
                isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('All analyses deleted.'),
                backgroundColor: Colors.green,
              ));
            } catch (e) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Failed to delete: $e'),
                backgroundColor: Colors.red,
              ));
            }
          },
          child: const Text('Delete All', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  // ── Metric card ────────────────────────────────────────────────────────────
  Widget _metricCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        margin:  const EdgeInsets.all(6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset:     const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 28),
            const SizedBox(height: 10),
            Text(value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile  = ResponsiveHelper.isMobile(context);
    final padding   = ResponsiveHelper.getResponsivePadding(context);
    final cardColor = Theme.of(context).cardColor;
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon:    const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadAnalytics,
          ),
          IconButton(
            icon:    const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear All',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: padding,
                    child: Text(error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                )
              : SingleChildScrollView(
                  padding: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Title ────────────────────────────────────────
                      Text(
                        'Resume Analytics',
                        style: TextStyle(
                          fontSize:   isMobile ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color:      primary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Metric cards ─────────────────────────────────
                      if (isMobile)
                        Column(children: [
                          Row(children: [
                            _metricCard(totalResumes.toString(),     'Resumes', Icons.description),
                            _metricCard(totalJobsMatched.toString(), 'Jobs',    Icons.work),
                          ]),
                          Row(children: [
                            _metricCard('${avgMatchScore.toStringAsFixed(1)}%', 'Avg Match', Icons.star),
                            _metricCard(totalSkillsMentions.toString(),          'Skills',    Icons.psychology),
                          ]),
                        ])
                      else
                        Row(children: [
                          _metricCard(totalResumes.toString(),                   'Resumes',   Icons.description),
                          _metricCard(totalJobsMatched.toString(),               'Jobs',      Icons.work),
                          _metricCard('${avgMatchScore.toStringAsFixed(1)}%',   'Avg Match', Icons.star),
                          _metricCard(totalSkillsMentions.toString(),            'Skills',    Icons.psychology),
                        ]),

                      const SizedBox(height: 24),

                      // ── Top Skills ───────────────────────────────────
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset:     const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Top Skills',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            if (topSkills.isEmpty)
                              Text('No skills found',
                                  style: TextStyle(color: hintColor))
                            else
                              ...topSkills.entries.map((e) {
                                final maxCount = topSkills.values
                                    .reduce((a, b) => a > b ? a : b);
                                final progress = e.value / maxCount;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(e.key),
                                          Text('${e.value}'),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      LinearProgressIndicator(
                                        value:           progress,
                                        backgroundColor: primary.withValues(alpha: 0.15),
                                        valueColor:
                                            AlwaysStoppedAnimation(primary),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Recent Match Scores ──────────────────────────
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset:     const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Match Scores',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            if (recentScores.isEmpty)
                              Text('No match scores yet.',
                                  style: TextStyle(color: hintColor))
                            else
                              ...recentScores.map((row) {
                                final filename =
                                    row['filename']?.toString() ?? 'Unknown';
                                final score =
                                    (row['score'] as num?)?.toDouble() ?? 0;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        primary.withValues(alpha: 0.15),
                                    child: Icon(Icons.assessment, color: primary),
                                  ),
                                  title: Text(filename,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                      'Score: ${score.toStringAsFixed(1)}%',
                                      style: TextStyle(color: hintColor)),
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── History ──────────────────────────────────────
                      Container(
                        width:   double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:      Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset:     const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Saved Analysis History',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            if (history.isEmpty)
                              Text('No saved analyses found.',
                                  style: TextStyle(color: hintColor))
                            else
                              ...history.take(10).map((item) {
                                final id       = item['analysis_id']?.toString() ?? '';
                                final filename = item['filename']?.toString() ?? 'Unknown CV';
                                final ts       = _formatAnalysisTimestamp(
                                    item['timestamp']?.toString());
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        primary.withValues(alpha: 0.15),
                                    child: Icon(Icons.description, color: primary),
                                  ),
                                  title: Text(filename,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  subtitle: Text(ts,
                                      style: TextStyle(color: hintColor)),
                                  trailing: TextButton(
                                    onPressed: () => _openAnalysis(id),
                                    child: Text('Open',
                                        style: TextStyle(color: primary)),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}