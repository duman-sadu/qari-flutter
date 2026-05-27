import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

class GroupInfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const GroupInfoChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class JuzLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const JuzLegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class GroupProgressPill extends StatelessWidget {
  final int assigned;
  final bool complete;
  const GroupProgressPill(
      {super.key, required this.assigned, required this.complete});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = context.watch<LanguageProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: complete ? c.greenTint : c.blueTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline
                : Icons.people_outline_rounded,
            size: 11,
            color: complete ? c.green : c.blue,
          ),
          const SizedBox(width: 4),
          Text(
            complete ? s.tr('fullGroup') : s.juzProgress(assigned),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: complete ? c.green : c.blue,
            ),
          ),
        ],
      ),
    );
  }
}
