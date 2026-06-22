import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class FcmService {
  /// Invoked when the user taps a challenge push. Set from main.
  static void Function(String challengeId)? onChallengeTap;
  // Captured when the app is cold-started by tapping a challenge push,
  // then fired by [flushPendingChallenge] once the UI is ready.
  static String? _pendingChallengeId;

  static Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, sound: true, badge: true);
    final token = await messaging.getToken();
    if (token != null) await _saveToken(token);
    messaging.onTokenRefresh.listen(_saveToken);

    // App in background and brought to foreground by tapping the push.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App launched from terminated state by tapping the push.
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      final id = _challengeIdOf(initial);
      if (id != null) _pendingChallengeId = id;
    }
  }

  static void _handleTap(RemoteMessage message) {
    final id = _challengeIdOf(message);
    if (id != null) onChallengeTap?.call(id);
  }

  static String? _challengeIdOf(RemoteMessage m) {
    if (m.data['type'] == 'challenge') {
      final id = m.data['challengeId'];
      if (id is String && id.isNotEmpty) return id;
    }
    return null;
  }

  /// Fires a challenge tap captured during cold start, once the UI is ready.
  static void flushPendingChallenge() {
    final id = _pendingChallengeId;
    if (id != null) {
      _pendingChallengeId = null;
      onChallengeTap?.call(id);
    }
  }

  static Future<void> _saveToken(String token) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await ApiService.saveFcmToken(token);
  }
}
