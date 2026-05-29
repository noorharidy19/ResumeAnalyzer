import 'package:flutter/material.dart';
import '../../services/application_service.dart';

class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final requirements = (job['requirements'] as List<dynamic>? ?? [])
        .map((r) => r.toString())
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(job['title'] ?? 'Job Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              job['title'] ?? '',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              job['company']?['name'] ?? '',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 12),

            // Meta chips row
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                if (job['location'] != null)
                  _MetaChip(Icons.location_on_outlined, job['location']),
                if (job['job_type'] != null)
                  _MetaChip(Icons.work_outline, job['job_type']),
                _MetaChip(
                  Icons.circle,
                  job['status'] == 'open' ? 'Open' : 'Closed',
                  color: job['status'] == 'open' ? Colors.green : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            _SectionHeader('Job Description'),
            const SizedBox(height: 8),
            Text(
              job['description'] ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 20),

            // Requirements
            if (requirements.isNotEmpty) ...[
              _SectionHeader('Requirements'),
              const SizedBox(height: 8),
              ...requirements.map(
                (req) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(child: Text(req)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Apply button
            SizedBox(
              width: double.infinity,
              child: _ApplyButtonFull(jobId: job['id'] as int),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color ?? Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _ApplyButtonFull extends StatefulWidget {
  final int jobId;
  const _ApplyButtonFull({required this.jobId});

  @override
  State<_ApplyButtonFull> createState() => _ApplyButtonFullState();
}

class _ApplyButtonFullState extends State<_ApplyButtonFull> {
  final ApplicationService _appService = ApplicationService();
  bool _loading = false;
  bool _applied = false;

  Future<void> _apply() async {
    setState(() => _loading = true);
    try {
      await _appService.applyToJob(widget.jobId);
      setState(() {
        _applied = true;
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_applied) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Application Submitted'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    return ElevatedButton(
      onPressed: _loading ? null : _apply,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Apply Now', style: TextStyle(fontSize: 16)),
    );
  }
}