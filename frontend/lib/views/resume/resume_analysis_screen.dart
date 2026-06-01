import 'package:flutter/material.dart';
import 'job_matches_screen.dart';
import 'learning_roadmap_screen.dart';
import 'interview_questions_screen.dart';
import 'career_path_screen.dart';
import '../cv_enhancement/cv_enhancement_screen.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  // json response from backend after analyzing resume, contains all data for different phases
  final Map<String, dynamic> analysisData;

  const ResumeAnalysisScreen({required this.analysisData, super.key});

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

    final phase1 =
        widget.analysisData['phase1'] as Map<String, dynamic>? ?? {};
    final phase2 =
        widget.analysisData['phase2'] as Map<String, dynamic>? ?? {};
    final phase3 =
        widget.analysisData['phase3'] as Map<String, dynamic>? ?? {};

    // analysis_id comes back from backend as a string like "analysis_20250524_143022"
    final analysisId =
        widget.analysisData['analysis_id'] as String? ?? '';

    final hintColor = Theme.of(context).textTheme.bodySmall?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // Transparent AppBar — foreground adapts via theme foregroundColor
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resume Analysis',
          style: TextStyle(
            // Use theme body text color so it adapts in dark mode
            color:      Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Tab navigation ───────────────────────────────────────────
          Container(
            // cardColor adapts: white in light, dark card in dark mode
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabButton(0, 'Extracted Data', primary, hintColor),
                  _buildTabButton(1, 'Job Matches',    primary, hintColor),
                  _buildTabButton(2, 'Learning Path',  primary, hintColor),
                  _buildTabButton(3, 'Interview Q&A',  primary, hintColor),
                  _buildTabButton(4, 'Career Path',    primary, hintColor),
                  _buildTabButton(5, '✨ Enhance CV',  primary, hintColor),
                ],
              ),
            ),
          ),
          Divider(color: primary.withValues(alpha: 0.2), height: 1),

          // ── Page view ────────────────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() => _currentPage = page);
              },
              children: [
                _buildPhase1View(phase1, primary),
                JobMatchesScreen(
                  phase2:       phase2,
                  analysisData: widget.analysisData,
                ),
                LearningRoadmapScreen(phase2: phase2, phase3: phase3),
                InterviewQuestionsScreen(phase3: phase3),
                CareerPathScreen(phase3: phase3),
                // Tab 5: CV Enhancement — loads inline, polls until Phase 4 is ready
                CVEnhancementScreen(analysisId: analysisId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
      int index, String label, Color primary, Color? hintColor) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeInOut,
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
            fontSize:   13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            // active tab uses accent; inactive uses theme hint color
            color:      isActive ? primary : hintColor,
          ),
        ),
      ),
    );
  }

  // ── Phase 1 — Extracted Data ───────────────────────────────────────────────
  Widget _buildPhase1View(Map<String, dynamic> phase1, Color primary) {
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Personal Info
        _buildSectionCard('Personal Information', primary, [
          _buildInfoRow('Name',     phase1['name']     ?? 'Not detected', hintColor),
          _buildInfoRow('Email',    phase1['email']    ?? 'Not detected', hintColor),
          _buildInfoRow('Phone',    phase1['phone']    ?? 'Not detected', hintColor),
          _buildInfoRow('Location', phase1['location'] ?? 'Not detected', hintColor),
          if (phase1['github'] != null)
            _buildInfoRow('GitHub', phase1['github'], hintColor),
        ]),
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
          phase1['experience_years']  ?? 0,
          phase1['internship_count']  ?? 0,
          primary,
          hintColor,
        ),
        const SizedBox(height: 12),
        // Education
        _buildEducationCard(
          'Education',
          phase1['education'] as List<dynamic>? ?? [],
          primary,
          hintColor,
        ),
        const SizedBox(height: 12),
        // Projects
        _buildProjectsCard(
          'Projects',
          phase1['projects'] as List<dynamic>? ?? [],
          primary,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            _pageController.animateToPage(
              5,
              duration: const Duration(milliseconds: 300),
              curve:    Curves.easeInOut,
            );
          },
          icon:  const Icon(Icons.auto_fix_high),
          label: const Text('Enhance CV'),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
      String title, Color primary, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value, Color? hintColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:      hintColor,
                fontSize:   12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard(
      String title, List<dynamic> skills, Color primary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            if (skills.isEmpty)
              const Text('No skills detected')
            else
              Wrap(
                spacing:    8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Chip(
                          label:           Text(skill.toString()),
                          backgroundColor: primary.withValues(alpha: 0.1),
                          labelStyle:      TextStyle(color: primary),
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
    Color? hintColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildMetricCard(
                        '$years', 'Years Experience', primary, hintColor)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildMetricCard(
                        '$internships', 'Internships', primary, hintColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String value, String label, Color primary, Color? hintColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 12, color: hintColor)),
        ],
      ),
    );
  }

  Widget _buildEducationCard(
    String title,
    List<dynamic> education,
    Color primary,
    Color? hintColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            if (education.isEmpty)
              const Text('No education detected')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: education.map((edu) {
                  final eduMap = edu as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(eduMap['institution'] ?? 'Unknown',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        if (eduMap['degree'] != null)
                          Text(eduMap['degree'],
                              style: TextStyle(
                                  fontSize: 12, color: hintColor)),
                        if (eduMap['year'] != null)
                          Text('${eduMap['year']}',
                              style: TextStyle(
                                  fontSize: 12, color: hintColor)),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsCard(
      String title, List<dynamic> projects, Color primary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: primary)),
            const SizedBox(height: 12),
            if (projects.isEmpty)
              const Text('No projects detected')
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: projects.map((project) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(project.toString())),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}