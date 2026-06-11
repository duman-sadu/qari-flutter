import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _googleLoading = false;
  bool _appleLoading = false;

  Future<void> _signInWithApple() async {
    setState(() => _appleLoading = true);
    final result = await AuthService.signInWithApple();
    if (!mounted) return;
    setState(() => _appleLoading = false);
    if (result.user != null) {
      final prefs = await SharedPreferences.getInstance();
      final isOnboarded = prefs.getString('studyMode') != null;
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, isOnboarded ? '/learning' : '/onboarding');
    } else if (result.error != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sign in with Apple'),
          content: Text(result.error!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    final result = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);
    if (result.user != null) {
      Navigator.pushReplacementNamed(context, '/learning');
    } else if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = Provider.of<LanguageProvider>(context);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient top section ──────────────────────────────────────────
          Expanded(
            flex: 58,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A2418),
                    Color(0xFF1A4731),
                    Color(0xFF28694A),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    // Language toggle top-right
                    Positioned(
                      top: 8,
                      right: 16,
                      child: _LangPicker(s: s),
                    ),
                    Positioned.fill(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Bismillah badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 9),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFC9A457).withValues(alpha: 0.45),
                            ),
                          ),
                          child: const Text(
                            'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                            style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFFC9A457),
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Logo circle
                        Container(
                          width: 106,
                          height: 106,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.10),
                            border: Border.all(
                              color: const Color(0xFFC9A457).withValues(alpha: 0.55),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('📖', style: TextStyle(fontSize: 46)),
                          ),
                        ),

                        const SizedBox(height: 22),

                        const Text(
                          'Qari',
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          s.tr('appSlogan'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white54,
                            height: 1.65,
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom section ────────────────────────────────────────────────
          Expanded(
            flex: 42,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.tr('welcomeTitle'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.tr('welcomeSub'),
                        style: TextStyle(fontSize: 14, color: c.subtext),
                      ),

                      const SizedBox(height: 26),

                      // Primary button — register
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                              context, '/onboarding'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            s.tr('register'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Apple button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: SignInWithAppleButton(
                          onPressed: _appleLoading ? () {} : _signInWithApple,
                          style: SignInWithAppleButtonStyle.black,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(16)),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Google button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _googleLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.primary,
                            backgroundColor: c.card,
                            side: BorderSide(color: c.border, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _googleLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation(c.primary),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🔵',
                                        style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Text(
                                      s.tr('signInGoogle'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: c.text,
                                      ),
                                    ),
                                  ],
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
                    Icon(
                      Icons.check,
                      size: 16,
                      color: s.lang == l.$1 ? c.primary : Colors.transparent,
                    ),
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
            Text(
              current.$2,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
