import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../providers/language_provider.dart';
import '../services/audio_handler.dart';
import '../theme/app_colors.dart';
import '../data/surah_info.dart';

const _speeds = [0.75, 1.0, 1.25, 1.5];

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen>
    with SingleTickerProviderStateMixin {
  LanguageProvider get _s => context.read<LanguageProvider>();

  AudioPlayer get _player => audioHandler.player;

  int _surah = 1;
  int _reciterIdx = 0;
  bool _isPlaying = false;
  bool _loading = false;
  String? _error;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _speed = 1.0;
  bool _autoNext = true;
  bool _repeatOne = false;
  int _playGeneration = 0;

  // Sleep timer
  Timer? _sleepTimer;
  Duration _sleepRemaining = Duration.zero;
  bool _sleepEndOfSurah = false;
  bool get _sleepActive =>
      _sleepRemaining > Duration.zero || _sleepEndOfSurah;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  final List<StreamSubscription<dynamic>> _subs = [];
  double? _dragStartX;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() =>
          _reciterIdx = context.read<PlanProvider>().selectedReciterIdx);
    });

    _subs.add(_player.onPlayerStateChanged.listen((s) {
      if (!mounted) return;
      final playing = s == PlayerState.playing;
      setState(() => _isPlaying = playing);
      if (playing) {
        _pulseCtrl.repeat(reverse: true);
      } else {
        _pulseCtrl.stop();
      }
    }));

    _subs.add(_player.onPositionChanged.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    }));

    _subs.add(_player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    }));

    _subs.add(audioHandler.onSurahChanged.listen((surah) {
      if (!mounted) return;
      setState(() {
        _surah = surah;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }));

    audioHandler.onTrackComplete = () {
      if (!mounted) return;
      if (_sleepEndOfSurah) {
        setState(() {
          _sleepEndOfSurah = false;
          _isPlaying = false;
          _position = Duration.zero;
        });
        return;
      }
      if (_repeatOne) {
        _play();
      } else if (_autoNext && _surah < 114) {
        _changeSurah(_surah + 1, autoPlay: true);
      } else {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    };

    audioHandler.onSkipPrevious = () {
      if (_surah > 1) _changeSurah(_surah - 1, autoPlay: true);
    };
    audioHandler.onSkipNext = () {
      if (_surah < 114) _changeSurah(_surah + 1, autoPlay: true);
    };
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _pulseCtrl.dispose();
    audioHandler.onTrackComplete = null;
    audioHandler.onSkipPrevious = null;
    audioHandler.onSkipNext = null;
    super.dispose();
  }

  // ── Playback ──────────────────────────────────────────────────────────────

  Future<void> _play() async {
    if (!mounted) return;
    final gen = ++_playGeneration;
    try {
      // Capture all state inside try — context.read<>() can throw in release mode
      final isRu = _s.isRu;
      final surah = _surah;
      final reciterIdx = _reciterIdx;
      final speed = _speed;

      if (mounted) setState(() { _loading = true; _error = null; });
      if (gen != _playGeneration) return;

      audioHandler.setMediaItem(
        isRu ? surahNamesRu[surah - 1] : surahNames[surah - 1].replaceAll(' сүресі', ''),
        reciters[reciterIdx].name,
      );

      try { await _player.stop(); } catch (_) {}
      if (gen != _playGeneration) return;

      await audioHandler.playUrl(reciters[reciterIdx].url(surah), speed);
    } catch (_) {
      // swallow — prevents unhandled Future rejection crash in release mode
    } finally {
      if (gen == _playGeneration && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await audioHandler.pause();
      } else {
        if (_position == Duration.zero) {
          await _play();
        } else {
          try {
            await audioHandler.play();
          } catch (_) {
            await _play();
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _changeSurah(int surah, {bool autoPlay = false}) async {
    try {
      audioHandler.currentSurah = surah;
      if (mounted) {
        setState(() {
          _surah = surah;
          _position = Duration.zero;
          _duration = Duration.zero;
          _error = null;
        });
      }
      if (autoPlay) {
        await _play();
      } else {
        try { await _player.stop(); } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _changeReciter(int idx) async {
    try {
      final wasPlaying = _isPlaying;
      if (mounted) {
        setState(() {
          _reciterIdx = idx;
          _position = Duration.zero;
          _duration = Duration.zero;
          _error = null;
        });
        context.read<PlanProvider>().setReciterIdx(idx);
      }
      if (wasPlaying) {
        await _play();
      } else {
        try { await _player.stop(); } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _setSpeed(double s) async {
    setState(() => _speed = s);
    if (_isPlaying) await _player.setPlaybackRate(s);
  }

  Future<void> _seek(double seconds) async {
    await audioHandler.seek(Duration(seconds: seconds.toInt()));
  }

  Future<void> _seekRelative(int seconds) async {
    if (_duration == Duration.zero) return;
    final target = (_position.inSeconds + seconds)
        .clamp(0, _duration.inSeconds);
    await audioHandler.seek(Duration(seconds: target));
  }

  // ── Sleep timer ───────────────────────────────────────────────────────────

  void _startSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    setState(() {
      _sleepRemaining = Duration(minutes: minutes);
      _sleepEndOfSurah = false;
    });
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _sleepRemaining -= const Duration(seconds: 1));
      if (_sleepRemaining <= Duration.zero) {
        t.cancel();
        if (_isPlaying) audioHandler.pause();
      }
    });
  }

  void _setSleepEndOfSurah() {
    _sleepTimer?.cancel();
    setState(() {
      _sleepEndOfSurah = true;
      _sleepRemaining = Duration.zero;
    });
  }

  void _cancelSleep() {
    _sleepTimer?.cancel();
    setState(() {
      _sleepRemaining = Duration.zero;
      _sleepEndOfSurah = false;
    });
  }

  void _showSleepPicker() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime_rounded, color: c.green, size: 20),
                const SizedBox(width: 8),
                Text(_s.tr('sleepTimer'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.text)),
              ],
            ),
            if (_sleepActive) ...[
              const SizedBox(height: 8),
              Text(
                _sleepEndOfSurah
                    ? _s.tr('stopAtEnd')
                    : _s.sleepRemainingLabel('${_sleepRemaining.inMinutes}:${(_sleepRemaining.inSeconds % 60).toString().padLeft(2, '0')}'),
                style: TextStyle(fontSize: 13, color: c.subtext),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final min in [15, 30, 45, 60])
                  _sleepChip(c, '$min мин', () {
                    Navigator.pop(sheetCtx);
                    _startSleepTimer(min);
                  }),
                _sleepChip(c, _s.tr('stopWhenSurahEnds'), () {
                  Navigator.pop(sheetCtx);
                  _setSleepEndOfSurah();
                }),
                if (_sleepActive)
                  _sleepChip(c, _s.tr('cancel'), () {
                    Navigator.pop(sheetCtx);
                    _cancelSleep();
                  }, isCancel: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sleepChip(AppColors c, String label, VoidCallback onTap,
      {bool isCancel = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isCancel
              ? Colors.red.withValues(alpha: 0.1)
              : c.greenTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCancel
                ? Colors.red.withValues(alpha: 0.3)
                : c.green.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isCancel ? Colors.red : c.green,
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final c = AppColors.of(context);
    final meta = surahMeta[_surah - 1];
    final reciter = reciters[_reciterIdx];
    final displayName = meta.name.replaceAll(' сүресі', '');

    return Scaffold(
      backgroundColor: c.bg,
      body: GestureDetector(
        onHorizontalDragStart: (d) => _dragStartX = d.localPosition.dx,
        onHorizontalDragEnd: (details) {
          final startX = _dragStartX;
          _dragStartX = null;
          if (startX == null) return;
          final screenW = MediaQuery.of(context).size.width;
          if (startX <= 20 || startX >= screenW - 20) return;
          final v = details.primaryVelocity ?? 0;
          if (v < -600 && _surah < 114) {
            _changeSurah(_surah + 1, autoPlay: _isPlaying);
          } else if (v > 600 && _surah > 1) {
            _changeSurah(_surah - 1, autoPlay: _isPlaying);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(color: c.primary),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 14),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70, size: 28),
                      ),
                      const Spacer(),
                      Text(
                        _s.tr('listenTitle'),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                      const Spacer(),
                      // Sleep timer button
                      GestureDetector(
                        onTap: _showSleepPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _sleepActive
                                ? Colors.white.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bedtime_rounded,
                                color: _sleepActive
                                    ? Colors.yellow[200]
                                    : Colors.white70,
                                size: 16,
                              ),
                              if (_sleepRemaining > Duration.zero) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${_sleepRemaining.inMinutes}:${(_sleepRemaining.inSeconds % 60).toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                              ] else if (_sleepEndOfSurah) ...[
                                const SizedBox(width: 4),
                                const Text('1♪',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Surah picker
                      GestureDetector(
                        onTap: () => _showSurahPicker(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.list_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(_s.tr('surah'),
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 36),

                    // ── Album art (pulsing glow when playing) ─────────────
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, child) {
                        final glow = _isPlaying ? _pulseAnim.value : 0.0;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 200 + glow * 12,
                              height: 200 + glow * 12,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    c.primary,
                                    c.primary.withValues(alpha: 0.6)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: c.primary.withValues(
                                        alpha: 0.18 + glow * 0.28),
                                    blurRadius: 28 + glow * 36,
                                    spreadRadius: 4 + glow * 12,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/hadi/слушает Коран.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (_loading)
                              const SizedBox(
                                width: 48,
                                height: 48,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 26),

                    // ── Surah name + meaning ───────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        displayName,
                        key: ValueKey(_surah),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                            height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        meta.meaning,
                        key: ValueKey('${_surah}_m'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: c.subtext,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Surah info chips ───────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Chip(
                          label: meta.place,
                          icon: Icons.location_on_rounded,
                          color: meta.place == 'Мекке'
                              ? const Color(0xFF7A4F00)
                              : c.green,
                          bg: meta.place == 'Мекке'
                              ? const Color(0xFFFFF0CC)
                              : c.greenTint,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: '${meta.ayah} аят',
                          icon: Icons.format_list_numbered_rounded,
                          color: c.blue,
                          bg: c.blueTint,
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: '№${meta.number}',
                          icon: Icons.tag_rounded,
                          color: c.subtext,
                          bg: c.surfaceAlt,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Reciter ────────────────────────────────────────────
                    GestureDetector(
                      onTap: () => _showReciterPicker(c),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(reciter.name,
                              style: TextStyle(
                                  fontSize: 13, color: c.subtext)),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more,
                              size: 18, color: c.subtext),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Progress bar ───────────────────────────────────────
                    if (_duration > Duration.zero) ...[
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16),
                          activeTrackColor: c.green,
                          inactiveTrackColor: c.border,
                          thumbColor: c.green,
                          overlayColor:
                              c.green.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          min: 0,
                          max: _duration.inSeconds.toDouble(),
                          value: _position.inSeconds
                              .toDouble()
                              .clamp(0, _duration.inSeconds.toDouble()),
                          onChanged: _seek,
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(_position),
                                style: TextStyle(
                                    fontSize: 12, color: c.subtext)),
                            Text(_fmt(_duration),
                                style: TextStyle(
                                    fontSize: 12, color: c.subtext)),
                          ],
                        ),
                      ),
                      // ± 15 sec seek buttons
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SeekRelBtn(
                            icon: Icons.replay_rounded,
                            label: '15',
                            color: c.subtext,
                            onTap: () => _seekRelative(-15),
                          ),
                          const SizedBox(width: 48),
                          _SeekRelBtn(
                            icon: Icons.forward_rounded,
                            label: '15',
                            color: c.subtext,
                            onTap: () => _seekRelative(15),
                            labelFirst: true,
                          ),
                        ],
                      ),
                    ] else
                      const SizedBox(height: 36),
                    const SizedBox(height: 16),

                    // ── Controls ───────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IconToggleBtn(
                          icon: _repeatOne
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded,
                          active: _repeatOne,
                          activeColor: c.green,
                          inactiveColor: c.subtext,
                          size: 24,
                          onTap: () =>
                              setState(() => _repeatOne = !_repeatOne),
                        ),
                        const SizedBox(width: 18),
                        _ControlBtn(
                          icon: Icons.skip_previous_rounded,
                          size: 38,
                          color: _surah > 1 ? c.text : c.border,
                          onTap: _surah > 1
                              ? () => _changeSurah(_surah - 1,
                                  autoPlay: _isPlaying)
                              : null,
                        ),
                        const SizedBox(width: 18),
                        // Play / Pause
                        GestureDetector(
                          onTap: _loading ? null : _togglePlay,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: c.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: c.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(22),
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 38,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        _ControlBtn(
                          icon: Icons.skip_next_rounded,
                          size: 38,
                          color: _surah < 114 ? c.text : c.border,
                          onTap: _surah < 114
                              ? () => _changeSurah(_surah + 1,
                                  autoPlay: _isPlaying)
                              : null,
                        ),
                        const SizedBox(width: 18),
                        _IconToggleBtn(
                          icon: Icons.queue_music_rounded,
                          active: _autoNext,
                          activeColor: c.green,
                          inactiveColor: c.subtext,
                          size: 24,
                          onTap: () =>
                              setState(() => _autoNext = !_autoNext),
                        ),
                      ],
                    ),

                    // ── Error ──────────────────────────────────────────────
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded,
                                  color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Speed chips ────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _speeds.map((s) {
                        final selected = _speed == s;
                        return GestureDetector(
                          onTap: () => _setSpeed(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? c.primary : c.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected ? c.primary : c.border),
                            ),
                            child: Text(
                              '${s}x',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : c.subtext,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reciter picker ─────────────────────────────────────────────────────────

  void _showReciterPicker(AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
              child: Row(
                children: [
                  Text(_s.tr('selectReciter'),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: c.text)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: Icon(Icons.close_rounded,
                        color: c.subtext, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            ...List.generate(reciters.length, (i) {
              final r = reciters[i];
              final selected = i == _reciterIdx;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _changeReciter(i);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  color: selected
                      ? c.greenTint
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Text(r.country,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? c.green : c.text)),
                            Text(r.arabic,
                                style: TextStyle(
                                    fontSize: 12, color: c.subtext)),
                          ],
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_circle_rounded,
                            color: c.green, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Surah picker ──────────────────────────────────────────────────────────

  void _showSurahPicker(AppColors c) {
    final h = MediaQuery.of(context).size.height;
    const itemH = 54.0;
    final scrollCtrl = ScrollController(
      initialScrollOffset: ((_surah - 1) * itemH - h * 0.15)
          .clamp(0.0, double.infinity),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (_, setSheet) {
            var query = '';
            return StatefulBuilder(
              builder: (_, setQuery) {
                final isRu = _s.isRu;
                final filtered = query.isEmpty
                    ? List.generate(114, (i) => i + 1)
                    : List.generate(114, (i) => i + 1).where((n) {
                        final name = (isRu ? surahNamesRu : surahNames)[n - 1].toLowerCase();
                        final meaning = isRu
                            ? surahMetaRu[n - 1].meaning.toLowerCase()
                            : surahMeta[n - 1].meaning.toLowerCase();
                        return name.contains(query) ||
                            '$n'.contains(query) ||
                            meaning.contains(query);
                      }).toList();

                return Container(
                  height: h * 0.82,
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                        child: Row(
                          children: [
                            Text(_s.tr('selectSurah'),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: c.text)),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetCtx),
                              icon: Icon(Icons.close_rounded,
                                  color: c.subtext, size: 22),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                      // Search field
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: TextField(
                          onChanged: (v) =>
                              setQuery(() => query = v.toLowerCase()),
                          style: TextStyle(
                              fontSize: 14, color: c.text),
                          decoration: InputDecoration(
                            hintText: _s.tr('search'),
                            hintStyle: TextStyle(color: c.subtext),
                            prefixIcon: Icon(Icons.search_rounded,
                                size: 20, color: c.subtext),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: c.surfaceAlt,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      Divider(color: c.border, height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller:
                              query.isEmpty ? scrollCtrl : null,
                          itemCount: filtered.length,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemExtent:
                              query.isEmpty ? itemH : null,
                          itemBuilder: (_, i) {
                            final num = filtered[i];
                            final name = (isRu ? surahNamesRu : surahNames)[num - 1];
                            final meaning = isRu
                                ? surahMetaRu[num - 1].meaning
                                : surahMeta[num - 1].meaning;
                            final selected = num == _surah;
                            return GestureDetector(
                              onTap: () {
                                Navigator.pop(sheetCtx);
                                _changeSurah(num,
                                    autoPlay: _isPlaying);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    bottom: 4),
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? c.greenTint
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? c.green
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? c.green
                                            : c.surfaceAlt,
                                        borderRadius:
                                            BorderRadius.circular(
                                                8),
                                      ),
                                      child: Center(
                                        child: Text('$num',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w800,
                                                color: selected
                                                    ? Colors.white
                                                    : c.subtext)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: selected
                                                    ? c.green
                                                    : c.text),
                                          ),
                                          Text(
                                            meaning,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: c.subtext),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(Icons.volume_up_rounded,
                                          color: c.green, size: 18),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(scrollCtrl.dispose);
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback? onTap;
  const _ControlBtn(
      {required this.icon,
      required this.size,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: color),
    );
  }
}

class _IconToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final VoidCallback onTap;
  const _IconToggleBtn(
      {required this.icon,
      required this.active,
      required this.activeColor,
      required this.inactiveColor,
      required this.size,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon,
          size: size, color: active ? activeColor : inactiveColor),
    );
  }
}

class _SeekRelBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool labelFirst;
  const _SeekRelBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.labelFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconW = Icon(icon, size: 22, color: color);
    final labelW = Text(label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color));
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: labelFirst
              ? [labelW, const SizedBox(width: 2), iconW]
              : [iconW, const SizedBox(width: 2), labelW],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _Chip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
