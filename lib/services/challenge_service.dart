import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChallengeService {
  static final _db = FirebaseFirestore.instance;
  static const _col = 'challenges';

  static String _generateId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  static String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static Future<String> create({
    required List<int> questionIndices,
    required String creatorName,
    required bool isRu,
    String? targetUid,
    String? targetName,
  }) async {
    final id = _generateId();
    await _db.collection(_col).doc(id).set({
      'questionIndices': questionIndices,
      'creatorUid': _myUid,
      'creatorName': creatorName,
      'creatorScore': -1,
      'challengerUid': targetUid,
      'challengerName': targetName,
      'challengerScore': -1,
      'createdAt': FieldValue.serverTimestamp(),
      'isRu': isRu,
    });
    return id;
  }

  static Future<Map<String, dynamic>?> get(String id) async {
    final doc = await _db.collection(_col).doc(id.toUpperCase()).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> saveScore({
    required String challengeId,
    required int score,
    required String playerName,
  }) async {
    final doc = await _db.collection(_col).doc(challengeId).get();
    if (!doc.exists) return;
    final isCreator = (doc.data()?['creatorUid'] as String?) == _myUid;
    await _db.collection(_col).doc(challengeId).update(
      isCreator
          ? {'creatorScore': score}
          : {
              'challengerUid': _myUid,
              'challengerName': playerName,
              'challengerScore': score,
            },
    );
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String id) =>
      _db.collection(_col).doc(id).snapshots();

  /// Incoming challenges directed at the current user that haven't been
  /// accepted yet (challengerScore == -1 means quiz not done).
  /// Single-field query avoids the need for a composite Firestore index.
  static Stream<List<Map<String, dynamic>>> pendingForMeStream() {
    if (_myUid.isEmpty) return const Stream.empty();
    return _db
        .collection(_col)
        .where('challengerUid', isEqualTo: _myUid)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => (d.data()['challengerScore'] as int? ?? -1) < 0)
            .map((d) => <String, dynamic>{...d.data(), 'id': d.id})
            .toList());
  }

  static bool isCreator(Map<String, dynamic> data) =>
      (data['creatorUid'] as String?) == _myUid;

  static int opponentScore(Map<String, dynamic> data) =>
      isCreator(data)
          ? (data['challengerScore'] as int? ?? -1)
          : (data['creatorScore'] as int? ?? -1);

  static String opponentName(Map<String, dynamic> data) =>
      isCreator(data)
          ? (data['challengerName'] as String? ?? '')
          : (data['creatorName'] as String? ?? '');
}
