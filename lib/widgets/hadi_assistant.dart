import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

enum HadiState { calm, happy, motivate, reminder }

String hadiMessage(HadiState state, {bool isRu = false}) {
  if (isRu) {
    switch (state) {
      case HadiState.calm:
        return 'Ассаляму алейкум! Проведём этот день с Кораном 📖';
      case HadiState.happy:
        return 'МашааАллах! Ты выполнил сегодняшнюю цель 🌟';
      case HadiState.motivate:
        return 'Твоя серия продолжается! Молодец, не останавливайся 🔥';
      case HadiState.reminder:
        return 'Ты ещё не читал сегодня. Даже один аят — хорошо 🌙';
    }
  }
  switch (state) {
    case HadiState.calm:
      return 'Ассаламу алейкум! Бүгін де Құранмен бірге болайық 📖';
    case HadiState.happy:
      return 'Машааллах! Бүгінгі мақсатыңды орындадың 🌟';
    case HadiState.motivate:
      return 'Сенің серияң жалғасуда! Жарайсың, тоқтама 🔥';
    case HadiState.reminder:
      return 'Бүгін әлі оқымадың. Бір аят болса да жетеді 🌙';
  }
}

String _hadiAsset(HadiState state) {
  switch (state) {
    case HadiState.happy:    return 'assets/hadi/happy.png';
    case HadiState.motivate: return 'assets/hadi/motivate.png';
    case HadiState.reminder: return 'assets/hadi/reminder.png';
    case HadiState.calm:     return 'assets/hadi/calm.png';
  }
}

// ── Animated avatar: breathing + floating ────────────────────────────────────

class _AnimatedHadiAvatar extends StatefulWidget {
  final HadiState state;
  const _AnimatedHadiAvatar({required this.state});

  @override
  State<_AnimatedHadiAvatar> createState() => _AnimatedHadiAvatarState();
}

class _AnimatedHadiAvatarState extends State<_AnimatedHadiAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final AnimationController _floatCtrl;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathCtrl, _floatCtrl]),
      builder: (_, child) {
        final scale = 1.0 + _breathCtrl.value * 0.04;
        final offsetY = sin(_floatCtrl.value * 2 * pi) * 3.0;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: _avatar(),
    );
  }

  Widget _avatar() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF5EBD7),
        border: Border.all(
          color: const Color(0xFFD6B98C).withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Image.asset(
            _hadiAsset(widget.state),
            key: ValueKey(widget.state),
            fit: BoxFit.cover,
            errorBuilder: (context, err, stack) => const Center(
              child: Text('🐪', style: TextStyle(fontSize: 26)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pulse wrapper (happy state) ───────────────────────────────────────────────

class _SuccessPulse extends StatefulWidget {
  final Widget child;
  const _SuccessPulse({required this.child});

  @override
  State<_SuccessPulse> createState() => _SuccessPulseState();
}

class _SuccessPulseState extends State<_SuccessPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

// ── Main card ─────────────────────────────────────────────────────────────────

class HadiAssistant extends StatelessWidget {
  final HadiState state;
  final VoidCallback? onDismiss;

  const HadiAssistant({
    super.key,
    required this.state,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final avatar = _AnimatedHadiAvatar(state: state);
    final avatarWidget = state == HadiState.happy
        ? _SuccessPulse(child: avatar)
        : avatar;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: const Color(0xFFD6B98C).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatarWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Dudi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2E7D56),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D56).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.watch<LanguageProvider>().tr('aiAssistant'),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF2E7D56),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _AnimatedMessage(state: state),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.close, size: 16, color: c.subtext),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Animated message text ─────────────────────────────────────────────────────

class _AnimatedMessage extends StatelessWidget {
  final HadiState state;
  const _AnimatedMessage({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isRu = context.watch<LanguageProvider>().isRu;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Text(
        hadiMessage(state, isRu: isRu),
        key: ValueKey(state),
        style: TextStyle(fontSize: 13, height: 1.4, color: c.text),
      ),
    );
  }
}

// ── Outer animated switcher (whole card fade+slide on state change) ───────────

class AnimatedHadiAssistant extends StatelessWidget {
  final HadiState state;
  final VoidCallback? onDismiss;

  const AnimatedHadiAssistant({
    super.key,
    required this.state,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: HadiAssistant(
        key: ValueKey(state),
        state: state,
        onDismiss: onDismiss,
      ),
    );
  }
}
