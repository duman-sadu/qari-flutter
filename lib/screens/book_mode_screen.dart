import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import '../providers/plan_provider.dart';
import '../services/quran_api.dart';

class BookModeScreen extends StatefulWidget {
  final int initialPage;
  final int? bookmarkPage;

  const BookModeScreen({
    super.key,
    required this.initialPage,
    this.bookmarkPage,
  });

  @override
  State<BookModeScreen> createState() => _BookModeScreenState();
}

class _BookModeScreenState extends State<BookModeScreen> {
  late final PageController _pageCtrl;
  late int _currentPage;
  int? _bookmarkPage;
  bool _showOverlay = true;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _bookmarkPage = widget.bookmarkPage;
    _pageCtrl = PageController(initialPage: widget.initialPage - 1);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scheduleHide();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _pageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _scheduleHide() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) _scheduleHide();
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bookmarkPage == _currentPage) {
      await prefs.remove('bookmarkPage');
      if (mounted) setState(() => _bookmarkPage = null);
    } else {
      await prefs.setInt('bookmarkPage', _currentPage);
      if (mounted) setState(() => _bookmarkPage = _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1B1510) : const Color(0xFFF9F5E8);
    final fg = isDark ? const Color(0xFFE0CFA0) : const Color(0xFF2C1A0E);
    final isMarked = _bookmarkPage == _currentPage;
    final isRu = context.watch<LanguageProvider>().isRu;

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleOverlay,
        child: Stack(
          children: [
            // ── Pages ──────────────────────────────────────────────────
            PageView.builder(
              controller: _pageCtrl,
              itemCount: 604,
              onPageChanged: (i) => setState(() => _currentPage = i + 1),
              itemBuilder: (_, i) => _BookPage(
                pageNumber: i + 1,
                bg: bg,
                fg: fg,
              ),
            ),

            // ── Overlay ────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: Column(
                  children: [
                    // Top bar
                    Container(
                      padding: EdgeInsets.fromLTRB(
                          4,
                          MediaQuery.of(context).padding.top + 4,
                          4,
                          8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.pop(context, _currentPage),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                          const Spacer(),
                          Text(
                            '$_currentPage / 604',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _toggleBookmark,
                            icon: Icon(
                              isMarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isMarked
                                  ? const Color(0xFFFFB300)
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Bottom bar
                    Container(
                      padding: EdgeInsets.fromLTRB(
                          16,
                          8,
                          16,
                          MediaQuery.of(context).padding.bottom + 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          // Previous page
                          GestureDetector(
                            onTap: () {
                              if (_currentPage > 1) {
                                _pageCtrl.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: const Icon(Icons.chevron_left,
                                color: Colors.white70, size: 28),
                          ),
                          const Spacer(),
                          Text(
                            isRu ? 'Стр. $_currentPage' : '$_currentPage-бет',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          // Next page
                          GestureDetector(
                            onTap: () {
                              if (_currentPage < 604) {
                                _pageCtrl.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            child: const Icon(Icons.chevron_right,
                                color: Colors.white70, size: 28),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Individual page widget ────────────────────────────────────────────────────

class _BookPage extends StatefulWidget {
  final int pageNumber;
  final Color bg;
  final Color fg;

  const _BookPage({
    required this.pageNumber,
    required this.bg,
    required this.fg,
  });

  @override
  State<_BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<_BookPage> {
  List<Map<String, dynamic>>? _ayahs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tid = context.read<LanguageProvider>().translationId;
    final data = await fetchVersesByPage(widget.pageNumber, tid);
    if (mounted) setState(() => _ayahs = data);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>();
    if (_ayahs == null) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.fg.withValues(alpha: 0.4),
        ),
      );
    }
    if (_ayahs!.isEmpty) {
      return Center(
        child: Text(s.tr('loadFailed'),
            style: TextStyle(color: widget.fg.withValues(alpha: 0.5))),
      );
    }

    final items = <Widget>[];
    int? lastChapter;

    for (final a in _ayahs!) {
      final ch = (a['chapter'] as int).clamp(1, 114);
      final v = a['verse'] as int;
      final arabic = a['arabic']?.toString() ?? '';

      if (ch != lastChapter) {
        lastChapter = ch;
        if (v == 1) {
          items.add(_surahHeader(ch));
        } else {
          items.add(_surahContinue(ch, v));
        }
      }

      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$arabic ',
                    style: TextStyle(
                      fontSize: 24,
                      height: 2.1,
                      color: widget.fg,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: widget.fg.withValues(alpha: 0.35),
                            width: 1),
                      ),
                      child: Center(
                        child: Text(
                          '$v',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: widget.fg.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
      );
    }

    final top = MediaQuery.of(context).padding.top + 56.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, top, 18, 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items,
      ),
    );
  }

  Widget _surahHeader(int ch) {
    final isRu = context.read<LanguageProvider>().isRu;
    final name = (isRu ? surahNamesRu : surahNames)[(ch - 1).clamp(0, 113)];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
              color: widget.fg.withValues(alpha: 0.2), width: 1),
        ),
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: widget.fg,
              letterSpacing: 0.5,
            ),
          ),
          if (ch != 9) ...[
            const SizedBox(height: 8),
            Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                height: 2.0,
                color: widget.fg.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _surahContinue(int ch, int verse) {
    final isRu = context.read<LanguageProvider>().isRu;
    final name = (isRu ? surahNamesRu : surahNames)[(ch - 1).clamp(0, 113)];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          isRu ? '· $name · с $verse аята ·' : '· $name · $verse-аяттан ·',
          style: TextStyle(
            fontSize: 11,
            color: widget.fg.withValues(alpha: 0.45),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
