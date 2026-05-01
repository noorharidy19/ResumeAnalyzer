import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/resume_analyzer_service.dart';
import 'resume_analysis_screen.dart';

class ResumeUploadScreen extends StatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  String? _fileName;
  List<int>? _fileBytes;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      print('Opening file picker...');
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      print('File picker result: $result');
      
      if (result != null) {
        print('Files selected: ${result.files.length}');
        if (result.files.isNotEmpty) {
          final file = result.files.first;
          print('File name: ${file.name}, Size: ${file.size}, Has bytes: ${file.bytes != null}');
          
          setState(() {
            _fileName = file.name;
            _fileBytes = file.bytes?.toList();
            _errorMessage = null;
            print('State updated: fileName=$_fileName');
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✓ File selected: ${file.name}')),
            );
          }
        }
      } else {
        print('File picker cancelled');
      }
    } catch (e) {
      print('Error picking file: $e');
      setState(() {
        _errorMessage = 'Error picking file: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _analyzeResume() async {
    if (_fileBytes == null || _fileName == null) {
      setState(() => _errorMessage = 'Please select a PDF file');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ResumeAnalyzerService.analyzeResume(
        _fileBytes!,
        _fileName!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResumeAnalysisScreen(analysisData: result),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis failed: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF5C6BC0);
    const bg = Color(0xFFF6F8FF);

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
          'Resume Analyzer',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(
                            Icons.description,
                            size: 48,
                            color: primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Your Resume',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select a PDF file to analyze and get job recommendations',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // File preview
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: primary,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              color: primary.withOpacity(0.05),
                            ),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.upload_file,
                                  size: 48,
                                  color: primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _fileName ?? 'No file selected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _fileName != null ? Colors.black : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _pickFile,
                                  icon: const Icon(Icons.folder_open),
                                  label: const Text('Choose PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_fileName == null || _isLoading)
                                      ? null
                                      : _analyzeResume,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.analytics),
                                  label: Text(
                                    _isLoading ? 'Analyzing...' : 'Analyze Resume',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info cards
                  _buildInfoCard(
                    'Phase 1',
                    'Resume Extraction',
                    'Extract personal info, skills, education, and experience from PDF',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Phase 2',
                    'Job Matching',
                    'Find matching jobs using AI and skill analysis',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    'Phase 3',
                    'AI Analysis',
                    'Get career advice, interview questions, and learning path',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String phase, String title, String description) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phase,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
