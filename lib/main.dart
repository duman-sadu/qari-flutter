import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';

import 'firebase_options.dart';
import 'services/audio_handler.dart';

import 'providers/plan_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/language_provider.dart';
import 'models/goal.dart';
import 'services/notification_service.dart';
import 'services/quran_api.dart';
import 'services/widget_service.dart';
import 'theme/app_colors.dart';

import 'screens/intro_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/learning_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/surah_select_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/friends_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final isOnboarded = prefs.getString('studyMode') != null;

  final planProvider = PlanProvider();
  final onboardingProvider = OnboardingProvider();
  final themeProvider = ThemeProvider();
  final goalProvider = GoalProvider();
  final languageProvider = LanguageProvider();
  audioHandler = await AudioService.init<QariAudioHandler>(
    builder: () => QariAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'kz.qari.audio',
      androidNotificationChannelName: 'Qari',
      androidNotificationIcon: 'drawable/reminder',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  await Future.wait([
    planProvider.loadProgress(),
    onboardingProvider.loadLocal(),
    themeProvider.load(),
    goalProvider.load(),
    languageProvider.load(),
    initQuranOfflineData(),
  ]);

  // Уведомления — каждый шаг изолирован, одна ошибка не блокирует остальное
  try {
    await NotificationService.initialize();
  } catch (_) {}

  try {
    await NotificationService.requestBatteryOptimization();
  } catch (_) {}

  try {
    final allDates = [
      ...planProvider.learnedHistory.map((h) => h.date),
      ...planProvider.readHistory.map((h) => h.date),
    ]..sort();
    final int daysSince;
    if (allDates.isEmpty) {
      daysSince = 9999;
    } else {
      final last = DateTime.parse(allDates.last);
      final today = DateTime.now();
      daysSince = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
    }
    final isRu = (prefs.getString('appLang') ?? 'kz') == 'ru';
    await NotificationService.scheduleReminder(daysSince, isRu: isRu);
    await NotificationService.scheduleMorningReminder(daysSince, isRu: isRu);
    await NotificationService.scheduleFridayReminder(isRu: isRu);

    final hasDonated = prefs.getBool('hasDonated') ?? false;
    if (hasDonated) {
      await NotificationService.cancelSupportReminder();
    } else {
      await NotificationService.scheduleSupportReminder(isRu: isRu);
    }

    // Goal notifications — one per remaining day, stops at deadline
    for (final g in goalProvider.goals) {
      try {
        final isLearn = g.type == GoalType.learn;
        final title = isRu
            ? 'Dudi — ${isLearn ? 'Цель заучивания' : 'Цель чтения'}'
            : 'Dudi — ${isLearn ? 'Жаттау' : 'Оқу'} мақсаты';
        await NotificationService.scheduleGoalNotifications(
          baseId: g.notifId,
          title: title,
          hour: g.notifHour,
          minute: g.notifMinute,
          deadline: g.deadline,
          isLearn: isLearn,
          isRu: isRu,
        );
      } catch (_) {}
    }
  } catch (_) {}

  // Update home screen widget data
  try {
    final isRu = (prefs.getString('appLang') ?? 'kz') == 'ru';
    await WidgetService.update(
      plan: planProvider,
      goals: goalProvider,
      isRu: isRu,
    );
  } catch (_) {}

  // Keep widget in sync as user progresses through ayahs
  planProvider.onWidgetUpdate = () async {
    try {
      final p = await SharedPreferences.getInstance();
      final isRu = (p.getString('appLang') ?? 'kz') == 'ru';
      await WidgetService.update(plan: planProvider, goals: goalProvider, isRu: isRu);
    } catch (_) {}
  };

  // Auth listener — skip the initial emission (already loaded above),
  // only reload when the user actually signs in or out.
  bool authListenerReady = false;
  FirebaseAuth.instance.authStateChanges().listen((user) async {
    if (!authListenerReady) {
      authListenerReady = true;
      return;
    }
    if (user != null) {
      await planProvider.loadProgress();
      await onboardingProvider.loadFromFirestore();
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: planProvider),
        ChangeNotifierProvider.value(value: onboardingProvider),
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: goalProvider),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: QariApp(
        initialRoute: isOnboarded ? '/learning' : '/welcome',
      ),
    ),
  );
}

ThemeData _buildTheme(AppColors c, Brightness brightness) => ThemeData(
  brightness: brightness,
  scaffoldBackgroundColor: c.bg,
  colorScheme: ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: Colors.white,
    secondary: c.green,
    onSecondary: Colors.white,
    error: Colors.red,
    onError: Colors.white,
    surface: c.card,
    onSurface: c.text,
  ),
  extensions: [c],
);

class QariApp extends StatelessWidget {
  final String initialRoute;
  const QariApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Qari',
      theme:     _buildTheme(AppColors.light, Brightness.light),
      darkTheme: _buildTheme(AppColors.dark,  Brightness.dark),
      themeMode: themeProvider.themeMode,
      initialRoute: initialRoute,
      routes: {
        '/intro':        (_) => const IntroScreen(),
        '/welcome':      (_) => const WelcomeScreen(),
        '/onboarding':   (_) => const OnboardingScreen(),
        '/learning':     (_) => const LearningScreen(),
        '/stats':        (_) => const StatsScreen(),
        '/profile':      (_) => const ProfileScreen(),
        '/surah-select': (_) => const SurahSelectScreen(),
        '/groups':       (_) => const GroupsScreen(),
        '/friends':      (_) => const FriendsScreen(),
      },
    );
  }
}
