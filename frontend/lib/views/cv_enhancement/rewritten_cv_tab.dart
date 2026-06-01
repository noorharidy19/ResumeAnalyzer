import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RewrittenCVTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const RewrittenCVTab({super.key, required this.data});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = data['summary']    as String?              ?? '';
    final bullets = List<Map<String, dynamic>>.from(
        data['experience'] ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Professional Summary ───────────────────────────────────────
        Row(
          children: [
            const Expanded(
              child: Text(
                'Professional Summary',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon:    const Icon(Icons.copy, size: 18),
              tooltip: 'Copy summary',
              onPressed: () => _copyToClipboard(context, summary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(summary,
              style: const TextStyle(height: 1.6)),
        ),

        const SizedBox(height: 28),

        // ── Experience Bullets ─────────────────────────────────────────
        const Text(
          'Experience — Improved Bullets',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Original shown above each improvement.',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 12),

        ...bullets.map((b) => _BulletCard(
              original: b['original'] as String? ?? '',
              improved: b['improved'] as String? ?? '',
              onCopy: () => _copyToClipboard(
                  context, b['improved'] as String? ?? ''),
            )),
      ],
    );
  }
}

class _BulletCard extends StatelessWidget {
  final String       original;
  final String       improved;
  final VoidCallback onCopy;

  const _BulletCard({
    required this.original,
    required this.improved,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode use a subtle dark surface; in light mode keep the
    // familiar light-grey so the struck-through text reads naturally.
    final originalBg = isDark
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.6)
        : Colors.grey.shade100;

    final originalTextColor = isDark
        ? Theme.of(context).textTheme.bodySmall?.color
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Original (struck-through, muted) ──────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: originalBg,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.remove,
                    size:  14,
                    color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    original,
                    style: TextStyle(
                      color:      originalTextColor,
                      decoration: TextDecoration.lineThrough,
                      fontSize:   13,
                      height:     1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Improved ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_upward,
                    size:  14,
                    color: Colors.green.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(improved,
                      style: const TextStyle(fontSize: 13, height: 1.5)),
                ),
                IconButton(
                  icon:        const Icon(Icons.copy, size: 16),
                  padding:     EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip:     'Copy improved bullet',
                  onPressed:   onCopy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}