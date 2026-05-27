import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/plan_provider.dart';

late QariAudioHandler audioHandler;

// ── Reciters (shared with ListenScreen) ──────────────────────────────────────

enum Cdn { quranicAudio, mp3quran }

class Reciter {
  final String name;
  final String arabic;
  final String country;
  final Cdn cdn;
  final String folder;

  const Reciter(this.name, this.arabic, this.country, this.cdn, this.folder);

  String url(int surah) {
    final p = surah.toString().padLeft(3, '0');
    if (cdn == Cdn.quranicAudio) {
      return 'https://download.quranicaudio.com/quran/$folder/$p.mp3';
    }
    final parts = folder.split('/');
    return 'https://server${parts[0]}.mp3quran.net/${parts[1]}/$p.mp3';
  }
}

const reciters = [
  Reciter('Мишари Алафаси',       'مشاري راشد العفاسي',   '🇰🇼 Кувейт',
      Cdn.quranicAudio, 'mishaari_raashid_al_3afaasee'),
  Reciter('Абдурахман ас-Судайс', 'عبد الرحمن السديس',    '🇸🇦 Сауд Арабия',
      Cdn.quranicAudio, 'abdurrahmaan_as-sudays'),
  Reciter('Мәhер аль-Муайқли',   'ماهر المعيقلي',         '🇸🇦 Сауд Арабия',
      Cdn.mp3quran, '12/maher'),
  Reciter('аль-Хусари',          'محمود خليل الحصري',     '🇪🇬 Египет',
      Cdn.quranicAudio, 'mahmood_khaleel_al-husaree'),
  Reciter('аль-Минашауи',        'محمد صديق المنشاوي',    '🇪🇬 Египет',
      Cdn.quranicAudio, 'muhammad_siddeeq_al-minshaawee'),
  Reciter('Абдулла Басфар',      'عبد الله بصفر',          '🇸🇦 Сауд Арабия',
      Cdn.quranicAudio, 'abdullaah_basfar'),
  Reciter('Сауд аш-Шурайм',     'سعود الشريم',            '🇸🇦 Сауд Арабия',
      Cdn.mp3quran, '7/shur'),
];

// ── Handler ───────────────────────────────────────────────────────────────────

class QariAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();
  final _surahController = StreamController<int>.broadcast();

  int currentSurah = 1;
  int currentReciterIdx = 0;
  double currentSpeed = 1.0;
  bool autoNext = true;

  Stream<int> get onSurahChanged => _surahController.stream;
  AudioPlayer get player => _player;

  void Function()? onSkipPrevious;
  void Function()? onSkipNext;
  void Function()? onTrackComplete;

  QariAudioHandler() {
    _player.setAudioContext(const AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.none,
      ),
    ));

    playbackState.add(PlaybackState(
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.idle,
    ));

    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: state == PlayerState.completed
            ? AudioProcessingState.completed
            : AudioProcessingState.ready,
        playing: playing,
      ));
    });

    _player.onPositionChanged.listen((pos) {
      playbackState.add(playbackState.value.copyWith(updatePosition: pos));
    });

    _player.onDurationChanged.listen((dur) {
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(current.copyWith(duration: dur));
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (onTrackComplete != null) {
        // ListenScreen is mounted — delegate so it handles repeat/auto-next/state
        onTrackComplete!();
      } else if (autoNext && currentSurah < 114) {
        currentSurah++;
        _surahController.add(currentSurah);
        playCurrentSurah();
      } else {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.idle,
          playing: false,
        ));
      }
    });
  }

  // Called by ListenScreen when user manually picks a surah
  void changeSurah(int surah) {
    currentSurah = surah;
    _surahController.add(surah);
  }

  String _currentTitle = '';

  void setMediaItem(String title, String artist) {
    _currentTitle = title;
    mediaItem.add(MediaItem(
      id: 'surah_$currentSurah',
      title: title,
      artist: artist,
      album: 'Quran',
    ));
  }

  Future<void> playUrl(String url, double speed) async {
    await _player.play(UrlSource(url));
    await _player.setPlaybackRate(speed);
  }

  void _updateMediaItem() {
    final title = _currentTitle.isNotEmpty
        ? _currentTitle
        : surahNames[currentSurah - 1].replaceAll(' сүресі', '');
    mediaItem.add(MediaItem(
      id: 'surah_$currentSurah',
      title: title,
      artist: reciters[currentReciterIdx].name,
      album: 'Quran',
    ));
  }

  Future<void> playCurrentSurah() async {
    _updateMediaItem();
    await _player.play(UrlSource(reciters[currentReciterIdx].url(currentSurah)));
    await _player.setPlaybackRate(currentSpeed);
  }

  @override
  Future<void> play() async {
    // If track ended, restart it; otherwise resume
    if (_player.state == PlayerState.completed ||
        _player.state == PlayerState.stopped) {
      await playCurrentSurah();
    } else {
      await _player.resume();
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToPrevious() async {
    if (onSkipPrevious != null) {
      onSkipPrevious!();
    } else if (currentSurah > 1) {
      currentSurah--;
      _surahController.add(currentSurah);
      await playCurrentSurah();
    }
  }

  @override
  Future<void> skipToNext() async {
    if (onSkipNext != null) {
      onSkipNext!();
    } else if (currentSurah < 114) {
      currentSurah++;
      _surahController.add(currentSurah);
      await playCurrentSurah();
    }
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }
}
