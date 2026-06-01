import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/application_service.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  final ApplicationService _appService = ApplicationService();
  List<dynamic> _applications = [];
  bool   _isLoading = true;
  String? _error;

  static const _primary = Color(0xFF6C63FF);
  static const _accent  = Color(0xFF5A52D5);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _appService.getMyApplications();
      setState(() { _applications = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _accent,
        elevation: 0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Applications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 72,
                color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text("No applications yet",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 8),
            Text("Jobs you apply to will appear here",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: _primary,
      child: ListView.separated(
        padding:          const EdgeInsets.all(16),
        itemCount:        _applications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _ApplicationCard(app: _applications[i] as Map<String, dynamic>),
      ),
    );
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────
class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;
  static const _primary = Color(0xFF6C63FF);

  const _ApplicationCard({required this.app});

  Color _statusColor(String s) => switch (s) {
        'accepted'    => Colors.green,
        'rejected'    => Colors.red,
        'shortlisted' => const Color(0xFF5C6BC0),
        _             => Colors.grey,
      };

  IconData _statusIcon(String s) => switch (s) {
        'accepted'    => Icons.check_circle,
        'rejected'    => Icons.cancel,
        'shortlisted' => Icons.bookmark,
        _             => Icons.hourglass_empty,
      };

  Color _verdictColor(String? v) => switch (v) {
        'good_fit'    => Colors.green,
        'average_fit' => Colors.orange,
        'weak_fit'    => Colors.red,
        _             => Colors.grey,
      };

  String _verdictLabel(String? v) => switch (v) {
        'good_fit'    => '✓ Good Fit',
        'average_fit' => '~ Average Fit',
        'weak_fit'    => '✗ Weak Fit',
        _             => '',
      };

  @override
  Widget build(BuildContext context) {
    final job     = app['job']         as Map<String, dynamic>? ?? {};
    final company = job['company']     as Map<String, dynamic>? ?? {};
    final status  = app['status']      as String? ?? 'pending';
    final score   = app['match_score'] as num?;
    final verdict = app['verdict']     as String?;
    final color   = _statusColor(status);
    final applied = app['applied_at']  as String?;

    return Card(
      elevation: 3,
      color:     Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header: job title + status badge ──────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:        _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline,
                      color: _primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job['title'] ?? 'Job',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold)),
                      if (company['name'] != null)
                        Text(company['name'],
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .textTheme.bodySmall?.color)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(
                        status[0].toUpperCase() + status.substring(1),
                        style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      color),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Location + job type ───────────────────────────────
            if (job['location'] != null || job['job_type'] != null)
              Row(children: [
                if (job['location'] != null) ...[
                  Icon(Icons.location_on_outlined, size: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text(job['location'],
                      style: TextStyle(fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
                if (job['job_type'] != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.work_outline, size: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text(job['job_type'],
                      style: TextStyle(fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ]),

            const Divider(height: 20),

            // ── Match score + applied date ────────────────────────
            Row(
              children: [
                if (score != null) ...[
                  const Icon(Icons.analytics_outlined,
                      size: 14, color: _primary),
                  const SizedBox(width: 5),
                  Text('Match: ${score.toInt()}%',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _primary)),
                  if (verdict != null) ...[
                    const SizedBox(width: 10),
                    Text(_verdictLabel(verdict),
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w500,
                            color:      _verdictColor(verdict))),
                  ],
                ],
                const Spacer(),
                if (applied != null)
                  Text(
                    'Applied ${DateFormat.MMMd().format(DateTime.parse(applied))}',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
              ],
            ),

            // ── Status message banner ────────────────────────────
            if (status != 'pending') ...[
              const SizedBox(height: 12),
              _StatusBanner(status: status),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status banner shown to the user ──────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon, message) = switch (status) {
      'accepted' => (
          Colors.green,
          Icons.celebration,
          'Congratulations! The company accepted your application.',
        ),
      'rejected' => (
          Colors.red,
          Icons.info_outline,
          'This application was not selected. Keep applying!',
        ),
      'shortlisted' => (
          const Color(0xFF5C6BC0),
          Icons.bookmark,
          "You've been shortlisted! The company may reach out soon.",
        ),
      _ => (Colors.grey, Icons.hourglass_empty, 'Under review.'),
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
              style: TextStyle(color: color, fontSize: 12)),
        ),
      ]),
    );
  }
}