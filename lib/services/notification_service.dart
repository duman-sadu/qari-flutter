import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../providers/plan_provider.dart'
    show surahNames, surahNamesRu, surahNamesEn;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'dudi_reminders_v2';
  static const _channelName = 'Dudi еске салулар';

  static const _eveningId = 0;
  static const _morningId = 1;
  static const _fridayId  = 2;
  static const _supportId = 3;
  static const _supportPayload = 'support';
  // Active memorization (белсенді) — 3 daily ayah reminders. iOS substitute for
  // the Android lock-screen overlay, which iOS forbids.
  static const _belsendiIds = [10, 11, 12];
  static const _belsendiHours = [9, 14, 20];
  static const _belsendiPayload = 'belsendi';
  // Ramadan хатм — one reminder per Ramadan day to read the day's juz.
  // Uses ID block 20..49 (30 days).
  static const _ramadanBaseId = 20;
  static const _ramadanPayload = 'ramadan';
  static const _mainChannel =
      MethodChannel('com.example.qari_flutter/overlay');

  /// Invoked when the user taps the weekly support reminder. Set from main.
  static void Function()? onSupportTap;
  /// Invoked when the user taps a белсенді ayah reminder. Set from main.
  static void Function()? onBelsendiTap;
  /// Invoked when the user taps a Ramadan хатм reminder. Set from main.
  static void Function()? onRamadanTap;
  // Captured when the app is cold-started by tapping the support reminder,
  // then fired by [flushPendingSupportTap] once the UI is ready.
  static bool _pendingSupportTap = false;
  // Same, for белсенді reminders.
  static bool _pendingBelsendiTap = false;
  // Same, for Ramadan reminders.
  static bool _pendingRamadanTap = false;

  static Uint8List? _dudiBytes;

  /// Picks the message variant for [lang] ('kz' default).
  static String _pick(String lang, String kz, String ru, String en) {
    switch (lang) {
      case 'ru': return ru;
      case 'en': return en;
      default:   return kz;
    }
  }

  static List<String> _surahNamesFor(String lang) {
    switch (lang) {
      case 'ru': return surahNamesRu;
      case 'en': return surahNamesEn;
      default:   return surahNames;
    }
  }

  static Future<NotificationDetails> _details() async {
    _dudiBytes ??= await _loadAssetBytes('assets/hadi/reminder.png');
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Dudi Құран оқуға шақырады',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: _dudiBytes != null
          ? ByteArrayAndroidBitmap(_dudiBytes!)
          : null,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: ios);
  }

  static Future<Uint8List?> _loadAssetBytes(String asset) async {
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 128,
        targetHeight: 128,
      );
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Almaty'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (_) {}
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onResponse,
    );

    // Cold start: app was launched by tapping the support reminder.
    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        final payload = launch?.notificationResponse?.payload;
        if (payload == _supportPayload) _pendingSupportTap = true;
        if (payload == _belsendiPayload) _pendingBelsendiTap = true;
        if (payload == _ramadanPayload) _pendingRamadanTap = true;
      }
    } catch (_) {}

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Dudi Құран оқуға шақырады',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static void _onResponse(NotificationResponse r) {
    if (r.payload == _supportPayload) onSupportTap?.call();
    if (r.payload == _belsendiPayload) onBelsendiTap?.call();
    if (r.payload == _ramadanPayload) onRamadanTap?.call();
  }

  /// Fires a support tap captured during cold start, once the UI is ready.
  static void flushPendingSupportTap() {
    if (_pendingSupportTap) {
      _pendingSupportTap = false;
      onSupportTap?.call();
    }
  }

  /// Fires a белсенді tap captured during cold start, once the UI is ready.
  static void flushPendingBelsendiTap() {
    if (_pendingBelsendiTap) {
      _pendingBelsendiTap = false;
      onBelsendiTap?.call();
    }
  }

  /// Schedules 3 daily reminders (09:00, 14:00, 20:00) showing the user's
  /// current ayah. Tapping opens the learning screen. Used by белсенді mode.
  static Future<void> scheduleActiveMemorization({
    required int chapter,
    required int verse,
    String lang = 'kz',
  }) async {
    await cancelActiveMemorization();
    final name = _surahNamesFor(lang)[chapter - 1];
    final label = _pick(lang,
        '$name, $verse-аят', '$name, аят $verse', '$name, ayah $verse');
    final now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < _belsendiIds.length; i++) {
      var at = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, _belsendiHours[i], 0);
      if (at.isBefore(now)) at = at.add(const Duration(days: 1));
      await _schedule(
        id: _belsendiIds[i],
        title: _pick(lang,
            'Жаттау уақыты 📖', 'Время заучивания 📖', 'Time to memorize 📖'),
        body: _pick(lang,
            'Кезекті аятың: $label. Қазір қайтала 🤲',
            'Твой текущий аят: $label. Повтори его сейчас 🤲',
            'Your current ayah: $label. Review it now 🤲'),
        at: at,
        repeat: DateTimeComponents.time,
        payload: _belsendiPayload,
      );
    }
  }

  static Future<void> cancelActiveMemorization() async {
    for (final id in _belsendiIds) {
      await _plugin.cancel(id);
    }
  }

  /// Fires a Ramadan tap captured during cold start, once the UI is ready.
  static void flushPendingRamadanTap() {
    if (_pendingRamadanTap) {
      _pendingRamadanTap = false;
      onRamadanTap?.call();
    }
  }

  /// Schedules one reminder per Ramadan day at [notifHour] telling the user to
  /// read that day's juz. Past days are skipped. Tapping opens the app.
  static Future<void> scheduleRamadan({
    required DateTime start,
    required int days,
    required int notifHour,
    String lang = 'kz',
  }) async {
    await cancelRamadan();
    final now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < days && i < 30; i++) {
      final day = start.add(Duration(days: i));
      final at = tz.TZDateTime(
          tz.local, day.year, day.month, day.day, notifHour, 0);
      if (at.isBefore(now)) continue;
      await _schedule(
        id: _ramadanBaseId + i,
        title: _pick(lang,
            'Рамазан хатым 🌙', 'Рамадан хатм 🌙', 'Ramadan Khatam 🌙'),
        body: _pick(lang,
            '${i + 1}-күн: бүгінгі жүзді оқы 📖',
            'День ${i + 1}: прочитай сегодняшний джуз 📖',
            'Day ${i + 1}: read today\'s juz 📖'),
        at: at,
        payload: _ramadanPayload,
      );
    }
  }

  static Future<void> cancelRamadan() async {
    for (int i = 0; i < 30; i++) {
      await _plugin.cancel(_ramadanBaseId + i);
    }
  }

  /// Shows a notification immediately (no AlarmManager needed).
  static Future<void> showNow({required String title, required String body}) async {
    await _plugin.show(997, title, body, await _details());
  }

  /// Schedules a test notification 1 minute from now via AlarmManager.
  /// If it arrives → AlarmManager works. If not → OEM kills it.
  static Future<String> scheduleTestIn1Min({String lang = 'kz'}) async {
    final now = tz.TZDateTime.now(tz.local);
    final at = now.add(const Duration(minutes: 1));
    final details = await _details();
    final hhmm = '${at.hour}:${at.minute.toString().padLeft(2, '0')}';
    try {
      await _plugin.zonedSchedule(
        998,
        'Dudi',
        _pick(lang,
            'AlarmManager жұмыс істейді! ✅',
            'AlarmManager работает! ✅',
            'AlarmManager works! ✅'),
        at,
        details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return _pick(lang,
          'Тест $hhmm-де жоспарланды — күт',
          'Тест запланирован на $hhmm — жди уведомление',
          'Test scheduled for $hhmm — wait for it');
    } catch (e) {
      // alarmClock failed (no SCHEDULE_EXACT_ALARM) — try inexact
      try {
        await _plugin.zonedSchedule(
          998,
          'Dudi',
          'Inexact AlarmManager ✅',
          at,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        return _pick(lang,
            'Тест (inexact) $hhmm-де',
            'Тест (inexact) на $hhmm',
            'Test (inexact) at $hhmm');
      } catch (e2) {
        return _pick(lang, 'Қате: $e2', 'Ошибка: $e2', 'Error: $e2');
      }
    }
  }

  static Future<void> requestBatteryOptimization() async {
    try {
      await _mainChannel.invokeMethod('requestBatteryOptimization');
    } catch (_) {}
  }

  /// Returns true if exact alarms are permitted (Android 12+).
  static Future<bool> canScheduleExact() async {
    try {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await impl?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens system "Alarms & reminders" settings so user can grant permission.
  static Future<void> requestExactAlarmPermission() async {
    try {
      final impl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await impl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  // Tries alarmClock (exact, works in Doze) — if permission denied falls back
  // to inexactAllowWhileIdle which needs no special permission.
  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    DateTimeComponents? repeat,
    String? payload,
  }) async {
    final details = await _details();
    try {
      await _plugin.zonedSchedule(
        id, title, body, at, details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeat,
        payload: payload,
      );
      return;
    } catch (_) {}
    try {
      await _plugin.zonedSchedule(
        id, title, body, at, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeat,
        payload: payload,
      );
    } catch (_) {}
  }

  /// Daily evening reminder at 20:00.
  static Future<void> scheduleReminder(int daysSince,
      {String lang = 'kz'}) async {
    await _plugin.cancel(_eveningId);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0);
    if (daysSince == 0 || at.isBefore(now)) {
      at = at.add(const Duration(days: 1));
    }
    await _schedule(
      id: _eveningId,
      title: 'Dudi',
      body: _eveningMessage(daysSince, lang: lang),
      at: at,
      repeat: DateTimeComponents.time,
    );
  }

  /// Daily morning motivational reminder at 08:00.
  static Future<void> scheduleMorningReminder(int daysSince,
      {String lang = 'kz'}) async {
    await _plugin.cancel(_morningId);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);
    if (at.isBefore(now)) at = at.add(const Duration(days: 1));
    await _schedule(
      id: _morningId,
      title: 'Dudi',
      body: _morningMessage(daysSince, lang: lang),
      at: at,
      repeat: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    await _plugin.cancel(_eveningId);
    await _plugin.cancel(_morningId);
  }

  /// Weekly Friday greeting at 09:00 — congratulates with Juma and advises Surah Al-Kahf.
  static Future<void> scheduleFridayReminder({String lang = 'kz'}) async {
    await _plugin.cancel(_fridayId);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    while (at.weekday != DateTime.friday) {
      at = at.add(const Duration(days: 1));
    }
    if (at.isBefore(now)) at = at.add(const Duration(days: 7));
    await _schedule(
      id: _fridayId,
      title: 'Dudi — Жұма мүбәрак! 🌙',
      body: _pick(lang,
          'Жұма мүбәрак! Бүгін әл-Кәһф сүресін оқуды ұмытпа — ол Дажжалдан қорғайды 📖',
          'Джума мубарак! Не забудь прочитать суру аль-Кахф сегодня — она защищает от Даджжала 📖',
          'Jumu\'ah Mubarak! Don\'t forget to read Surah Al-Kahf today — it protects from the Dajjal 📖'),
      at: at,
      repeat: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Weekly support reminder on Wednesdays at 19:00 for users who haven't donated.
  static Future<void> scheduleSupportReminder({String lang = 'kz'}) async {
    await _plugin.cancel(_supportId);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0);
    while (at.weekday != DateTime.wednesday) {
      at = at.add(const Duration(days: 1));
    }
    if (at.isBefore(now)) at = at.add(const Duration(days: 7));
    await _schedule(
      id: _supportId,
      title: 'Dudi 🤲',
      body: _supportMessage(lang),
      at: at,
      repeat: DateTimeComponents.dayOfWeekAndTime,
      payload: _supportPayload,
    );
  }

  static Future<void> cancelSupportReminder() async {
    await _plugin.cancel(_supportId);
  }

  static String _supportMessage(String lang) {
    final List<String> msgs;
    switch (lang) {
      case 'ru':
        msgs = [
          'Qari живёт благодаря вам. Поддержи проект — это садака для уммы! 🤲',
          'Приложение бесплатное, но развивается с вашей помощью. Поддержи Qari 💚',
          'Каждый аят, прочитанный через Qari — и вы часть этого. Поддержи нас 🤲',
        ];
        break;
      case 'en':
        msgs = [
          'Qari lives thanks to you. Support the project — it\'s sadaqah for the ummah! 🤲',
          'The app is free, but it grows with your help. Support Qari 💚',
          'Every ayah read through Qari — you are part of it. Support us 🤲',
        ];
        break;
      default:
        msgs = [
          'Qari сіздің арқаңызда өседі. Жобаны қолда — бұл үммет үшін садақа! 🤲',
          'Қолданба тегін, бірақ сіздің қолдауыңызбен дамиды. Qari-ды қолда 💚',
          'Qari арқылы оқыған әр аят — сіз де оның бір бөлігісіз. Бізді қолда 🤲',
        ];
    }
    return msgs[DateTime.now().day % msgs.length];
  }

  /// Schedules one notification per remaining day up to [deadline].
  /// IDs: [baseId]..[baseId + daysLeft - 1] (each goal has a 400-slot block).
  static Future<void> scheduleGoalNotifications({
    required int baseId,
    required String title,
    required int hour,
    required int minute,
    required String deadline,
    required bool isLearn,
    String lang = 'kz',
  }) async {
    await cancelGoalNotifications(baseId);

    if (deadline.isEmpty) return;

    DateTime deadlineDate;
    try {
      deadlineDate = DateTime.parse(deadline);
    } catch (_) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay =
        DateTime(deadlineDate.year, deadlineDate.month, deadlineDate.day);
    final totalDays = deadlineDay.difference(today).inDays;

    if (totalDays <= 0) return;

    for (int i = 0; i < totalDays && i < 400; i++) {
      final targetDay = today.add(Duration(days: i));
      final at = tz.TZDateTime(
          tz.local, targetDay.year, targetDay.month, targetDay.day,
          hour, minute);
      if (at.isBefore(now)) continue;

      try {
        await _schedule(
          id: baseId + i,
          title: title,
          body: _goalBody(
              daysLeft: totalDays - i, isLearn: isLearn, lang: lang),
          at: at,
        );
      } catch (_) {}
    }
  }

  /// Cancels all pending notifications belonging to this goal's ID block.
  static Future<void> cancelGoalNotifications(int baseId) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final n in pending) {
        if (n.id >= baseId && n.id < baseId + 400) {
          try {
            await _plugin.cancel(n.id);
          } catch (_) {}
        }
      }
    } catch (_) {
      // pendingNotificationRequests unavailable — cancel by direct range
      for (int i = 0; i < 60; i++) {
        try {
          await _plugin.cancel(baseId + i);
        } catch (_) {}
      }
    }
  }

  // ── Message builders ──────────────────────────────────────────────────────

  static String _goalBody({
    required int daysLeft,
    required bool isLearn,
    required String lang,
  }) {
    final d = daysLeft;
    if (lang == 'ru') {
      final String daysStr;
      if (d % 10 == 1 && d % 100 != 11) {
        daysStr = 'Остался $d день';
      } else if (d % 10 >= 2 && d % 10 <= 4 && (d % 100 < 10 || d % 100 >= 20)) {
        daysStr = 'Осталось $d дня';
      } else {
        daysStr = 'Осталось $d дней';
      }
      if (d == 1) {
        return isLearn
            ? 'Последний день! Dudi верит в тебя — заверши суру 💪📘'
            : 'Последний день цели! Прочитай сегодня — ты почти у финиша 🏁📖';
      }
      if (d <= 3) {
        return isLearn
            ? '$daysStr. Финишная прямая — не останавливайся! 🔥📘'
            : '$daysStr до конца цели. Dudi рядом — читай! 🐪📖';
      }
      if (d <= 7) {
        final msgs = isLearn ? [
          '$daysStr — повторяй по частям каждый день 📘',
          '$daysStr — Dudi напоминает: заучивание требует постоянства 🤲',
          '$daysStr — разбей суру на части и учи по одной 📘',
        ] : [
          '$daysStr — читай хотя бы страницу в день 📖',
          '$daysStr — Dudi рядом на твоём пути 🐪',
          '$daysStr — постоянство важнее количества 🌿',
        ];
        return msgs[d % msgs.length];
      }
      if (d <= 14) {
        return isLearn
            ? '$daysStr. Учи по 3–5 аятов в день — и успеешь! 📘'
            : '$daysStr. Читай по странице утром и вечером 📖';
      }
      return isLearn
          ? '$daysStr до завершения цели. Dudi с тобой на каждом шагу 🐪📘'
          : '$daysStr. Начни сейчас — маленький шаг ведёт к великой цели 📖';
    }

    if (lang == 'en') {
      final daysStr = d == 1 ? '1 day left' : '$d days left';
      if (d == 1) {
        return isLearn
            ? 'Last day! Dudi believes in you — finish the surah 💪📘'
            : 'Last day of your goal! Read today — you\'re almost there 🏁📖';
      }
      if (d <= 3) {
        return isLearn
            ? '$daysStr. Final stretch — don\'t stop! 🔥📘'
            : '$daysStr until the goal ends. Dudi is with you — read! 🐪📖';
      }
      if (d <= 7) {
        final msgs = isLearn ? [
          '$daysStr — review it piece by piece every day 📘',
          '$daysStr — Dudi reminds you: memorization takes consistency 🤲',
          '$daysStr — split the surah into parts and learn one at a time 📘',
        ] : [
          '$daysStr — read at least a page a day 📖',
          '$daysStr — Dudi is with you on your path 🐪',
          '$daysStr — consistency matters more than quantity 🌿',
        ];
        return msgs[d % msgs.length];
      }
      if (d <= 14) {
        return isLearn
            ? '$daysStr. Learn 3–5 ayahs a day — you\'ll make it! 📘'
            : '$daysStr. Read a page in the morning and evening 📖';
      }
      return isLearn
          ? '$daysStr to finish the goal. Dudi is with you every step 🐪📘'
          : '$daysStr. Start now — a small step leads to a great goal 📖';
    }

    // Kazakh
    final daysStr = d == 1 ? '1 күн қалды' : '$d күн қалды';
    if (d == 1) {
      return isLearn
          ? 'Соңғы күн! Dudi сенеді — сүрені аяқта 💪📘'
          : 'Мақсаттың соңғы күні! Бүгін оқы — финишке жеттің 🏁📖';
    }
    if (d <= 3) {
      return isLearn
          ? '$daysStr. Финишке жақын — тоқтама! 🔥📘'
          : '$daysStr мақсат аяқталады. Dudi қасында — оқы! 🐪📖';
    }
    if (d <= 7) {
      final msgs = isLearn ? [
        '$daysStr — күн сайын бөліктеп қайтала 📘',
        '$daysStr — Dudi еске салады: жаттау тұрақтылықты талап етеді 🤲',
        '$daysStr — сүрені бөліктерге бөліп, біртіндеп үйрен 📘',
      ] : [
        '$daysStr — күн сайын кем дегенде бір бет оқы 📖',
        '$daysStr — Dudi жолыңда қасында 🐪',
        '$daysStr — тұрақтылық мөлшерден маңызды 🌿',
      ];
      return msgs[d % msgs.length];
    }
    if (d <= 14) {
      return isLearn
          ? '$daysStr. Күн сайын 3–5 аят үйрен — үлгересің! 📘'
          : '$daysStr. Таңертең және кеш бір беттен оқы 📖';
    }
    return isLearn
        ? '$daysStr мақсат аяқталады. Dudi әр қадамда қасында 🐪📘'
        : '$daysStr. Қазір баста — кішкентай қадам ұлы мақсатқа жетелейді 📖';
  }

  static String _eveningMessage(int days, {String lang = 'kz'}) {
    if (lang == 'ru') {
      if (days == 0) {
        final msgs = [
          'МашааАллах! Ты занимался сегодня. Так держать — постоянство любимо Аллахом 📖',
          'Отличный день! Пусть каждый прочитанный аят будет нуром в твоём сердце 🌟',
          'Молодец! Пророк ﷺ сказал: лучшее дело — то, что делается постоянно 🤲',
        ];
        return msgs[days % msgs.length];
      }
      if (days == 1) {
        final msgs = [
          'Не забудь прочитать Коран сегодня — сохрани свою серию! 🔥',
          'Один день — один аят. Маленький шаг лучше, чем остановка 📖',
          'Dudi напоминает: сегодня твой день для Корана. Не откладывай 🐪',
        ];
        return msgs[DateTime.now().weekday % msgs.length];
      }
      if (days == 2) return 'Прошло 2 дня... Dudi скучает. Один аят — и серия возобновится! 🐪';
      if (days == 3) return '$days дня без Корана. Помни: «Читайте Коран, ибо он придёт заступником» 🌙';
      if (days <= 7) return '$days дней без Корана. Вернись сегодня — Аллах принимает раскаяние 🤲';
      if (days <= 14) return 'Dudi ждёт тебя уже $days дней. Начни с Аль-Фатихи — 7 аятов, 1 минута 🌿';
      return 'Давно не виделись... Коран скучает. Бисмилла — и начни заново 🐪';
    }
    if (lang == 'en') {
      if (days == 0) {
        final msgs = [
          'MashaAllah! You studied today. Keep it up — consistency is beloved to Allah 📖',
          'Great day! May every ayah you read be a light in your heart 🌟',
          'Well done! The Prophet ﷺ said: the best deeds are the most consistent 🤲',
        ];
        return msgs[days % msgs.length];
      }
      if (days == 1) {
        final msgs = [
          'Don\'t forget to read the Quran today — keep your streak! 🔥',
          'One day — one ayah. A small step is better than stopping 📖',
          'Dudi reminds you: today is your Quran day. Don\'t put it off 🐪',
        ];
        return msgs[DateTime.now().weekday % msgs.length];
      }
      if (days == 2) return '2 days have passed... Dudi misses you. One ayah and the streak resumes! 🐪';
      if (days == 3) return '$days days without the Quran. Remember: "Read the Quran, for it will come as an intercessor" 🌙';
      if (days <= 7) return '$days days without the Quran. Come back today — Allah accepts repentance 🤲';
      if (days <= 14) return 'Dudi has been waiting for $days days. Start with Al-Fatihah — 7 ayahs, 1 minute 🌿';
      return 'It\'s been a while... The Quran misses you. Bismillah — start again 🐪';
    }
    if (days == 0) {
      final msgs = [
        'МашааАллах! Бүгін жақсы оқыдың. Тұрақтылық — Аллахқа ең сүйікті амал 📖',
        'Тамаша күн! Оқыған әр аятың жүрегіңе нұр болсын 🌟',
        'Жарайсың! Пайғамбар ﷺ айтты: ең жақсы амал — тұрақты амал 🤲',
      ];
      return msgs[days % msgs.length];
    }
    if (days == 1) {
      final msgs = [
        'Бүгін Құран оқуды ұмытпа — серияңды сақта! 🔥',
        'Бір күн — бір аят. Кішкентай қадам тоқтаудан жақсы 📖',
        'Dudi еске салады: бүгін Құран күнің. Кейінге қалдырма 🐪',
      ];
      return msgs[DateTime.now().weekday % msgs.length];
    }
    if (days == 2) return '2 күн болды... Dudi сағынды. Бір аят — және серия жалғасады! 🐪';
    if (days == 3) return '$days күн оқымадың. «Құранды оқыңдар, ол қияметте шапағатшы болады» 🌙';
    if (days <= 7) return '$days күн Құрансыз. Бүгін қайт — Алла тәубені қабыл етеді 🤲';
    if (days <= 14) return 'Dudi $days күн күтті. Әл-Фатихадан баста — 7 аят, 1 минут 🌿';
    return 'Ұзақ болды... Құран сізді күтеді. Бисмилла — жаңадан бастайық 🐪';
  }

  static String _morningMessage(int days, {String lang = 'kz'}) {
    final List<String> tips;
    switch (lang) {
      case 'ru': tips = _tipsRu; break;
      case 'en': tips = _tipsEn; break;
      default:   tips = _tipsKz;
    }
    final tip = tips[DateTime.now().day % tips.length];

    if (lang == 'ru') {
      if (days == 0) {
        final msgs = [
          'Ассаляму алейкум! Продолжай свой путь с Кораном ☀️',
          'Доброе утро! Вчера было хорошо — сегодня ещё лучше 🌟',
          'С именем Аллаха начни день! $tip',
        ];
        return msgs[DateTime.now().weekday % msgs.length];
      }
      if (days == 1) return 'Доброе утро! Поддержи серию — прочитай сегодня 🔥 $tip';
      if (days <= 3) return 'Доброе утро! $days день без Корана. Сегодня — отличный шанс вернуться 🌿';
      return 'Dudi желает доброго утра! Начни день с аята — и он будет благословенным 🌙';
    }
    if (lang == 'en') {
      if (days == 0) {
        final msgs = [
          'Assalamu alaikum! Continue your journey with the Quran ☀️',
          'Good morning! Yesterday was good — today will be even better 🌟',
          'Start the day in the name of Allah! $tip',
        ];
        return msgs[DateTime.now().weekday % msgs.length];
      }
      if (days == 1) return 'Good morning! Keep the streak — read today 🔥 $tip';
      if (days <= 3) return 'Good morning! $days days without the Quran. Today is a great chance to return 🌿';
      return 'Dudi wishes you a good morning! Start the day with an ayah — it will be blessed 🌙';
    }
    if (days == 0) {
      final msgs = [
        'Ассалаумағалейкум! Бүгін де Құранмен жол жүр ☀️',
        'Қайырлы таң! Кеше жақсы болды — бүгін одан да жақсы 🌟',
        'Алланың атымен күнді баста! $tip',
      ];
      return msgs[DateTime.now().weekday % msgs.length];
    }
    if (days == 1) return 'Қайырлы таң! Серияңды жалғастыр — бүгін оқы 🔥 $tip';
    if (days <= 3) return 'Қайырлы таң! $days күн болды. Бүгін — оралуға тамаша мүмкіндік 🌿';
    return 'Dudi қайырлы таң тілейді! Аятпен күнді баста — ол берекелі болады 🌙';
  }

  static const _tipsKz = [
    'Кеңес: Күн сайын 5 минут Құран оқу — жылда 30 сағат!',
    'Кеңес: Ясин сүресін жұма таңертеңінде оқу — сүннет.',
    'Кеңес: Аятуль-Күрсиді таңертеңгі, кешкі намаздан кейін оқы.',
    'Кеңес: Мүлк сүресі қабірде шапағатшы болады.',
    'Кеңес: Іхлас сүресі — Құранның үштен біріне тең.',
    'Кеңес: Кәһф сүресін жұма күні оқу — дажжалдан қорғайды.',
  ];

  static const _tipsRu = [
    'Совет: 5 минут Корана каждый день — это 30 часов в год!',
    'Совет: Суру Ясин читают утром пятницы — это сунна.',
    'Совет: Аятуль-Курси читай после каждой молитвы.',
    'Совет: Сура Мульк заступается в могиле.',
    'Совет: Сура Ихлас равна трети Корана.',
    'Совет: Сура Кахф в пятницу — защита от Даджжала.',
  ];

  static const _tipsEn = [
    'Tip: 5 minutes of Quran every day is 30 hours a year!',
    'Tip: Reading Surah Ya-Sin on Friday morning is a sunnah.',
    'Tip: Recite Ayat al-Kursi after every prayer.',
    'Tip: Surah Al-Mulk intercedes in the grave.',
    'Tip: Surah Al-Ikhlas equals a third of the Quran.',
    'Tip: Surah Al-Kahf on Friday protects from the Dajjal.',
  ];
}
