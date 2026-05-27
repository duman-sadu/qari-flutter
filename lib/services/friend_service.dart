import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

class FriendProfile {
  final String uid;
  final String name;
  final int streak;
  final int learnedCount;
  final String? lastStudyDate;

  const FriendProfile({
    required this.uid,
    required this.name,
    required this.streak,
    required this.learnedCount,
    this.lastStudyDate,
  });

  factory FriendProfile.fromBackend(Map<String, dynamic> data) {
    final first = data['firstName'] as String? ?? '';
    final last = data['lastName'] as String? ?? '';
    final name = [last, first].where((s) => s.isNotEmpty).join(' ');
    return FriendProfile(
      uid: data['firebaseUid'] as String? ?? '',
      name: name.isEmpty ? 'Пайдаланушы' : name,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      learnedCount: (data['xp'] as num?)?.toInt() ?? 0,
      lastStudyDate: data['lastStudiedAt'] as String?,
    );
  }
}

class FriendService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ── Friend code ───────────────────────────────────────────────────────────

  static Future<String> getOrCreateMyCode() async {
    if (_uid == null) return '';
    return await ApiService.getMyFriendCode() ?? '';
  }

  // ── Add friend by code ────────────────────────────────────────────────────

  static Future<({bool success, String? error, FriendProfile? profile})>
      addFriendByCode(String rawCode) async {
    if (_uid == null) {
      return (success: false, error: 'Кірілмеген', profile: null);
    }

    final code = rawCode.trim().toUpperCase();
    final userData = await ApiService.findUserByCode(code);

    if (userData == null) {
      return (success: false, error: 'Пайдаланушы табылмады', profile: null);
    }

    final friendUid = userData['firebaseUid'] as String?;
    if (friendUid == null || friendUid.isEmpty) {
      return (success: false, error: 'Пайдаланушы табылмады', profile: null);
    }
    if (friendUid == _uid) {
      return (success: false, error: 'Бұл сіздің өз кодыңыз', profile: null);
    }

    final success = await ApiService.addFriend(friendUid);
    if (!success) {
      return (success: false, error: 'Қате орын алды', profile: null);
    }

    final first = userData['firstName'] as String? ?? '';
    final last = userData['lastName'] as String? ?? '';
    final name = [last, first].where((s) => s.isNotEmpty).join(' ');

    final profile = FriendProfile(
      uid: friendUid,
      name: name.isEmpty ? 'Пайдаланушы' : name,
      streak: (userData['streak'] as num?)?.toInt() ?? 0,
      learnedCount: 0,
    );
    return (success: true, error: null, profile: profile);
  }

  // ── Friends list ──────────────────────────────────────────────────────────

  static Future<List<FriendProfile>> getFriends() async {
    if (_uid == null) return [];
    final list = await ApiService.getFriends();
    return list
        .map((e) => FriendProfile.fromBackend(e as Map<String, dynamic>))
        .toList();
  }

  /// Polling stream — emits a fresh list every 15 seconds.
  static Stream<List<FriendProfile>> friendsStream() async* {
    while (true) {
      yield await getFriends();
      await Future.delayed(const Duration(seconds: 15));
    }
  }

  static Stream<int> pendingRequestCountStream() => const Stream.empty();

  // ── Remove ────────────────────────────────────────────────────────────────

  static Future<void> removeFriend(String friendUid) async {
    await ApiService.removeFriend(friendUid);
  }

  // ── No-ops kept for call-site compatibility ───────────────────────────────

  static Future<void> refreshFriendSnapshots() async {}

  static Future<List<FriendProfile>> processPendingRequests() async => [];

  static Future<void> publishMyStats({
    String? name,
    int? streak,
    int? learnedCount,
    String? lastStudyDate,
  }) async {}
}
