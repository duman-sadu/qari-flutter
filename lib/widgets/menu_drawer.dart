import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../screens/profile_screen.dart';
import '../screens/surah_select_screen.dart';
import '../screens/hadi_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/friends_screen.dart';
import 'support_sheet.dart';

class MenuDrawerWidget extends StatefulWidget {
  final VoidCallback onClose;
  final BuildContext parentContext;
  final bool leftHanded;
  final ValueChanged<bool> onLeftHandedToggle;
  final VoidCallback? onOpenSettings;

  const MenuDrawerWidget({
    super.key,
    required this.onClose,
    required this.parentContext,
    required this.leftHanded,
    required this.onLeftHandedToggle,
    this.onOpenSettings,
  });

  @override
  State<MenuDrawerWidget> createState() => _MenuDrawerWidgetState();
}

class _MenuDrawerWidgetState extends State<MenuDrawerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showSupport(BuildContext ctx, LanguageProvider s) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SupportSheet(isRu: s.isRu),
    );
  }

  void _navigate(Widget screen) {
    final ctx = widget.parentContext;
    widget.onClose();
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!ctx.mounted) return;
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => screen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final s = context.watch<LanguageProvider>();

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, anim) => Stack(
        children: [
          // Backdrop
          FadeTransition(
            opacity: _fadeAnim,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withValues(alpha: 0.45),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          // Drawer panel
          Positioned(
            left: widget.leftHanded ? 0 : null,
            right: widget.leftHanded ? null : 0,
            top: 0,
            bottom: 0,
            width: 300,
            child: Transform.translate(
              offset: Offset(300 * _slideAnim.value * (widget.leftHanded ? -1 : 1), 0),
              child: Material(
                elevation: 0,
                child: Container(
                  color: c.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                        decoration: BoxDecoration(color: c.primary),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Text('📖', style: TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Qari',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            _LangPicker(s: s),
                          ],
                        ),
                      ),

                      // Menu items
                      Expanded(
                        child: Container(
                          color: c.bg,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            children: [
                              _MenuItem(
                                icon: Icons.person_outline_rounded,
                                iconBg: c.greenTint,
                                iconColor: c.green,
                                title: s.tr('myProfile'),
                                subtitle: s.tr('dataResults'),
                                onTap: () => _navigate(const ProfileScreen()),
                              ),
                              const SizedBox(height: 8),
                              _MenuItem(
                                icon: Icons.tune_rounded,
                                iconBg: c.blueTint,
                                iconColor: c.blue,
                                title: s.tr('settings'),
                                subtitle: s.tr('settingsSub'),
                                onTap: () {
                                  if (widget.onOpenSettings != null) {
                                    widget.onClose();
                                    Future.delayed(
                                      const Duration(milliseconds: 260),
                                      widget.onOpenSettings!,
                                    );
                                  } else {
                                    _navigate(const SurahSelectScreen());
                                  }
                                },
                              ),
                              const SizedBox(height: 8),
                              _MenuItem(
                                icon: Icons.smart_toy_outlined,
                                iconBg: const Color(0xFFF5EBD7),
                                iconColor: const Color(0xFF2E7D56),
                                imageAsset: 'assets/hadi/happy.png',
                                title: s.tr('dudiAI'),
                                subtitle: s.tr('dudiSub'),
                                onTap: () => _navigate(const HadiScreen()),
                              ),
                              const SizedBox(height: 8),
                              _MenuItem(
                                icon: Icons.groups_outlined,
                                iconBg: c.blueTint,
                                iconColor: c.blue,
                                title: s.tr('groupsMenu'),
                                subtitle: s.tr('groupsSub'),
                                onTap: () => _navigate(const GroupsScreen()),
                              ),
                              const SizedBox(height: 8),
                              _MenuItem(
                                icon: Icons.people_outline_rounded,
                                iconBg: c.greenTint,
                                iconColor: c.green,
                                title: s.tr('friendsMenu'),
                                subtitle: s.tr('friendsSub'),
                                onTap: () => _navigate(const FriendsScreen()),
                              ),
                              const SizedBox(height: 16),
                              Divider(color: c.border, height: 1),
                              const SizedBox(height: 12),


                              // Dark mode toggle
                              _ToggleRow(
                                icon: themeProvider.isDark
                                    ? Icons.light_mode_outlined
                                    : Icons.dark_mode_outlined,
                                c: c,
                                title: themeProvider.isDark
                                    ? s.tr('lightMode')
                                    : s.tr('darkMode'),
                                subtitle: s.tr('colorScheme'),
                                value: themeProvider.isDark,
                                onChanged: (_) => themeProvider.toggle(),
                              ),
                              const SizedBox(height: 8),

                              // Left-handed toggle
                              _ToggleRow(
                                icon: widget.leftHanded
                                    ? Icons.back_hand_outlined
                                    : Icons.front_hand_outlined,
                                c: c,
                                title: widget.leftHanded
                                    ? s.tr('rightHanded')
                                    : s.tr('leftHanded'),
                                subtitle: s.tr('controlLayout'),
                                value: widget.leftHanded,
                                onChanged: widget.onLeftHandedToggle,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Support button
                      Container(
                        color: c.bg,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        child: GestureDetector(
                          onTap: () => _showSupport(context, s),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B5E3B), Color(0xFF2E7D56)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                s.tr('supportBtn'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: imageAsset != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(imageAsset!, fit: BoxFit.cover,
                          errorBuilder: (_, e, stack) =>
                              Icon(icon, color: iconColor, size: 20)),
                    )
                  : Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: c.subtext)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.subtext, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final AppColors c;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.c,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: c.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.text)),
                Text(subtitle,
                    style: TextStyle(fontSize: 11, color: c.subtext)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.primary,
          ),
        ],
      ),
    );
  }
}

class _LangPicker extends StatelessWidget {
  final LanguageProvider s;
  const _LangPicker({required this.s});

  static const _langs = [
    ('kz', 'ҚАЗ', 'Қазақша'),
    ('ru', 'РУС', 'Русский'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final current = _langs.firstWhere(
      (l) => l.$1 == s.lang,
      orElse: () => _langs.first,
    );
    return PopupMenuButton<String>(
      onSelected: s.setLanguage,
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _langs
          .map((l) => PopupMenuItem<String>(
                value: l.$1,
                child: Row(
                  children: [
                    Icon(Icons.check,
                        size: 16,
                        color: s.lang == l.$1 ? c.primary : Colors.transparent),
                    const SizedBox(width: 8),
                    Text(l.$3,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: c.text)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.$2,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

