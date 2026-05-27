import 'package:flutter/material.dart';
import '../services/quran_api.dart';

class TajweedTextWidget extends StatelessWidget {
  final String html;
  final double fontSize;
  final Color? baseColor;
  const TajweedTextWidget({
    super.key,
    required this.html,
    this.fontSize = 30,
    this.baseColor,
  });

  Color _hexToColor(String hex, Color fallback) {
    if (hex == '#000000') return fallback;
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final parts = parseTajweedParts(html);
    final fallback = baseColor ?? Theme.of(context).colorScheme.onSurface;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          children: parts.map((p) => TextSpan(
            text: p['text'],
            style: TextStyle(
              color: _hexToColor(p['color']!, fallback),
              fontSize: fontSize,
              height: 1.8,
            ),
          )).toList(),
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}