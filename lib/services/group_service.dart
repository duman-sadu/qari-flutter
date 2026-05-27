import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class GroupMemberFull {
  final String uid;
  final String name;
  final String role;
  final int? juz;
  final bool juzCompleted;

  const GroupMemberFull({
    required this.uid,
    required this.name,
    required this.role,
    this.juz,
    this.juzCompleted = false,
  });

  factory GroupMemberFull.fromMap(Map<String, dynamic> m) => GroupMemberFull(
        uid: m['userId'] as String? ?? '',
        name: m['name'] as String? ?? 'Пайдаланушы',
        role: m['role'] as String? ?? 'member',
        juz: (m['juz'] as num?)?.toInt(),
        juzCompleted: m['juzCompleted'] as bool? ?? false,
      );
}

class GroupMember {
  final String uid;
  final String name;
  final bool completed;
  final DateTime? takenAt;
  final DateTime? completedAt;

  const GroupMember({
    required this.uid,
    required this.name,
    this.completed = false,
    this.takenAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'name': name,
        'completed': completed,
        if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Пайдаланушы',
        completed: j['completed'] as bool? ?? false,
        takenAt: _parseDate(j['takenAt']),
        completedAt: _parseDate(j['completedAt']),
      );
}

class KhatamMemberEntry {
  final int juz;
  final String uid;
  final String name;
  final DateTime? takenAt;
  final DateTime? completedAt;

  const KhatamMemberEntry({
    required this.juz,
    required this.uid,
    required this.name,
    this.takenAt,
    this.completedAt,
  });

  factory KhatamMemberEntry.fromMap(Map<String, dynamic> m) =>
      KhatamMemberEntry(
        juz: (m['juz'] as num?)?.toInt() ?? 0,
        uid: m['uid'] as String? ?? m['userId'] as String? ?? '',
        name: m['name'] as String? ?? 'Пайдаланушы',
        takenAt: GroupMember._parseDate(m['takenAt']),
        completedAt: GroupMember._parseDate(m['completedAt']),
      );

  Map<String, dynamic> toMap() => {
        'juz': juz,
        'uid': uid,
        'name': name,
        if (takenAt != null) 'takenAt': takenAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      };
}

class KhatamRecord {
  final int number;
  final DateTime completedAt;
  final List<KhatamMemberEntry> entries;

  const KhatamRecord({
    required this.number,
    required this.completedAt,
    required this.entries,
  });

  factory KhatamRecord.fromMap(Map<String, dynamic> m) => KhatamRecord(
        number: (m['number'] as num?)?.toInt() ?? 0,
        completedAt: GroupMember._parseDate(m['completedAt']) ?? DateTime.now(),
        entries: ((m['entries'] as List?) ?? [])
            .map((e) => KhatamMemberEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'number': number,
        'completedAt': completedAt.toIso8601String(),
        'entries': entries.map((e) => e.toMap()).toList(),
      };
}

class QuranGroup {
  final String id;
  final String name;
  final String createdBy;
  final String inviteCode;
  final Map<int, GroupMember> juzAssignments;
  final Map<int, GroupMember> nextRoundAssignments;
  final List<String> memberUids;
  final int khatamCount;
  final List<KhatamRecord> khatamHistory;
  final List<String> duaList;
  final List<GroupMemberFull> allMembers;
  final int myKhatamCount;
  final int? _assignedCountOverride;

  const QuranGroup({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.inviteCode,
    required this.juzAssignments,
    this.nextRoundAssignments = const {},
    required this.memberUids,
    this.khatamCount = 0,
    this.khatamHistory = const [],
    this.duaList = const [],
    this.allMembers = const [],
    this.myKhatamCount = 0,
    int? assignedCountOverride,
  }) : _assignedCountOverride = assignedCountOverride;

  int get assignedCount => _assignedCountOverride ?? juzAssignments.length;
  int get completedCount =>
      juzAssignments.values.where((m) => m.completed).length;
  bool get isComplete => juzAssignments.length == 30;
  bool get allDone =>
      juzAssignments.length == 30 &&
      juzAssignments.values.every((m) => m.completed);

  int? myJuz(String uid) {
    for (final e in juzAssignments.entries) {
      if (e.value.uid == uid && !e.value.completed) return e.key;
    }
    return null;
  }

  int? myNextRoundJuz(String uid) {
    for (final e in nextRoundAssignments.entries) {
      if (e.value.uid == uid) return e.key;
    }
    return null;
  }

  bool hasActiveJuz(String uid) =>
      myJuz(uid) != null || myNextRoundJuz(uid) != null;

  bool isMyJuzComplete(String uid) {
    for (final e in juzAssignments.entries) {
      if (e.value.uid == uid) return e.value.completed;
    }
    return false;
  }

  /// Build a QuranGroup from the backend GET /groups/:id response (has members list).
  factory QuranGroup.fromBackend(Map<String, dynamic> data) {
    final members = (data['members'] as List?) ?? [];
    final juzAssignments = <int, GroupMember>{};
    final nextRoundAssignments = <int, GroupMember>{};
    final memberUids = <String>[];

    for (final m in members) {
      final map = m as Map<String, dynamic>;
      final uid = map['userId'] as String? ?? '';
      final name = map['name'] as String? ?? 'Пайдаланушы';
      final completed = map['juzCompleted'] as bool? ?? false;
      final takenAt = GroupMember._parseDate(map['juzTakenAt']);
      final completedAt = GroupMember._parseDate(map['juzCompletedAt']);

      if (!memberUids.contains(uid)) memberUids.add(uid);

      final juz = (map['juz'] as num?)?.toInt();
      if (juz != null) {
        juzAssignments[juz] = GroupMember(
          uid: uid,
          name: name,
          completed: completed,
          takenAt: takenAt,
          completedAt: completedAt,
        );
      }

      final nextJuz = (map['nextJuz'] as num?)?.toInt();
      if (nextJuz != null) {
        nextRoundAssignments[nextJuz] = GroupMember(
          uid: uid,
          name: name,
          completed: false,
          takenAt: takenAt,
        );
      }

      // Restore previously completed juzes — only if the slot isn't already
      // held by another member's active assignment (current juz always wins).
      final completedJuzes = (map['completedJuzes'] as List?)?.cast<int>() ?? [];
      for (final cj in completedJuzes) {
        if (!juzAssignments.containsKey(cj)) {
          juzAssignments[cj] = GroupMember(
            uid: uid,
            name: name,
            completed: true,
          );
        }
      }
    }

    final history = ((data['khatamHistory'] as List?) ?? [])
        .map((e) => KhatamRecord.fromMap(e as Map<String, dynamic>))
        .toList();

    final allMembers = (data['members'] as List? ?? [])
        .map((m) => GroupMemberFull.fromMap(m as Map<String, dynamic>))
        .toList();

    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final myKhatamCount =
        history.where((r) => r.entries.any((e) => e.uid == myUid)).length;

    return QuranGroup(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      juzAssignments: juzAssignments,
      nextRoundAssignments: nextRoundAssignments,
      memberUids: memberUids,
      khatamCount: (data['khatamCount'] as num?)?.toInt() ?? 0,
      khatamHistory: history,
      duaList: List<String>.from(data['duaList'] as List? ?? []),
      allMembers: allMembers,
      myKhatamCount: myKhatamCount,
    );
  }

  /// Build a lightweight QuranGroup from the list response (no full members).
  factory QuranGroup.fromBackendList(Map<String, dynamic> data) {
    final myJuzNum = (data['myJuz'] as num?)?.toInt();
    final myJuzCompleted = data['myJuzCompleted'] as bool? ?? false;

    // Include the current user's active juz so myJuz() works in the list screen.
    final juzAssignments = <int, GroupMember>{};
    if (myJuzNum != null && !myJuzCompleted) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      juzAssignments[myJuzNum] = GroupMember(uid: uid, name: '');
    }

    return QuranGroup(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      juzAssignments: juzAssignments,
      memberUids: const [],
      khatamCount: (data['khatamCount'] as num?)?.toInt() ?? 0,
      duaList: List<String>.from(data['duaList'] as List? ?? []),
      assignedCountOverride: (data['assignedCount'] as num?)?.toInt(),
      myKhatamCount: (data['myKhatamCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class GroupService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  static bool get isLoggedIn => _uid != null;

  static String _memberName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email ?? 'Пайдаланушы';
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  static Future<QuranGroup?> createGroup(String name) async {
    final data = await ApiService.createGroup(name, _memberName());
    if (data == null) return null;
    return QuranGroup.fromBackendList(data);
  }

  static Future<QuranGroup?> joinByCode(String code) async {
    final data = await ApiService.joinGroup(code, _memberName());
    if (data == null) return null;
    return QuranGroup.fromBackendList(data);
  }

  static Future<List<QuranGroup>> myGroups() async {
    final list = await ApiService.getMyGroups();
    return list
        .map((e) => QuranGroup.fromBackendList(e as Map<String, dynamic>))
        .toList();
  }

  static Future<QuranGroup?> getGroup(String groupId) async {
    final data = await ApiService.getGroup(groupId);
    if (data == null) return null;
    return QuranGroup.fromBackend(data);
  }

  /// Polling stream — emits a fresh group every 10 seconds.
  static Stream<QuranGroup?> groupStream(String groupId) async* {
    while (true) {
      yield await getGroup(groupId);
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  /// Polling stream for the groups list — used by GroupsScreen.
  static Stream<List<QuranGroup>> myGroupsStream() async* {
    while (true) {
      yield await myGroups();
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  // ── Juz management ────────────────────────────────────────────────────────

  static Future<void> assignJuz(String groupId, int juz, String memberName) async {
    await ApiService.assignJuz(groupId, juz);
  }

  static Future<void> unassignJuz(String groupId, int juz) async {
    await ApiService.unassignJuz(groupId);
  }

  static Future<void> assignToNextRound(
      String groupId, int juz, String memberName) async {
    await ApiService.assignNextRoundJuz(groupId, juz);
  }

  static Future<void> unassignFromNextRound(String groupId, int juz) async {
    await ApiService.unassignNextRoundJuz(groupId);
  }

  static Future<bool> completeNextRoundJuz(String groupId) async {
    final result = await ApiService.completeNextRoundJuz(groupId);
    return result['khatamCompleted'] as bool? ?? false;
  }

  /// Returns true if this completion triggered a Khatam.
  static Future<bool> markJuzComplete(
      String groupId, int juz, String memberName, bool complete) async {
    if (!complete) {
      final ok = await ApiService.uncompleteJuz(groupId, juz);
      if (!ok) throw Exception('uncomplete failed');
      return false;
    }
    final result = await ApiService.completeJuz(groupId);
    return result?['khatamCompleted'] as bool? ?? false;
  }

  // ── Dua list ──────────────────────────────────────────────────────────────

  static Future<void> addDuaName(String groupId, String name) async {
    await ApiService.addDuaName(groupId, name);
  }

  static Future<void> removeDuaName(String groupId, String name) async {
    await ApiService.removeDuaName(groupId, name);
  }

  // ── Leave / Remove / Delete ───────────────────────────────────────────────

  static Future<void> resetMyKhatams(String groupId) async {
    await ApiService.resetMyGroupKhatams(groupId);
  }

  static Future<bool> clearDeletedGroupKhatam(String groupName) {
    return ApiService.clearDeletedGroupKhatam(groupName);
  }

  static Future<List<Map<String, dynamic>>> getDeletedGroupKhatams() async {
    return ApiService.getDeletedGroupKhatams();
  }

  static Future<void> leaveGroup(String groupId) async {
    await ApiService.leaveGroup(groupId);
  }

  static Future<void> removeMember(String groupId, String userId) async {
    await ApiService.removeMember(groupId, userId);
  }

  static Future<void> deleteGroup(String groupId) async {
    await ApiService.deleteGroup(groupId);
  }

  // ── Juz read counts ───────────────────────────────────────────────────────

  static Future<void> recordJuzRead(int juz) async {
    await ApiService.recordJuzRead(juz);
  }

  static Future<void> resetJuzReadCounts() async {
    await ApiService.resetJuzReadCounts();
  }

  static Stream<Map<int, int>> juzReadCountsStream() async* {
    while (true) {
      yield await ApiService.getJuzReadCounts();
      await Future.delayed(const Duration(seconds: 30));
    }
  }
}
