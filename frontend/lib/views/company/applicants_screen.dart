import 'package:flutter/material.dart';
import '../../services/application_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Applicants list screen (company views all applicants for a job)
// ─────────────────────────────────────────────────────────────────────────────
class ApplicantsScreen extends StatefulWidget {
  final int jobId;
  final String jobTitle;
  const ApplicantsScreen({super.key, required this.jobId, required this.jobTitle});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final ApplicationService _appService = ApplicationService();
  List<dynamic> _applicants = [];
  bool _isLoading = true;
  String? _error;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);
  static const bg      = Color(0xFFF0F7FF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _appService.getApplicantsForJob(widget.jobId);
      setState(() { _applicants = data; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(widget.jobTitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _applicants.isEmpty
                  ? _EmptyView()
                  : _ApplicantsList(
                      applicants: _applicants,
                      onStatusChange: (id, status) async {
                        await _appService.updateApplicationStatus(id, status);
                        _load();
                      },
                      onViewDetail: (id) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ApplicantDetailScreen(applicationId: id)),
                      ),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F51B5)),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No applications yet',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Applications will appear here once candidates apply',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _ApplicantsList extends StatelessWidget {
  final List<dynamic> applicants;
  final Function(int, String) onStatusChange;
  final Function(int) onViewDetail;
  const _ApplicantsList({
    required this.applicants,
    required this.onStatusChange,
    required this.onViewDetail,
  });
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF5C6BC0),
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: applicants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final app = applicants[i] as Map<String, dynamic>;
          return _ApplicantCard(
            application: app,
            onStatusChange: (status) => onStatusChange(app['id'] as int, status),
            onViewDetail: () => onViewDetail(app['id'] as int),
          );
        },
      ),
    );
  }
}

// ── Applicant card ─────────────────────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final Function(String) onStatusChange;
  final VoidCallback onViewDetail;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);

  const _ApplicantCard({
    required this.application,
    required this.onStatusChange,
    required this.onViewDetail,
  });

  Color _verdictColor(String? v) {
    if (v == 'good_fit') return Colors.green;
    if (v == 'average_fit') return Colors.orange;
    if (v == 'weak_fit') return Colors.red;
    return Colors.grey;
  }

  String _verdictLabel(String? v) {
    if (v == 'good_fit') return 'Good Fit ✓';
    if (v == 'average_fit') return 'Average Fit';
    if (v == 'weak_fit') return 'Weak Fit';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final applicant = application['applicant'] as Map<String, dynamic>? ?? {};
    final score     = application['match_score'] as num?;
    final verdict   = application['verdict'] as String?;
    final status    = application['status'] as String? ?? 'pending';
    final initials  = ((applicant['name'] as String?)?.isNotEmpty == true)
        ? (applicant['name'] as String).substring(0, 1).toUpperCase()
        : '?';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primary.withOpacity(0.12),
                  child: Text(initials,
                      style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(applicant['name'] ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(applicant['email'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                // Score circle
                if (score != null) _ScoreBadge(score: score.toInt()),
              ],
            ),

            const SizedBox(height: 12),

            // Verdict + status pills
            Wrap(
              spacing: 8,
              children: [
                if (verdict != null)
                  _Pill(label: _verdictLabel(verdict), color: _verdictColor(verdict)),
                _Pill(label: status.capitalize(), color: _statusColor(status)),
              ],
            ),

            const SizedBox(height: 12),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.visibility_outlined, size: 16, color: primary),
                    label: const Text('Details', style: TextStyle(color: primary, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionMenu(currentStatus: status, onStatusChange: onStatusChange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    if (s == 'accepted') return Colors.green;
    if (s == 'shortlisted') return const Color(0xFF5C6BC0);
    if (s == 'rejected') return Colors.red;
    return Colors.grey;
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});
  Color get _color {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _color, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$score',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _color)),
            Text('score', style: TextStyle(fontSize: 9, color: _color)),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}

class _ActionMenu extends StatelessWidget {
  final String currentStatus;
  final Function(String) onStatusChange;
  static const primary = Color(0xFF5C6BC0);
  const _ActionMenu({required this.currentStatus, required this.onStatusChange});
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        onSelected: onStatusChange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          if (currentStatus != 'shortlisted')
            const PopupMenuItem(value: 'shortlisted',
                child: Row(children: [
                  Icon(Icons.bookmark_outline, color: Color(0xFF5C6BC0)),
                  SizedBox(width: 8), Text('Shortlist')
                ])),
          if (currentStatus != 'accepted')
            const PopupMenuItem(value: 'accepted',
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 8), Text('Accept')
                ])),
          if (currentStatus != 'rejected')
            const PopupMenuItem(value: 'rejected',
                child: Row(children: [
                  Icon(Icons.cancel_outlined, color: Colors.red),
                  SizedBox(width: 8), Text('Reject')
                ])),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: primary.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Action', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: primary),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Applicant detail screen (full AI screening report)
// ─────────────────────────────────────────────────────────────────────────────
class ApplicantDetailScreen extends StatefulWidget {
  final int applicationId;
  const ApplicantDetailScreen({super.key, required this.applicationId});
  @override
  State<ApplicantDetailScreen> createState() => _ApplicantDetailScreenState();
}

class _ApplicantDetailScreenState extends State<ApplicantDetailScreen> {
  final ApplicationService _appService = ApplicationService();
  Map<String, dynamic>? _app;
  bool _isLoading = true;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);
  static const bg      = Color(0xFFF0F7FF);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await _appService.getApplicationDetail(widget.applicationId);
      setState(() { _app = data; _isLoading = false; });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    await _appService.updateApplicationStatus(widget.applicationId, status);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Applicant Detail',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _app == null
              ? const Center(child: Text('Failed to load.'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final applicant  = _app!['applicant'] as Map<String, dynamic>? ?? {};
    final screening  = _app!['ai_screening'] as Map<String, dynamic>?;
    final score      = _app!['match_score'] as num?;
    final verdict    = _app!['verdict'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──────────────────────────────────────────
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primary.withOpacity(0.12),
                    child: Text(
                      ((applicant['name'] as String?)?.isNotEmpty == true)
                          ? (applicant['name'] as String).substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(applicant['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(applicant['email'] ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  if (score != null) _LargeScore(score: score.toInt(), verdict: verdict),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── AI Summary ───────────────────────────────────────────
          if (screening?['summary'] != null)
            _InfoCard(
              icon: Icons.auto_awesome_outlined,
              title: 'AI Summary',
              color: accent,
              child: Text(screening!['summary'], style: const TextStyle(height: 1.6)),
            ),

          const SizedBox(height: 10),

          // ── Matched experience ───────────────────────────────────
          if (screening?['matched_experience'] != null)
            _InfoCard(
              icon: Icons.work_history_outlined,
              title: 'Matched Experience',
              color: Colors.teal,
              child: Text(screening!['matched_experience'],
                  style: const TextStyle(height: 1.6)),
            ),

          const SizedBox(height: 10),

          // ── Skills grid ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (screening?['matched_skills'] != null)
                Expanded(
                  child: _InfoCard(
                    icon: Icons.check_circle_outline,
                    title: 'Matched Skills',
                    color: Colors.green,
                    child: _TagWrap(
                      tags: (screening!['matched_skills'] as List).cast<String>(),
                      color: Colors.green,
                    ),
                  ),
                ),
              if (screening?['matched_skills'] != null &&
                  screening?['missing_skills'] != null)
                const SizedBox(width: 10),
              if (screening?['missing_skills'] != null)
                Expanded(
                  child: _InfoCard(
                    icon: Icons.cancel_outlined,
                    title: 'Missing Skills',
                    color: Colors.red,
                    child: _TagWrap(
                      tags: (screening!['missing_skills'] as List).cast<String>(),
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Weak points ──────────────────────────────────────────
          if (screening?['weak_points'] != null)
            _InfoCard(
              icon: Icons.warning_amber_outlined,
              title: 'Weak Points',
              color: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (screening!['weak_points'] as List)
                    .cast<String>()
                    .map((w) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right, size: 18, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(child: Text(w, style: const TextStyle(fontSize: 13))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),

          const SizedBox(height: 20),

          // ── Action buttons ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('accepted'),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('Accept', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus('shortlisted'),
                  icon: const Icon(Icons.bookmark_outline, size: 18, color: primary),
                  label: const Text('Shortlist', style: TextStyle(color: primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus('rejected'),
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  label: const Text('Reject', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _LargeScore extends StatelessWidget {
  final int score;
  final String? verdict;
  const _LargeScore({required this.score, this.verdict});
  Color get _color {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _color, width: 3),
            ),
            child: Center(
              child: Text('$score',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: _color)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            verdict == 'good_fit' ? 'Good Fit' : verdict == 'average_fit' ? 'Average' : 'Weak',
            style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600),
          ),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;
  const _InfoCard({required this.icon, required this.title, required this.color, required this.child});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: color)),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      );
}

class _TagWrap extends StatelessWidget {
  final List<String> tags;
  final Color color;
  const _TagWrap({required this.tags, required this.color});
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 5,
        runSpacing: 4,
        children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(t, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        )).toList(),
      );
}

extension StringExt on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}