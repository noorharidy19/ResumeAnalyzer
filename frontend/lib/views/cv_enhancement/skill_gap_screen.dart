import 'package:flutter/material.dart';

class SkillGapScreen extends StatelessWidget {
  final List<Map<String, dynamic>> skillGaps;

  const SkillGapScreen({super.key, required this.skillGaps});

  static const _importanceOrder = {'high': 0, 'medium': 1, 'low': 2};

  Color _importanceColor(String importance) {
    switch (importance) {
      case 'high':   return const Color(0xFFDC2626);
      case 'medium': return const Color(0xFFD97706);
      case 'low':    return const Color(0xFF059669);
      default:       return Colors.grey;
    }
  }

  IconData _importanceIcon(String importance) {
    switch (importance) {
      case 'high':   return Icons.priority_high_rounded;
      case 'medium': return Icons.remove_rounded;
      case 'low':    return Icons.arrow_downward_rounded;
      default:       return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...skillGaps]..sort((a, b) {
        final aOrder = _importanceOrder[a['importance']] ?? 9;
        final bOrder = _importanceOrder[b['importance']] ?? 9;
        return aOrder.compareTo(bOrder);
      });

    // Group by importance
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final gap in sorted) {
      final key = gap['importance'] as String? ?? 'low';
      groups.putIfAbsent(key, () => []).add(gap);
    }

    final sections = <Widget>[];

    for (final importance in ['high', 'medium', 'low']) {
      final items = groups[importance];
      if (items == null || items.isEmpty) continue;

      final color = _importanceColor(importance);
      final label =
          '${importance[0].toUpperCase()}${importance.substring(1)} Priority';

      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(_importanceIcon(importance), size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize:   14,
                  fontWeight: FontWeight.w700,
                  color:      color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Divider(color: color.withValues(alpha: 0.3))),
            ],
          ),
        ),
      );

      for (final gap in items) {
        sections.add(_SkillGapCard(gap: gap, color: color));
      }

      sections.add(const SizedBox(height: 16));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary chips ────────────────────────────────────────────
        Wrap(
          spacing: 8,
          children: [
            _countChip(context,
                label: 'High',
                count: groups['high']?.length ?? 0,
                color: _importanceColor('high')),
            _countChip(context,
                label: 'Medium',
                count: groups['medium']?.length ?? 0,
                color: _importanceColor('medium')),
            _countChip(context,
                label: 'Low',
                count: groups['low']?.length ?? 0,
                color: _importanceColor('low')),
          ],
        ),
        const SizedBox(height: 20),
        ...sections,
      ],
    );
  }

  Widget _countChip(BuildContext context, {
    required String label,
    required int    count,
    required Color  color,
  }) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(
          '$count',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
      label:           Text(label),
      backgroundColor: color.withValues(alpha: 0.08),
      side:            BorderSide(color: color.withValues(alpha: 0.3)),
      labelStyle:      TextStyle(color: color, fontSize: 12),
    );
  }
}

class _SkillGapCard extends StatelessWidget {
  final Map<String, dynamic> gap;
  final Color                color;

  const _SkillGapCard({required this.gap, required this.color});

  @override
  Widget build(BuildContext context) {
    // Use theme colors instead of hardcoded grey shades
    final hintColor = Theme.of(context).textTheme.bodySmall?.color;
    final bodyColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left:   BorderSide(color: color, width: 4),
          top:    BorderSide(color: Theme.of(context).dividerColor),
          right:  BorderSide(color: Theme.of(context).dividerColor),
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gap['skill'] as String? ?? '',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: hintColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  gap['how_to_acquire'] as String? ?? '',
                  style: TextStyle(
                      fontSize: 13, color: bodyColor, height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}