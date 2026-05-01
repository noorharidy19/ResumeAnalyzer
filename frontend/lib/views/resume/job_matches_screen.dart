import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class JobMatchesScreen extends StatefulWidget {
  final Map<String, dynamic> phase2;
  final Map<String, dynamic> analysisData;

  const JobMatchesScreen({
    required this.phase2,
    required this.analysisData,
    super.key,
  });

  @override
  State<JobMatchesScreen> createState() => _JobMatchesScreenState();
}

class _JobMatchesScreenState extends State<JobMatchesScreen> {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);

    final matches = widget.phase2['matches'] as List<dynamic>? ?? [];
    final summary = widget.phase2['summary'] as String? ?? '';
    final careerLevel = widget.phase2['career_level'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        if (summary.isNotEmpty)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [primary.withOpacity(0.1), primary.withOpacity(0.05)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Chip(
                    label: Text(careerLevel),
                    backgroundColor: primary.withOpacity(0.2),
                    labelStyle: TextStyle(color: primary),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        // Job matches
        Text(
          'Matched Jobs',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 12),
        if (matches.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No job matches found'),
            ),
          )
        else
          Column(
            children: List.generate(
              matches.length,
              (index) => _buildJobCard(matches[index] as Map<String, dynamic>, primary),
            ),
          ),
      ],
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, Color primary) {
    final title = job['title'] as String? ?? 'Unknown';
    final company = job['company'] as String? ?? 'Unknown';
    final location = job['location'] as String? ?? '';
    final matchScore = job['match_score'] as int? ?? 0;
    final level = job['level'] as String? ?? '';
    final applyLink = job['apply_link'] as String? ?? '';
    final skillGap = job['skill_gap'] as Map<String, dynamic>? ?? {};
    final coveragePct = skillGap['coverage_pct'] as int? ?? 0;
    final matchedReq = skillGap['matched_required'] as List<dynamic>? ?? [];
    final missingReq = skillGap['missing_required'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and match score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$matchScore%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Location and level
            Row(
              children: [
                if (location.isNotEmpty) ...[
                  Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                ],
                if (level.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Skill gap
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
                      const Text(
                        'Skill Coverage: ',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: coveragePct / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(
                              coveragePct >= 80
                                  ? Colors.green
                                  : (coveragePct >= 50 ? Colors.orange : Colors.red),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$coveragePct%',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (matchedReq.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'You have:',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: matchedReq
                              .take(5)
                              .map((skill) => Chip(
                                    label: Text(skill.toString()),
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                    labelStyle:
                                        const TextStyle(fontSize: 11, color: Colors.green),
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  if (missingReq.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Still need:',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: missingReq
                              .take(5)
                              .map((skill) => Chip(
                                    label: Text(skill.toString()),
                                    backgroundColor: Colors.red.withOpacity(0.2),
                                    labelStyle:
                                        const TextStyle(fontSize: 11, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Apply button
            if (applyLink.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(applyLink))) {
                      await launchUrl(Uri.parse(applyLink));
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Apply Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
