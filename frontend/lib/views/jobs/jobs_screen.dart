import 'package:flutter/material.dart';
import '../../services/job_service.dart';
import '../../services/application_service.dart';
import 'job_detail_screen.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  final JobService _jobService = JobService();

  List<dynamic> _jobs     = [];
  List<dynamic> _filtered = [];
  bool    _isLoading      = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  // Company-side brand colors — these are intentional accent colors for
  // the job-board flow and live on a gradient/coloured AppBar, so they
  // stay as constants. Card and scaffold backgrounds use theme values.
  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

  @override
  void initState() {
    super.initState();
    _loadJobs();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final jobs = await _jobService.getAllJobs();
      setState(() {
        _jobs     = jobs;
        _filtered = jobs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _jobs.where((j) {
        final title   = (j['title']               ?? '').toString().toLowerCase();
        final company = (j['company']?['name']    ?? '').toString().toLowerCase();
        return title.contains(q) || company.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _accent,
        elevation:       0,
        title: const Text(
          'Job Openings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadJobs,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar (sits under the coloured AppBar) ──────────────
          Container(
            color:   _accent,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText:  'Search jobs or companies...',
                hintStyle: TextStyle(color: hintColor, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _primary),
                filled:    true,
                // In dark mode use card colour so the field pops against
                // the blue banner; in light mode keep the familiar white.
                fillColor: Theme.of(context).cardColor,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadJobs,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: hintColor),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'No jobs available'
                  : 'No results found',
              style: TextStyle(fontSize: 16, color: hintColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      color:     _primary,
      child: ListView.separated(
        padding:          const EdgeInsets.all(16),
        itemCount:        _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _JobCard(job: _filtered[i] as Map<String, dynamic>),
      ),
    );
  }
}

// ── Job card ───────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  final Map<String, dynamic> job;

  static const _primary = Color(0xFF5C6BC0);
  static const _accent  = Color(0xFF3F51B5);

  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final reqs = (job['requirements'] as List<dynamic>? ?? [])
        .take(3)
        .map((r) => r.toString())
        .toList();

    final hintColor = Theme.of(context).textTheme.bodySmall?.color;
    final cardColor = Theme.of(context).cardColor;

    return Card(
      elevation: 3,
      color:     cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => JobDetailScreen(job: job)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title + company ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:        _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.work_outline,
                        color: _primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['title'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job['company']?['name'] ?? '',
                          style:
                              TextStyle(color: hintColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Location + type ────────────────────────────────────
              Wrap(
                spacing: 12,
                children: [
                  if (job['location'] != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on_outlined,
                          size: 13, color: hintColor),
                      const SizedBox(width: 3),
                      Text(job['location'],
                          style: TextStyle(
                              fontSize: 12, color: hintColor)),
                    ]),
                  if (job['job_type'] != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.schedule_outlined,
                          size: 13, color: hintColor),
                      const SizedBox(width: 3),
                      Text(job['job_type'],
                          style: TextStyle(
                              fontSize: 12, color: hintColor)),
                    ]),
                ],
              ),

              // ── Requirement chips ──────────────────────────────────
              if (reqs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing:    6,
                  runSpacing: 4,
                  children: reqs
                      .map((r) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      _primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(r,
                                style: const TextStyle(
                                    fontSize: 11, color: _primary)),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 12),

              // ── Apply button ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [_ApplyButton(jobId: job['id'] as int)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Apply button with state ────────────────────────────────────────────────────
class _ApplyButton extends StatefulWidget {
  final int jobId;
  const _ApplyButton({required this.jobId});

  @override
  State<_ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends State<_ApplyButton> {
  final ApplicationService _appService = ApplicationService();
  bool _loading = false;
  bool _applied = false;

  static const _accent = Color(0xFF3F51B5);

  Future<void> _apply() async {
    setState(() => _loading = true);
    try {
      await _appService.applyToJob(widget.jobId);
      setState(() { _applied = true; _loading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Application submitted! AI is analyzing your CV... ⚙️'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_applied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:        Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text('Applied',
                style: TextStyle(
                    color:      Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize:   13)),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _loading ? null : _apply,
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      child: _loading
          ? const SizedBox(
              width:  16,
              height: 16,
              child:  CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Text('Apply Now',
              style: TextStyle(
                  color:      Colors.white,
                  fontSize:   13,
                  fontWeight: FontWeight.w600)),
    );
  }
}