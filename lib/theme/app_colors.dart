import 'package:flutter/material.dart';

/// Central color tokens for light and dark modes.
/// Access via [AppColors.of(context)] anywhere in the tree.
class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color primary;
  final Color green;
  final Color card;
  final Color border;
  final Color text;
  final Color subtext;
  final Color blue;
  final Color blueTint;
  final Color greenTint;
  final Color surfaceAlt;
  final Color meccaBg;
  final Color meccaFg;
  final Color gold;
  final Color goldTint;

  const AppColors({
    required this.bg,
    required this.primary,
    required this.green,
    required this.card,
    required this.border,
    required this.text,
    required this.subtext,
    required this.blue,
    required this.blueTint,
    required this.greenTint,
    required this.surfaceAlt,
    required this.meccaBg,
    required this.meccaFg,
    required this.gold,
    required this.goldTint,
  });

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  static const light = AppColors(
    bg:         Color(0xFFF7F4EE),
    primary:    Color(0xFF1A4731),
    green:      Color(0xFF2D7A55),
    card:       Colors.white,
    border:     Color(0xFFE8E2D8),
    text:       Color(0xFF1C1C1E),
    subtext:    Color(0xFF8E8E93),
    blue:       Color(0xFF1565C0),
    blueTint:   Color(0xFFE8F0FD),
    greenTint:  Color(0xFFEFF7F2),
    surfaceAlt: Color(0xFFF0EDE6),
    meccaBg:    Color(0xFFFFF3E0),
    meccaFg:    Color(0xFF7B3F00),
    gold:       Color(0xFFC9A457),
    goldTint:   Color(0xFFFFF8E8),
  );

  static const dark = AppColors(
    bg:         Color(0xFF111A14),
    primary:    Color(0xFF1A4731),
    green:      Color(0xFF50C080),
    card:       Color(0xFF1D2D23),
    border:     Color(0xFF2D4035),
    text:       Color(0xFFF2F2F2),
    subtext:    Color(0xFF98989D),
    blue:       Color(0xFF68AEE8),
    blueTint:   Color(0xFF0F2036),
    greenTint:  Color(0xFF162C1E),
    surfaceAlt: Color(0xFF1A2820),
    meccaBg:    Color(0xFF2A1E0C),
    meccaFg:    Color(0xFFD49050),
    gold:       Color(0xFFC9A457),
    goldTint:   Color(0xFF252010),
  );

  @override
  AppColors copyWith({
    Color? bg, Color? primary, Color? green, Color? card, Color? border,
    Color? text, Color? subtext, Color? blue, Color? blueTint,
    Color? greenTint, Color? surfaceAlt, Color? meccaBg, Color? meccaFg,
    Color? gold, Color? goldTint,
  }) => AppColors(
    bg:         bg         ?? this.bg,
    primary:    primary    ?? this.primary,
    green:      green      ?? this.green,
    card:       card       ?? this.card,
    border:     border     ?? this.border,
    text:       text       ?? this.text,
    subtext:    subtext    ?? this.subtext,
    blue:       blue       ?? this.blue,
    blueTint:   blueTint   ?? this.blueTint,
    greenTint:  greenTint  ?? this.greenTint,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    meccaBg:    meccaBg    ?? this.meccaBg,
    meccaFg:    meccaFg    ?? this.meccaFg,
    gold:       gold       ?? this.gold,
    goldTint:   goldTint   ?? this.goldTint,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg:         Color.lerp(bg,         other.bg,         t)!,
      primary:    Color.lerp(primary,    other.primary,    t)!,
      green:      Color.lerp(green,      other.green,      t)!,
      card:       Color.lerp(card,       other.card,       t)!,
      border:     Color.lerp(border,     other.border,     t)!,
      text:       Color.lerp(text,       other.text,       t)!,
      subtext:    Color.lerp(subtext,    other.subtext,    t)!,
      blue:       Color.lerp(blue,       other.blue,       t)!,
      blueTint:   Color.lerp(blueTint,   other.blueTint,   t)!,
      greenTint:  Color.lerp(greenTint,  other.greenTint,  t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      meccaBg:    Color.lerp(meccaBg,    other.meccaBg,    t)!,
      meccaFg:    Color.lerp(meccaFg,    other.meccaFg,    t)!,
      gold:       Color.lerp(gold,       other.gold,       t)!,
      goldTint:   Color.lerp(goldTint,   other.goldTint,   t)!,
    );
  }
}
