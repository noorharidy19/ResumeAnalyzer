import 'package:flutter/material.dart';

class InterviewQuestionsScreen extends StatefulWidget {
  final Map<String, dynamic> phase3;

  const InterviewQuestionsScreen({
    required this.phase3,
    super.key,
  });

  @override
  State<InterviewQuestionsScreen> createState() =>
      _InterviewQuestionsScreenState();
}

class _InterviewQuestionsScreenState extends State<InterviewQuestionsScreen> {
  late List<bool> _expandedState;

  @override
  void initState() {
    super.initState();
    final questions = widget.phase3['interview_questions'] as List<dynamic>? ?? [];
    _expandedState = List.filled(questions.length, false);
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);

    final questions = widget.phase3['interview_questions'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'Interview Preparation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Role-specific questions for your top matched position',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        if (questions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No interview questions generated'),
            ),
          )
        else
          Column(
            children: List.generate(
              questions.length,
              (index) => _buildQuestionCard(
                questions[index] as Map<String, dynamic>,
                index,
                primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(
    Map<String, dynamic> question,
    int index,
    Color primary,
  ) {
    final q = question['question'] as String? ?? '';
    final category = question['category'] as String? ?? '';
    final difficulty = question['difficulty'] as String? ?? '';

    final categoryColor = _getCategoryColor(category);
    final difficultyColor = _getDifficultyColor(difficulty);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedState[index] = expanded;
          });
        },
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
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
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 10,
                            color: categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            color: difficultyColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: Colors.grey.withOpacity(0.2)),
                const SizedBox(height: 12),
                _buildAnswerGuide(question, primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerGuide(Map<String, dynamic> question, Color primary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Answer Tips:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTipItem(
          'Use STAR method',
          'Situation • Task • Action • Result for behavioral questions',
          primary,
        ),
        const SizedBox(height: 8),
        _buildTipItem(
          'Be specific',
          'Provide concrete examples from your projects or experience',
          primary,
        ),
        const SizedBox(height: 8),
        _buildTipItem(
          'Link to role',
          'Connect your answer to the job requirements and responsibilities',
          primary,
        ),
      ],
    );
  }

  Widget _buildTipItem(String title, String description, Color primary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 16, color: primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technical':
        return Colors.blue;
      case 'behavioral':
        return Colors.green;
      case 'situational':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
