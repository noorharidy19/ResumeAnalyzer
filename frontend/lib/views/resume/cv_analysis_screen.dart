import 'package:flutter/material.dart';

class CVAnalysisScreen extends StatelessWidget {
  final Map<String, dynamic> cvData;
  const CVAnalysisScreen({required this.cvData, super.key});

  int _computeTotalExperience(List<dynamic>? experiences) {
    if (experiences == null) return 0;
    final now = DateTime.now().year;
    var total = 0;
    for (final e in experiences) {
      try {
        final start = e['startYear'] is int ? e['startYear'] as int : int.tryParse('${e['startYear']}') ?? now;
        final end = e['endYear'] is int ? e['endYear'] as int : (e['endYear'] == null ? now : int.tryParse('${e['endYear']}') ?? now);
        total += (end - start).abs();
      } catch (_) {
        // ignore malformed entries
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final personal = cvData['personal'] as Map<String, dynamic>?;
    final education = cvData['education'] as List<dynamic>?;
    final experience = cvData['experience'] as List<dynamic>?;
    final skills = (cvData['skills'] as List<dynamic>?)?.cast<String>() ?? <String>[];

    final totalYears = _computeTotalExperience(experience);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Analysis'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Personal Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (personal != null) ...[
                  Text(personal['name'] ?? '-', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(personal['email'] ?? '-', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(personal['phone'] ?? '-', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(personal['location'] ?? '-', style: const TextStyle(color: Colors.black54)),
                ] else
                  const Text('No personal info detected'),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Summary & Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(cvData['summary'] ?? 'No summary extracted', style: const TextStyle(color: Colors.black87)),
                const SizedBox(height: 8),
                Row(children: [
                  Chip(label: Text('Skills: ${skills.length}')),
                  const SizedBox(width: 8),
                  Chip(label: Text('Total experience: $totalYears yrs')),
                ])
              ]),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Skills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (skills.isNotEmpty)
                  Wrap(spacing: 8, runSpacing: 6, children: skills.map((s) => Chip(label: Text(s))).toList())
                else
                  const Text('No skills detected'),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (experience != null && experience.isNotEmpty)
                  Column(
                    children: experience.map((e) {
                      final title = e['title'] ?? '-';
                      final company = e['company'] ?? '-';
                      final years = (() {
                        final s = e['startYear'];
                        final en = e['endYear'];
                        return '${s ?? '?'} - ${en ?? 'present'}';
                      })();
                      final desc = e['description'] ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('$title • $company'),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(years), if (desc.isNotEmpty) Text(desc)]),
                      );
                    }).toList(),
                  )
                else
                  const Text('No experience entries detected'),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Education', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (education != null && education.isNotEmpty)
                  Column(
                    children: education.map((ed) {
                      final degree = ed['degree'] ?? '-';
                      final inst = ed['institution'] ?? '-';
                      final years = '${ed['startYear'] ?? '?'} - ${ed['endYear'] ?? '?'}';
                      return ListTile(contentPadding: EdgeInsets.zero, title: Text(degree), subtitle: Text('$inst · $years'));
                    }).toList(),
                  )
                else
                  const Text('No education entries detected'),
              ]),
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}
