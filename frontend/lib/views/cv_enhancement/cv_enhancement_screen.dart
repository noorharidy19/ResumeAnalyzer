import 'package:flutter/material.dart';
import '../../services/cv_enhancement_service.dart';
import 'certificates_screen.dart';
import 'rewritten_cv_tab.dart';

class CVEnhancementScreen extends StatefulWidget {
  final String analysisId;
  final String? targetJob;

  const CVEnhancementScreen({
    super.key,
    required this.analysisId,
    this.targetJob,
  });

  @override
  State<CVEnhancementScreen> createState() => _CVEnhancementScreenState();
}

class _CVEnhancementScreenState extends State<CVEnhancementScreen>
    with SingleTickerProviderStateMixin {
  final _service = CVEnhancementService();

  late TabController _tabController;
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _downloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // First check if already done
      var result = await _service.getEnhancement(
        widget.analysisId.toString(),
      );
      if (result == null) {
        // Trigger and poll
        await _service.enhanceResume(
          widget.analysisId.toString(),
          targetJob: widget.targetJob,
        );
        result = await _service.pollEnhancement(
          widget.analysisId.toString(),
        );
      }

      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _downloadPDF() async {
    setState(() => _downloading = true);
    try {
      final file = await _service.downloadPDF(
        widget.analysisId.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to ${file.path}'),
          backgroundColor: Colors.green.shade700,
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV Enhancement'),
        actions: [
          if (!_loading && _data != null)
            _downloading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    tooltip: 'Download PDF',
                    onPressed: _downloadPDF,
                  ),
        ],
        bottom: _loading || _error != null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Rewritten CV'),
                  Tab(text: 'Certificates'),
                ],
              ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
  if (_loading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Enhancing your CV with AI…\nThis may take up to 30 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  if (_error != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Handle both flat and nested { phase4: {...} } structures
  final phase4 = (_data!['phase4'] as Map<String, dynamic>?) ?? _data!;

  final rewrittenSections = phase4['rewritten_sections'] as Map<String, dynamic>?;
  final certificates     = phase4['certificates']        as List<dynamic>?;

  if (rewrittenSections == null || certificates == null) {
    return const Center(child: Text('Enhancement data is incomplete. Please retry.'));
  }

  return TabBarView(
    controller: _tabController,
    children: [
      RewrittenCVTab(data: rewrittenSections),
      CertificatesScreen(
        certificates: certificates
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      ),
    ],
  );
}
    }