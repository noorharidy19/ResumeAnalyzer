import 'package:flutter/material.dart';
import '../../services/job_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final JobService _jobService = JobService();
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _reqCtrl      = TextEditingController();

  final List<String> _requirements = [];
  String? _selectedJobType;
  bool _isSubmitting = false;

  static const primary = Color(0xFF5C6BC0);
  static const accent  = Color(0xFF3F51B5);
  static const bg      = Color(0xFFF0F7FF);

  static const _jobTypes = ['Full-time', 'Part-time', 'Remote', 'Internship', 'Contract'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _reqCtrl.dispose();
    super.dispose();
  }

  void _addRequirement() {
    final text = _reqCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _requirements.add(text);
      _reqCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one requirement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _jobService.createJob(
        title:        _titleCtrl.text.trim(),
        description:  _descCtrl.text.trim(),
        requirements: _requirements,
        location:     _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        jobType:      _selectedJobType,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job posted successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post a Job',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Card wrapper for fields ─────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _Label('Job Title *'),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: _inputStyle('e.g. Senior Flutter Developer', Icons.title),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),

                      const SizedBox(height: 16),

                      _Label('Job Description *'),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 5,
                        decoration: _inputStyle(
                          'Describe the role, responsibilities...',
                          Icons.description_outlined,
                        ).copyWith(alignLabelWithHint: true),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Please add a description'
                            : null,
                      ),

                      const SizedBox(height: 16),

                      // Location + Type row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Location'),
                                TextFormField(
                                  controller: _locationCtrl,
                                  decoration: _inputStyle('e.g. Cairo, Egypt', Icons.location_on_outlined),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Label('Job Type'),
                                DropdownButtonFormField<String>(
                                  value: _selectedJobType,
                                  hint: const Text('Select', style: TextStyle(fontSize: 13)),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.work_outline, color: primary),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  items: _jobTypes
                                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (v) => setState(() => _selectedJobType = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Requirements card ───────────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Requirements *'),
                      const Text(
                        'Add skills or qualifications one by one',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _reqCtrl,
                              decoration: _inputStyle(
                                'e.g. Python, 2+ years experience',
                                Icons.add_circle_outline,
                              ),
                              onFieldSubmitted: (_) => _addRequirement(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addRequirement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: const Text('Add',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                      if (_requirements.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _requirements.asMap().entries.map((e) => Chip(
                            label: Text(e.value,
                                style: const TextStyle(fontSize: 12, color: primary)),
                            deleteIcon: const Icon(Icons.close, size: 16, color: primary),
                            onDeleted: () =>
                                setState(() => _requirements.removeAt(e.key)),
                            backgroundColor: primary.withOpacity(0.08),
                            side: BorderSide(color: primary.withOpacity(0.2)),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post Job',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13),
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF3F51B5),
          ),
        ),
      );
}