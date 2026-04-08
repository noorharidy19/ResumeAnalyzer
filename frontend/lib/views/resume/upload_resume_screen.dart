import 'package:flutter/material.dart';
import 'cv_analysis_screen.dart';

class UploadResumeScreen extends StatefulWidget {
  const UploadResumeScreen({super.key});

  @override
  State<UploadResumeScreen> createState() => _UploadResumeScreenState();
}

class _UploadResumeScreenState extends State<UploadResumeScreen> {
  String? _fileName;

  void _pickFile() {
    // TODO: integrate file_picker or platform file chooser
    // For now simulate selecting a file
    setState(() {
      _fileName = 'sample_resume.pdf';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the same pastel blue from the dashboard for consistency
    const primary = Color(0xFF5C6BC0);
    const bg = Color(0xFFF6F8FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Upload Resume', style: TextStyle(color: Colors.black)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.all(24),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  const SizedBox(height: 4),
                  Text('Upload a PDF resume', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary)),
                  const SizedBox(height: 8),
                  const Text('Select a PDF file to analyze with the Resume Analyzer.'),
                  const SizedBox(height: 20),

                  // Drop area / file preview
                  GestureDetector(
                    onTap: _pickFile,
                    child: DottedBox(
                      borderColor: primary,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.upload_file, size: 42, color: primary),
                          const SizedBox(height: 8),
                          Text(_fileName ?? 'Tap to choose a PDF file', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Choose file'),
                        style: ElevatedButton.styleFrom(backgroundColor: primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _fileName == null ? null : () {
                            // For now navigate to the analysis page with mock extracted data
                            final mockData = {
                              'personal': {
                                'name': 'Ahmed Ali',
                                'email': 'ahmed@example.com',
                                'phone': '+20 10 1234 5678',
                                'location': 'Cairo, Egypt'
                              },
                              'education': [
                                {
                                  'degree': 'B.Sc. Computer Science',
                                  'institution': 'Cairo University',
                                  'startYear': 2014,
                                  'endYear': 2018
                                }
                              ],
                              'experience': [
                                {
                                  'title': 'Mobile Developer',
                                  'company': 'Acme Ltd',
                                  'startYear': 2019,
                                  'endYear': 2024,
                                  'description': 'Built Flutter apps and integrations.'
                                }
                              ],
                              'skills': ['Flutter', 'Dart', 'Firebase', 'REST APIs'],
                              'summary': 'Experienced mobile developer focused on Flutter.'
                            };

                            Navigator.push(context, MaterialPageRoute(builder: (_) => CVAnalysisScreen(cvData: mockData)));
                          },
                          child: const Text('Analyze'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Simple dotted container used for the drop area UI
class DottedBox extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  const DottedBox({required this.child, this.borderColor, super.key});

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? Colors.grey.shade300;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, style: BorderStyle.solid),
      ),
      child: Center(child: child),
    );
  }
}
