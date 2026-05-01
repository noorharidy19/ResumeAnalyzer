import 'package:flutter/material.dart';
import 'job_matches_screen.dart';
import 'learning_roadmap_screen.dart';
import 'interview_questions_screen.dart';
import 'career_path_screen.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic> analysisData;

  const ResumeAnalysisScreen({
    required this.analysisData,
    super.key,
  });

  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);
    const bg = Color(0xFFF6F8FF);

    final phase1 = widget.analysisData['phase1'] as Map<String, dynamic>? ?? {};
    final phase2 = widget.analysisData['phase2'] as Map<String, dynamic>? ?? {};
    final phase3 = widget.analysisData['phase3'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Resume Analysis',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Tab navigation
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(0, 'Extracted Data', primary),
                  _buildTabButton(1, 'Job Matches', primary),
                  _buildTabButton(2, 'Learning Path', primary),
                  _buildTabButton(3, 'Interview Q&A', primary),
                  _buildTabButton(4, 'Career Path', primary),
                ],
              ),
            ),
          ),
          Divider(color: primary.withOpacity(0.2), height: 1),
          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildPhase1View(phase1, primary, bg),
                JobMatchesScreen(
                  phase2: phase2,
                  analysisData: widget.analysisData,
                ),
                LearningRoadmapScreen(
                  phase2: phase2,
                  phase3: phase3,
                ),
                InterviewQuestionsScreen(
                  phase3: phase3,
                ),
                CareerPathScreen(
                  phase3: phase3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, Color primary) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? primary : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildPhase1View(
    Map<String, dynamic> phase1,
    Color primary,
    Color bg,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Personal Info
        _buildSectionCard(
          'Personal Information',
          primary,
          [
            _buildInfoRow('Name', phase1['name'] ?? 'Not detected'),
            _buildInfoRow('Email', phase1['email'] ?? 'Not detected'),
            _buildInfoRow('Phone', phase1['phone'] ?? 'Not detected'),
            _buildInfoRow('Location', phase1['location'] ?? 'Not detected'),
            if (phase1['github'] != null)
              _buildInfoRow('GitHub', phase1['github']),
          ],
        ),
        const SizedBox(height: 12),
        // Skills
        _buildSkillsCard(
          'Skills Detected',
          phase1['skills'] as List<dynamic>? ?? [],
          primary,
        ),
        const SizedBox(height: 12),
        // Experience
        _buildExperienceCard(
          'Experience',
          phase1['experience_years'] ?? 0,
          phase1['internship_count'] ?? 0,
          primary,
        ),
        const SizedBox(height: 12),
        // Education
        _buildEducationCard(
          'Education',
          phase1['education'] as List<dynamic>? ?? [],
          primary,
        ),
        const SizedBox(height: 12),
        // Projects
        _buildProjectsCard(
          'Projects',
          phase1['projects'] as List<dynamic>? ?? [],
          primary,
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    Color primary,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(
    String title,
    List<dynamic> skills,
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
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              const Text('No skills detected')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Chip(
                          label: Text(skill.toString()),
                          backgroundColor: primary.withOpacity(0.1),
                          labelStyle: TextStyle(color: primary),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceCard(
    String title,
    dynamic years,
    dynamic internships,
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
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    '$years',
                    'Years Experience',
                    primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    '$internships',
                    'Internships',
                    primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String value, String label, Color primary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard(
    String title,
    List<dynamic> education,
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
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            if (education.isEmpty)
              const Text('No education detected')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: education
                    .map((edu) {
                      final eduMap = edu as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eduMap['institution'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (eduMap['degree'] != null)
                              Text(
                                eduMap['degree'],
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            if (eduMap['year'] != null)
                              Text(
                                '${eduMap['year']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsCard(
    String title,
    List<dynamic> projects,
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
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            if (projects.isEmpty)
              const Text('No projects detected')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: projects
                    .map((project) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(project.toString()),
                            ),
                          ],
                        ),
                      );
                    })
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
