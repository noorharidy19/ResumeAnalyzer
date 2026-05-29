import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/job_service.dart';
import '../auth/login_screen.dart';
import 'post_job_screen.dart';
import 'applicants_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});

  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardScreenState();
}

class _CompanyDashboardScreenState extends State<CompanyDashboardScreen> {
  final JobService _jobService = JobService();

  List<dynamic> _myJobs    = [];
  bool _isLoading          = true;
  String? _error;
  String _companyName      = '';

  // ── Theme colors ────────────────────────────────────────────────────────
  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);
  static const bg      = Color(0xFFF0F7FF);

  @override
  void initState() {
    super.initState();
    _initName();
    _loadMyJobs();
  }

  Future<void> _initName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _companyName = prefs.getString('user_name') ?? 'Company');
  }

  Future<void> _loadMyJobs() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final jobs = await _jobService.getMyJobPosts();
      setState(() { _myJobs = jobs; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteJob(int jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete job post?'),
        content: const Text('This will also remove all applications for this job.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _jobService.deleteJob(jobId);
      _loadMyJobs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.business, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _companyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMyJobs,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const PostJobScreen()),
          );
          if (created == true) _loadMyJobs();
        },
        backgroundColor: accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post a Job', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Stats banner ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                _StatChip(
                  label: 'Total Jobs',
                  value: '${_myJobs.length}',
                  icon: Icons.work_outline,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Open',
                  value: '${_myJobs.where((j) => j['status'] == 'open').length}',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
          ),

          // ── Job list ───────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primary));
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
              onPressed: _loadMyJobs,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_myJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No job posts yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap the button below to post your first job",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyJobs,
      color: primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _myJobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _CompanyJobCard(
          job: _myJobs[i] as Map<String, dynamic>,
          onDelete: () => _deleteJob(_myJobs[i]['id'] as int),
          onViewApplicants: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ApplicantsScreen(
                jobId:    _myJobs[i]['id'] as int,
                jobTitle: _myJobs[i]['title'] as String,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat chip ──────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Company job card ───────────────────────────────────────────────────────────
class _CompanyJobCard extends StatelessWidget {
  final Map<String, dynamic> job;
  final VoidCallback onDelete;
  final VoidCallback onViewApplicants;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);

  const _CompanyJobCard({
    required this.job,
    required this.onDelete,
    required this.onViewApplicants,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = job['status'] == 'open';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.work_outline, color: primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    job['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOpen
                          ? Colors.green.withOpacity(0.4)
                          : Colors.grey.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? Colors.green[700] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),

            if (job['location'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(job['location'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (job['job_type'] != null) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.work_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(job['job_type'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewApplicants,
                    icon: const Icon(Icons.people_outline, size: 18, color: primary),
                    label: const Text('View Applicants',
                        style: TextStyle(color: primary, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete job',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}