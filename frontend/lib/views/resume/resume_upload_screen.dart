import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/resume_analyzer_service.dart';
import 'resume_analysis_screen.dart';
import '../../utils/responsive_helper.dart';

class ResumeUploadScreen extends StatefulWidget {
  const ResumeUploadScreen({super.key});

  @override
  State<ResumeUploadScreen> createState() => _ResumeUploadScreenState();
}

class _ResumeUploadScreenState extends State<ResumeUploadScreen> {
  // FIX: analyzeResume is an instance method, not static — create an instance
  final _service = ResumeAnalyzerService();

  String?    _fileName;     // name of the selected file
  List<int>? _fileBytes;    // bytes of the selected file (to send to backend in bytes)
  bool       _isLoading    = false;
  String?    _errorMessage;

  Future<void> _pickFile() async {
    try {
      print('Opening file picker...');
      FilePickerResult? result = await FilePicker.pickFiles(
        type:             FileType.custom,
        allowedExtensions: ['pdf'],
        withData:         true, // convert to bytes directly
      );

      print('File picker result: $result');

      if (result != null) {
        print('Files selected: ${result.files.length}');
        if (result.files.isNotEmpty) {
          final file = result.files.first;
          print(
              'File name: ${file.name}, Size: ${file.size}, Has bytes: ${file.bytes != null}');

          setState(() {
            _fileName     = file.name;
            _fileBytes    = file.bytes?.toList();
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
          SnackBar(
              content:         Text('Error: $e'),
              backgroundColor: Colors.red),
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
      _isLoading    = true;
      _errorMessage = null;
    });

    try { //send file bytes to backend and get analysis result
      final result = await ResumeAnalyzerService.analyzeResume(
        _fileBytes!,
        _fileName!,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            // second screen to show analysis result
            builder: (context) =>
                ResumeAnalysisScreen(analysisData: result),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Analysis failed: $e';
        _isLoading    = false;
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

    final isMobile    = ResponsiveHelper.isMobile(context);
    final padding     = ResponsiveHelper.getResponsivePadding(context);
    final cardPadding = isMobile ? 16.0 : 24.0;
    final fontSize    = ResponsiveHelper.getResponsiveFontSize(
      context,
      mobileSize:  16,
      tabletSize:  18,
      desktopSize: 20,
    );

    final hintColor      = Theme.of(context).textTheme.bodySmall?.color;
    final isDark         = Theme.of(context).brightness == Brightness.dark;
    // File name text: black on light, body text color on dark
    final fileNameColor  = _fileName != null
        ? (isDark
            ? Theme.of(context).textTheme.bodyMedium?.color
            : Colors.black)
        : hintColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation:       0,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Resume Analyzer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: isMobile ? 500 : 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Upload card ──────────────────────────────────────
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.description,
                            size:  isMobile ? 36 : 48,
                            color: primary),
                        const SizedBox(height: 16),
                        Text(
                          'Upload Your Resume',
                          style: TextStyle(
                              fontSize:   fontSize,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a PDF file to analyze and get job recommendations',
                          style: TextStyle(color: hintColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // ── Drop zone ──────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: primary,
                                width: 2,
                                style: BorderStyle.solid),
                            borderRadius: BorderRadius.circular(12),
                            color: primary.withValues(alpha: 0.05),
                          ),
                          padding: EdgeInsets.all(isMobile ? 20 : 32),
                          child: Column(
                            children: [
                              Icon(Icons.upload_file,
                                  size:  isMobile ? 36 : 48,
                                  color: primary),
                              const SizedBox(height: 12),
                              Text(
                                _fileName ?? 'No file selected',
                                style: TextStyle(
                                  fontSize:   isMobile ? 12 : 14,
                                  color:      fileNameColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Buttons ────────────────────────────────
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _pickFile,
                                icon:  const Icon(Icons.folder_open),
                                label: const Text('Choose PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: (_fileName == null || _isLoading)
                                    ? null
                                    : _analyzeResume,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width:  20,
                                        height: 20,
                                        child:  CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.analytics),
                                label: Text(_isLoading
                                    ? 'Analyzing...'
                                    : 'Analyze Resume'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isLoading ? null : _pickFile,
                                  icon:  const Icon(Icons.folder_open),
                                  label: const Text('Choose PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (_fileName == null || _isLoading)
                                          ? null
                                          : _analyzeResume,
                                  icon: _isLoading
                                      ? const SizedBox(
                                          width:  20,
                                          height: 20,
                                          child:  CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.analytics),
                                  label: Text(_isLoading
                                      ? 'Analyzing...'
                                      : 'Analyze Resume'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
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

                // ── Info cards ───────────────────────────────────────
                _buildInfoCard(
                  'Phase 1',
                  'Resume Extraction',
                  'Extract personal info, skills, education, and experience from PDF',
                  hintColor,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  'Phase 2',
                  'Job Matching',
                  'Find matching jobs using AI and skill analysis',
                  hintColor,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  'Phase 3',
                  'AI Analysis',
                  'Get career advice, interview questions, and learning path',
                  hintColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String phase,
    String title,
    String description,
    Color? hintColor,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(phase,
                style: TextStyle(
                    fontSize:   12,
                    color:      hintColor,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(description,
                style: TextStyle(fontSize: 13, color: hintColor)),
          ],
        ),
      ),
    );
  }
}