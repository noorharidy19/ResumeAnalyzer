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
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);

    final recommendations = widget.phase2['recommendations'] as List<dynamic>? ?? [];
    final roadmap = widget.phase3['learning_roadmap'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Recommendations from Phase 2
        if (recommendations.isNotEmpty) ...[
          Text(
            'Skills to Learn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(
              recommendations.length,
              (index) => _buildRecommendationCard(
                recommendations[index] as Map<String, dynamic>,
                primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Learning Roadmap from Phase 3
        if (roadmap.isNotEmpty) ...[
          Text(
            'Personalized Learning Path',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(
              roadmap.length,
              (index) => _buildRoadmapCard(
                roadmap[index] as Map<String, dynamic>,
                index,
                primary,
              ),
            ),
          ),
        ],
        if (recommendations.isEmpty && roadmap.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No learning recommendations available'),
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> rec, Color primary) {
    final skill = rec['skill'] as String? ?? '';
    final priority = rec['priority'] as String? ?? '';
    final resource = rec['resource'] as String? ?? '';
    final url = rec['url'] as String? ?? '';
    final hours = rec['est_hours'] as int? ?? 0;
    final neededInJobs = rec['needed_in_jobs'] as int? ?? 0;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Needed in $neededInJobs matched job(s)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Resource info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '~$hours hours',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (resource.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (url.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.link, size: 14, color: Color(0xFF5C6BC0)),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'View Resource',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF5C6BC0),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapCard(Map<String, dynamic> item, int index, Color primary) {
    final skill = item['skill'] as String? ?? '';
    final priority = item['priority'] as String? ?? '';
    final reason = item['reason'] as String? ?? '';
    final resource = item['resource_title'] as String? ?? '';
    final url = item['resource_url'] as String? ?? '';
    final time = item['estimated_time'] as String? ?? '';

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
            // Title with step number
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$priority Priority',
                          style: TextStyle(
                            fontSize: 11,
                            color: priorityColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Reason
            if (reason.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Why learn this?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            // Resource details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (resource.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      resource,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (url.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.link, size: 14, color: Color(0xFF5C6BC0)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'View Resource',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF5C6BC0),
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
