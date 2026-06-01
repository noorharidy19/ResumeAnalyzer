import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> certificates;

  const CertificatesScreen({super.key, required this.certificates});

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $url')),
        );
      }
    }
  }

  Color _priorityColor(int priority) {
    if (priority == 1) return const Color(0xFFDC2626); // Red — top pick
    if (priority == 2) return const Color(0xFFD97706); // Amber — strong
    return const Color(0xFF6B7280);                    // Gray — good to have
  }

  String _priorityLabel(int priority) {
    if (priority == 1) return 'Top Pick';
    if (priority == 2) return 'Recommended';
    return 'Good to Have';
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...certificates]
      ..sort((a, b) =>
          (a['priority'] as int).compareTo(b['priority'] as int));

    // Resolved once per build — avoids calling Theme inside a loop
    final hintColor  = Theme.of(context).textTheme.bodySmall?.color;
    final bodyColor  = Theme.of(context).textTheme.bodyMedium?.color;
    final cardColor  = Theme.of(context).colorScheme.surface;
    final dividerClr = Theme.of(context).dividerColor;

    return ListView.builder(
      padding:   const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final cert     = sorted[i];
        final priority = cert['priority'] as int? ?? i + 1;
        final color    = _priorityColor(priority);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color:        cardColor,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: dividerClr),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Priority badge bar ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _priorityLabel(priority),
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cert['provider'] as String? ?? '',
                        style: TextStyle(fontSize: 12, color: hintColor),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['name'] as String? ?? '',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cert['why'] as String? ?? '',
                      style: TextStyle(
                          fontSize: 13, color: bodyColor, height: 1.5),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}