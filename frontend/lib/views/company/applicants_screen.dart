import 'package:flutter/material.dart';
import '../../services/application_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Applicants list screen (company views all applicants for a job)
// ─────────────────────────────────────────────────────────────────────────────
class ApplicantsScreen extends StatefulWidget {
  final int    jobId;
  final String jobTitle;
  const ApplicantsScreen(
      {super.key, required this.jobId, required this.jobTitle});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final ApplicationService _appService = ApplicationService();
  List<dynamic> _applicants = [];
  bool   _isLoading = true;
  String? _error;

  // Company-side brand colors — kept intentionally separate from main app theme
  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _accent,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Applicants',
                style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   16)),
            Text(widget.jobTitle,
                style:    const TextStyle(color: Colors.white70, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          IconButton(
              icon:      const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primary))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : _applicants.isEmpty
                  ? const _EmptyView()
                  : _ApplicantsList(
                      applicants: _applicants,
                      onStatusChange: (id, status) async {
                        await _appService.updateApplicationStatus(
                            id, status);
                        _load();
                      },
                      onViewDetail: (id) => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ApplicantDetailScreen(applicationId: id)),
                      ),
                    ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String       error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(error,
                style:     const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F51B5)),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size:  72,
                color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 16),
            Text('No applications yet',
                style: TextStyle(
                    fontSize:   18,
                    color:      Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
                'Applications will appear here once candidates apply',
                style: TextStyle(
                    color:    Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

class _ApplicantsList extends StatelessWidget {
  final List<dynamic>          applicants;
  final Function(int, String)  onStatusChange;
  final Function(int)          onViewDetail;
  const _ApplicantsList({
    required this.applicants,
    required this.onStatusChange,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color:     const Color(0xFF5C6BC0),
      onRefresh: () async {},
      child: ListView.separated(
        padding:          const EdgeInsets.all(16),
        itemCount:        applicants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final app = applicants[i] as Map<String, dynamic>;
          return _ApplicantCard(
            application:    app,
            onStatusChange: (status) =>
                onStatusChange(app['id'] as int, status),
            onViewDetail:   () => onViewDetail(app['id'] as int),
          );
        },
      ),
    );
  }
}

// ── Applicant card ─────────────────────────────────────────────────────────────
class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> application;
  final Function(String)     onStatusChange;
  final VoidCallback         onViewDetail;

  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

  const _ApplicantCard({
    required this.application,
    required this.onStatusChange,
    required this.onViewDetail,
  });

  Color _verdictColor(String? v) {
    if (v == 'good_fit')    return Colors.green;
    if (v == 'average_fit') return Colors.orange;
    if (v == 'weak_fit')    return Colors.red;
    return Colors.grey;
  }

  String _verdictLabel(String? v) {
    if (v == 'good_fit')    return 'Good Fit ✓';
    if (v == 'average_fit') return 'Average Fit';
    if (v == 'weak_fit')    return 'Weak Fit';
    return 'Pending';
  }

  Color _statusColor(String s) {
    if (s == 'accepted')   return Colors.green;
    if (s == 'shortlisted') return const Color(0xFF5C6BC0);
    if (s == 'rejected')   return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final applicant = application['applicant'] as Map<String, dynamic>? ?? {};
    final score     = application['match_score'] as num?;
    final verdict   = application['verdict']     as String?;
    final status    = application['status']      as String? ?? 'pending';
    final initials  = ((applicant['name'] as String?)?.isNotEmpty == true)
        ? (applicant['name'] as String).substring(0, 1).toUpperCase()
        : '?';

    return Card(
      elevation: 3,
      color:     Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius:          22,
                  backgroundColor: _primary.withValues(alpha: 0.12),
                  child: Text(initials,
                      style: const TextStyle(
                          color:      _primary,
                          fontWeight: FontWeight.bold,
                          fontSize:   18)),
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
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ],
                  ),
                ),
                if (score != null) _ScoreBadge(score: score.toInt()),
              ],
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: [
                if (verdict != null)
                  _Pill(
                      label: _verdictLabel(verdict),
                      color: _verdictColor(verdict)),
                _Pill(
                    label: status.capitalize(),
                    color: _statusColor(status)),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetail,
                    icon: const Icon(Icons.visibility_outlined,
                        size: 16, color: _primary),
                    label: const Text('Details',
                        style: TextStyle(color: _primary, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side:  BorderSide(color: _primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ActionMenu(
                    currentStatus: status, onStatusChange: onStatusChange),
              ],
            ),
          ],
        ),
      ),
    );
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
        width:  52,
        height: 52,
        decoration: BoxDecoration(
          shape:  BoxShape.circle,
          border: Border.all(color: _color, width: 2.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$score',
                style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.bold,
                    color:      _color)),
            Text('score', style: TextStyle(fontSize: 9, color: _color)),
          ],
        ),
      );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color  color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize:   11,
                color:      color,
                fontWeight: FontWeight.w600)),
      );
}

class _ActionMenu extends StatelessWidget {
  final String           currentStatus;
  final Function(String) onStatusChange;
  static const _primary = Color(0xFF5C6BC0);
  const _ActionMenu(
      {required this.currentStatus, required this.onStatusChange});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        onSelected: onStatusChange,
        color:      Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          if (currentStatus != 'shortlisted')
            const PopupMenuItem(
                value: 'shortlisted',
                child: Row(children: [
                  Icon(Icons.bookmark_outline, color: Color(0xFF5C6BC0)),
                  SizedBox(width: 8),
                  Text('Shortlist'),
                ])),
          if (currentStatus != 'accepted')
            const PopupMenuItem(
                value: 'accepted',
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Accept'),
                ])),
          if (currentStatus != 'rejected')
            const PopupMenuItem(
                value: 'rejected',
                child: Row(children: [
                  Icon(Icons.cancel_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Reject'),
                ])),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border:       Border.all(color: _primary.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Action',
                  style: TextStyle(
                      color:      _primary,
                      fontSize:   13,
                      fontWeight: FontWeight.w600)),
              SizedBox(width: 4),
              Icon(Icons.arrow_drop_down, color: _primary),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Applicant detail screen
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

  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _accent,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Applicant Detail',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _app == null
              ? const Center(child: Text('Failed to load.'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final applicant = _app!['applicant']    as Map<String, dynamic>? ?? {};
    final screening = _app!['ai_screening'] as Map<String, dynamic>?;
    final score     = _app!['match_score']  as num?;
    final verdict   = _app!['verdict']      as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ──────────────────────────────────────────
          Card(
            elevation: 3,
            color:     Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius:          30,
                    backgroundColor: _primary.withValues(alpha: 0.12),
                    child: Text(
                      ((applicant['name'] as String?)?.isNotEmpty == true)
                          ? (applicant['name'] as String)
                              .substring(0, 1)
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize:   24,
                          fontWeight: FontWeight.bold,
                          color:      _primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(applicant['name'] ?? '',
                            style: const TextStyle(
                                fontSize:   18,
                                fontWeight: FontWeight.bold)),
                        Text(applicant['email'] ?? '',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  if (score != null)
                    _LargeScore(score: score.toInt(), verdict: verdict),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (screening?['summary'] != null)
            _InfoCard(
              icon:  Icons.auto_awesome_outlined,
              title: 'AI Summary',
              color: _accent,
              child: Text(screening!['summary'],
                  style: const TextStyle(height: 1.6)),
            ),
          const SizedBox(height: 10),

          if (screening?['matched_experience'] != null)
            _InfoCard(
              icon:  Icons.work_history_outlined,
              title: 'Matched Experience',
              color: Colors.teal,
              child: Text(screening!['matched_experience'],
                  style: const TextStyle(height: 1.6)),
            ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (screening?['matched_skills'] != null)
                Expanded(
                  child: _InfoCard(
                    icon:  Icons.check_circle_outline,
                    title: 'Matched Skills',
                    color: Colors.green,
                    child: _TagWrap(
                      tags:  (screening!['matched_skills'] as List)
                          .cast<String>(),
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
                    icon:  Icons.cancel_outlined,
                    title: 'Missing Skills',
                    color: Colors.red,
                    child: _TagWrap(
                      tags:  (screening!['missing_skills'] as List)
                          .cast<String>(),
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (screening?['weak_points'] != null)
            _InfoCard(
              icon:  Icons.warning_amber_outlined,
              title: 'Weak Points',
              color: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (screening!['weak_points'] as List)
                    .cast<String>()
                    .map((w) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.arrow_right,
                                  size: 18, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(w,
                                      style: const TextStyle(
                                          fontSize: 13))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 20),

          // ── CV Section ───────────────────────────────────────────
          _CvSection(resumeSnapshot: _app!['resume_snapshot'] as Map<String, dynamic>?),
          const SizedBox(height: 20),

          // ── Action buttons ───────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus('accepted'),
                  icon:  const Icon(Icons.check,
                      color: Colors.white, size: 18),
                  label: const Text('Accept',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus('shortlisted'),
                  icon:  const Icon(Icons.bookmark_outline,
                      size: 18, color: _primary),
                  label: const Text('Shortlist',
                      style: TextStyle(color: _primary)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updateStatus('rejected'),
                  icon:  const Icon(Icons.close,
                      size: 18, color: Colors.red),
                  label: const Text('Reject',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

// ─────────────────────────────────────────────────────────────────────────────
// CV Section — renders Phase 1 resume_snapshot
// ─────────────────────────────────────────────────────────────────────────────
class _CvSection extends StatefulWidget {
  final Map<String, dynamic>? resumeSnapshot;
  const _CvSection({required this.resumeSnapshot});

  @override
  State<_CvSection> createState() => _CvSectionState();
}

class _CvSectionState extends State<_CvSection> {
  bool _expanded = false;

  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

  @override
  Widget build(BuildContext context) {
    final cv = widget.resumeSnapshot;

    return Card(
      elevation: 2,
      color:     Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // ── Collapsible header ──────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:        _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined,
                        color: _primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Candidate CV',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  if (cv == null)
                    Text('Not available',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color)),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: _primary,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ────────────────────────────────────
          if (_expanded && cv != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),

                  // Personal info
                  _CvRow(Icons.person_outline, 'Name',
                      cv['name'] as String?),
                  _CvRow(Icons.email_outlined, 'Email',
                      cv['email'] as String?),
                  _CvRow(Icons.phone_outlined, 'Phone',
                      cv['phone'] as String?),
                  _CvRow(Icons.location_on_outlined, 'Location',
                      cv['location'] as String?),
                  _CvRow(Icons.link, 'GitHub',
                      cv['github'] as String?),
                  _CvRow(Icons.work_history_outlined,
                      'Experience (years)',
                      cv['experience_years'] != null
                          ? '${cv['experience_years']}'
                          : null),
                  _CvRow(Icons.badge_outlined, 'Internships',
                      cv['internship_count'] != null
                          ? '${cv['internship_count']}'
                          : null),

                  // Skills
                  if (cv['skills'] is List &&
                      (cv['skills'] as List).isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CvSubHeading(
                        icon:  Icons.psychology_outlined,
                        label: 'Skills',
                        color: _accent),
                    const SizedBox(height: 8),
                    _TagWrap(
                      tags:  (cv['skills'] as List).cast<String>(),
                      color: _primary,
                    ),
                  ],

                  // Education
                  if (cv['education'] is List &&
                      (cv['education'] as List).isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CvSubHeading(
                        icon:  Icons.school_outlined,
                        label: 'Education',
                        color: Colors.teal),
                    const SizedBox(height: 6),
                    ...(cv['education'] as List)
                        .cast<Map<String, dynamic>>()
                        .map((e) => _CvBullet(
                              title: e['institution'] as String? ?? '',
                              sub:   [
                                if (e['degree'] != null)
                                  e['degree'] as String,
                                if (e['year'] != null)
                                  e['year'] as String,
                              ].join(' · '),
                            )),
                  ],

                  // Projects
                  if (cv['projects'] is List &&
                      (cv['projects'] as List).isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CvSubHeading(
                        icon:  Icons.folder_outlined,
                        label: 'Projects',
                        color: Colors.deepPurple),
                    const SizedBox(height: 6),
                    ...(cv['projects'] as List)
                        .cast<String>()
                        .map((p) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.arrow_right,
                                      size: 18,
                                      color: Colors.deepPurple),
                                  const SizedBox(width: 4),
                                  Expanded(
                                      child: Text(p,
                                          style: const TextStyle(
                                              fontSize: 13))),
                                ],
                              ),
                            )),
                  ],
                ],
              ),
            ),

          // ── Collapsed but cv is null ────────────────────────────
          if (_expanded && cv == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No CV data was saved with this application.',
                style: TextStyle(
                    color:
                        Theme.of(context).textTheme.bodySmall?.color),
              ),
            ),
        ],
      ),
    );
  }
}

class _CvRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String?  value;
  const _CvRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size:  15,
              color: Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color)),
          ),
          Expanded(
            child: Text(value!,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _CvSubHeading extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _CvSubHeading(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   13,
                  color:      color)),
        ],
      );
}

class _CvBullet extends StatelessWidget {
  final String title;
  final String sub;
  const _CvBullet({required this.title, required this.sub});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.circle, size: 6, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
class _LargeScore extends StatelessWidget {
  final int     score;
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
            width:  60,
            height: 60,
            decoration: BoxDecoration(
              shape:  BoxShape.circle,
              border: Border.all(color: _color, width: 3),
            ),
            child: Center(
              child: Text('$score',
                  style: TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                      color:      _color)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            verdict == 'good_fit'
                ? 'Good Fit'
                : verdict == 'average_fit'
                    ? 'Average'
                    : 'Weak',
            style: TextStyle(
                fontSize:   11,
                color:      _color,
                fontWeight: FontWeight.w600),
          ),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Color    color;
  final Widget   child;
  const _InfoCard(
      {required this.icon,
      required this.title,
      required this.color,
      required this.child});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        color:     Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
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
                          fontSize:   13,
                          color:      color)),
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
  final Color        color;
  const _TagWrap({required this.tags, required this.color});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing:    5,
        runSpacing: 4,
        children: tags
            .map((t) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(t,
                      style: TextStyle(
                          fontSize:   11,
                          color:      color,
                          fontWeight: FontWeight.w500)),
                ))
            .toList(),
      );
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}