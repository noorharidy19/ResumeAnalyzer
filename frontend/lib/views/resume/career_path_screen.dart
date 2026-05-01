import 'package:flutter/material.dart';

class CareerPathScreen extends StatelessWidget {
  final Map<String, dynamic> phase3;

  const CareerPathScreen({
    required this.phase3,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);

    final resumeFeedback = phase3['resume_feedback'] as Map<String, dynamic>? ?? {};
    final careerPath = phase3['career_path'] as Map<String, dynamic>? ?? {};
    final finalRecommendation =
        phase3['final_recommendation'] as String? ?? 'No recommendation available';

    final overallScore = resumeFeedback['overall_score'] as int? ?? 0;
    final strengths = resumeFeedback['strengths'] as List<dynamic>? ?? [];
    final weaknesses = resumeFeedback['weaknesses'] as List<dynamic>? ?? [];
    final improvements = resumeFeedback['improvements'] as List<dynamic>? ?? [];
    final summary = resumeFeedback['summary'] as String? ?? '';

    final recommendedPath = careerPath['recommended_path'] as String? ?? '';
    final reason = careerPath['reason'] as String? ?? '';
    final alternativePaths =
        careerPath['alternative_paths'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resume Score
        _buildScoreCard(overallScore, primary),
        const SizedBox(height: 16),
        // Resume Summary
        if (summary.isNotEmpty)
          _buildSectionCard(
            'Resume Summary',
            summary,
            primary,
            Icons.description,
          ),
        const SizedBox(height: 16),
        // Strengths
        if (strengths.isNotEmpty)
          _buildListCard(
            'Your Strengths',
            strengths.cast<String>(),
            Colors.green,
            Icons.star,
          ),
        const SizedBox(height: 16),
        // Weaknesses
        if (weaknesses.isNotEmpty)
          _buildListCard(
            'Areas to Improve',
            weaknesses.cast<String>(),
            Colors.orange,
            Icons.flag,
          ),
        const SizedBox(height: 16),
        // Improvements
        if (improvements.isNotEmpty)
          _buildListCard(
            'Recommended Improvements',
            improvements.cast<String>(),
            primary,
            Icons.lightbulb,
          ),
        const SizedBox(height: 16),
        // Career Path
        if (recommendedPath.isNotEmpty) ...[
          _buildCareerPathCard(
            recommendedPath,
            reason,
            alternativePaths.cast<String>(),
            primary,
          ),
          const SizedBox(height: 16),
        ],
        // Final Recommendation
        _buildSectionCard(
          'Final Recommendation',
          finalRecommendation,
          primary,
          Icons.recommend,
        ),
        const SizedBox(height: 16),
        // Action Items
        _buildActionItems(primary),
      ],
    );
  }

  Widget _buildScoreCard(int score, Color primary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.1), primary.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Resume Score',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(
                      score >= 80
                          ? Colors.green
                          : (score >= 60 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getScoreLabel(score),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    String content,
    Color primary,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerPathCard(
    String path,
    String reason,
    List<String> alternatives,
    Color primary,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recommended Career Path',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    path,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (reason.isNotEmpty)
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            if (alternatives.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Alternative Paths:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: alternatives
                    .map((alt) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              const Text('→ '),
                              Expanded(
                                child: Text(
                                  alt,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionItems(Color primary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.checklist, color: primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Next Steps',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildActionItem(1, 'Complete the Learning Path', Colors.blue),
            const SizedBox(height: 8),
            _buildActionItem(2, 'Build projects with new skills', Colors.green),
            const SizedBox(height: 8),
            _buildActionItem(3, 'Update resume after learning', Colors.orange),
            const SizedBox(height: 8),
            _buildActionItem(4, 'Apply to matched positions', Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(int number, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent! Ready for top positions';
    if (score >= 80) return 'Great! You\'re competitive';
    if (score >= 70) return 'Good. Consider improvements below';
    if (score >= 60) return 'Decent. Follow recommendations';
    return 'Needs work. Focus on key improvements';
  }
}
