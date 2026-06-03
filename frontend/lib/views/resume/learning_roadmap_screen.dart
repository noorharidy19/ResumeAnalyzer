import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LearningRoadmapScreen extends StatefulWidget {
  final Map<String, dynamic> phase2;
  final Map<String, dynamic> phase3;

  const LearningRoadmapScreen({
    required this.phase2,
    required this.phase3,
    super.key,
  });

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {

  // ── Strip "certificate/certification" word from resource name ─────────────
  String _cleanResourceName(String resource) {
    return resource
        .replaceAll(RegExp(r'\bcertificate\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bcertification\b', caseSensitive: false), '')
        .replaceAll(RegExp(r' {2,}'), ' ')   // collapse double spaces
        .replaceAll(RegExp(r'\s+—'), ' —')   // fix "  —" → " —"
        .replaceAll(RegExp(r'—\s+'), '— ')   // fix "—  " → "— "
        .trim();
  }

  // ── Data-driven "Why learn this?" using priority + source ─────────────────
  String _skillReason(
      String skill, String priority, int neededInJobs, String source) {
    final jobs =
        neededInJobs == 1 ? '1 matched job' : '$neededInJobs matched jobs';

    final sourceNote = source == 'coursera'
        ? 'A top-rated Coursera course is available.'
        : source == 'youtube'
            ? 'A free YouTube tutorial is available.'
            : source == 'hardcoded'
                ? 'Free learning resources are available.'
                : 'Learning resources are available.';

    if (priority == 'High') {
      return '$skill is a core requirement missing from $jobs. $sourceNote';
    } else if (priority == 'Medium') {
      return '$skill is a preferred skill in $jobs and will strengthen your profile. $sourceNote';
    } else {
      return '$skill is a nice-to-have skill in $jobs. $sourceNote';
    }
  }

  // ── Icon based on resource type ───────────────────────────────────────────
  IconData _resourceIcon(String resource) {
    final lower = resource.toLowerCase();
    if (lower.contains('course')) return Icons.school;
    if (lower.contains('tutorial')) return Icons.play_circle_outline;
    if (lower.contains('docs') || lower.contains('documentation')) {
      return Icons.menu_book;
    }
    return Icons.menu_book;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);

    // Only phase2 recommendations — no duplicate phase3 roadmap section
    final recommendations =
        widget.phase2['recommendations'] as List<dynamic>? ?? [];

    final hintColor   = Theme.of(context).textTheme.bodySmall?.color;
    final surfaceTint =
        Theme.of(context).colorScheme.surface.withValues(alpha: 0.6);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Skills to Learn ────────────────────────────────────────────
        if (recommendations.isNotEmpty) ...[
          const Text(
            'Skills to Learn',
            style: TextStyle(
              fontSize:   18,
              fontWeight: FontWeight.bold,
              color:      Color(0xFF5C6BC0),
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(
              recommendations.length,
              (index) => _buildRecommendationCard(
                index,
                recommendations[index] as Map<String, dynamic>,
                primary,
                hintColor,
                surfaceTint,
              ),
            ),
          ),
        ],

        if (recommendations.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No learning recommendations available'),
            ),
          ),
      ],
    );
  }

  // ── Recommendation card ──────────────────────────────────────────────────
  Widget _buildRecommendationCard(
    int index,
    Map<String, dynamic> rec,
    Color primary,
    Color? hintColor,
    Color surfaceTint,
  ) {
    final skill        = rec['skill']          as String? ?? '';
    final priority     = rec['priority']       as String? ?? '';
    final rawResource  = rec['resource']       as String? ?? '';
    final url          = rec['url']            as String? ?? '';
    final hours        = rec['est_hours']      as int?    ?? 0;
    final neededInJobs = rec['needed_in_jobs'] as int?    ?? 0;
    final source       = rec['source']         as String? ?? '';
    final rating       = rec['rating']; // double or null

    // Clean "certificate/certification" word out of the display name
    final resource = _cleanResourceName(rawResource);

    final priorityColor = priority == 'High'
        ? Colors.red
        : (priority == 'Medium' ? Colors.orange : Colors.green);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step number + skill + priority badge ─────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step circle
                Container(
                  width:  32,
                  height: 32,
                  decoration: BoxDecoration(
                    color:        primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:      primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Needed in $neededInJobs matched job(s)',
                        style: TextStyle(fontSize: 12, color: hintColor),
                      ),
                    ],
                  ),
                ),
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:        priorityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.bold,
                      color:      priorityColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Why learn this? ───────────────────────────────────────
            Text(
              'Why learn this?',
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _skillReason(skill, priority, neededInJobs, source),
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 12),

            // ── Resource box ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        surfaceTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hours + optional star rating
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: hintColor),
                      const SizedBox(width: 8),
                      Text(
                        '~$hours hours',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize:   12,
                        ),
                      ),
                      if (rating != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Resource name with smart icon (no "certificate" word)
                  if (resource.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _resourceIcon(resource),
                          size:  14,
                          color: const Color(0xFF5C6BC0),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            resource,
                            style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // View Resource link
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final uri = Uri.parse(url);
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.link,
                              size: 14, color: Color(0xFF5C6BC0)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'View Resource',
                              style: TextStyle(
                                fontSize:   12,
                                color:      Color(0xFF5C6BC0),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}