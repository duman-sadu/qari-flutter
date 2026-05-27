import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

// LAN IP of the dev machine — phone and PC must be on the same Wi-Fi.
const String _kBase = 'https://qari-backend-production-e8df.up.railway.app/api/v1';

class ApiService {
  static Future<String?> _token() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _token();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  static Future<void> loginToBackend() async {
    final token = await _token();
    if (token == null) return;
    try {
      await http.post(
        Uri.parse('$_kBase/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': token}),
      );
    } catch (_) {}
  }

  // ── Users / Profile ───────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/users/me'), headers: await _headers());
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> updateMe(Map<String, dynamic> data) async {
    try {
      final r = await http.patch(
        Uri.parse('$_kBase/users/me'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getProfileData() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/users/me/profile'), headers: await _headers());
      if (r.statusCode == 200 && r.body != 'null') {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveProfileData(Map<String, dynamic> data) async {
    try {
      await http.patch(
        Uri.parse('$_kBase/users/me/profile'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
    } catch (_) {}
  }

  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/users/leaderboard'), headers: await _headers());
      if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    } catch (_) {}
    return [];
  }

  // ── Progress state ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProgressState() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/users/me/progress'), headers: await _headers());
      if (r.statusCode == 200 && r.body != 'null') {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveProgressState(Map<String, dynamic> data) async {
    try {
      await http.patch(
        Uri.parse('$_kBase/users/me/progress'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
    } catch (_) {}
  }

  // ── Juz read counts ───────────────────────────────────────────────────────

  static Future<Map<int, int>> getJuzReadCounts() async {
    try {
      final r = await http.get(
        Uri.parse('$_kBase/users/me/juz-reads'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final raw = data['counts'] as Map<String, dynamic>? ?? {};
        return raw.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      }
    } catch (_) {}
    return {};
  }

  static Future<void> recordJuzRead(int juz) async {
    try {
      await http.post(
        Uri.parse('$_kBase/users/me/juz-reads'),
        headers: await _headers(),
        body: jsonEncode({'juz': juz}),
      );
    } catch (_) {}
  }

  static Future<void> resetJuzReadCounts() async {
    try {
      await http.delete(
        Uri.parse('$_kBase/users/me/juz-reads'),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  // ── Friend code ───────────────────────────────────────────────────────────

  static Future<String?> getMyFriendCode() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/users/me/friend-code'), headers: await _headers());
      if (r.statusCode == 200) {
        return (jsonDecode(r.body) as Map<String, dynamic>)['code'] as String?;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> findUserByCode(String code) async {
    try {
      final r = await http.get(
        Uri.parse('$_kBase/users/by-code/${Uri.encodeComponent(code.trim().toUpperCase())}'),
        headers: await _headers(),
      );
      if (r.statusCode == 200 && r.body != 'null') {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  // ── Groups ────────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getMyGroups() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/groups'), headers: await _headers());
      if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>?> createGroup(String name, String memberName) async {
    try {
      final r = await http.post(
        Uri.parse('$_kBase/groups'),
        headers: await _headers(),
        body: jsonEncode({'name': name, 'memberName': memberName}),
      );
      if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> joinGroup(String code, String memberName) async {
    try {
      final r = await http.post(
        Uri.parse('$_kBase/groups/join'),
        headers: await _headers(),
        body: jsonEncode({'code': code, 'memberName': memberName}),
      );
      if (r.statusCode == 201) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getGroup(String groupId) async {
    try {
      final r = await http.get(Uri.parse('$_kBase/groups/$groupId'), headers: await _headers());
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<void> assignJuz(String groupId, int juz) async {
    try {
      await http.post(
        Uri.parse('$_kBase/groups/$groupId/juz'),
        headers: await _headers(),
        body: jsonEncode({'juz': juz}),
      );
    } catch (_) {}
  }

  static Future<bool> uncompleteJuz(String groupId, int juz) async {
    try {
      final r = await http.patch(
        Uri.parse('$_kBase/groups/$groupId/juz/uncomplete'),
        headers: await _headers(),
        body: jsonEncode({'juz': juz}),
      );
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> unassignJuz(String groupId) async {
    try {
      await http.delete(Uri.parse('$_kBase/groups/$groupId/juz'), headers: await _headers());
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> completeJuz(String groupId) async {
    try {
      final r = await http.patch(
        Uri.parse('$_kBase/groups/$groupId/juz/complete'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static Future<void> assignNextRoundJuz(String groupId, int juz) async {
    final r = await http.post(
      Uri.parse('$_kBase/groups/$groupId/next-juz'),
      headers: await _headers(),
      body: jsonEncode({'juz': juz}),
    );
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw Exception('assignNextRoundJuz failed: ${r.statusCode}');
    }
  }

  static Future<void> unassignNextRoundJuz(String groupId) async {
    try {
      await http.delete(Uri.parse('$_kBase/groups/$groupId/next-juz'), headers: await _headers());
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> completeNextRoundJuz(String groupId) async {
    final r = await http.patch(
      Uri.parse('$_kBase/groups/$groupId/next-juz/complete'),
      headers: await _headers(),
    );
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    throw Exception('completeNextRoundJuz failed: ${r.statusCode} ${r.body}');
  }

  static Future<List<Map<String, dynamic>>> getDeletedGroupKhatams() async {
    try {
      final r = await http.get(
        Uri.parse('$_kBase/users/me/deleted-khatams'),
        headers: await _headers(),
      );
      if (r.statusCode == 200) {
        return (jsonDecode(r.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> clearDeletedGroupKhatam(String groupName) async {
    try {
      final r = await http.delete(
        Uri.parse('$_kBase/users/me/deleted-khatams/${Uri.encodeComponent(groupName)}'),
        headers: await _headers(),
      );
      return r.statusCode == 200 || r.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  static Future<void> resetMyGroupKhatams(String groupId) async {
    try {
      await http.delete(
        Uri.parse('$_kBase/groups/$groupId/my-khatams'),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  static Future<void> leaveGroup(String groupId) async {
    try {
      await http.delete(Uri.parse('$_kBase/groups/$groupId/leave'), headers: await _headers());
    } catch (_) {}
  }

  static Future<void> removeMember(String groupId, String userId) async {
    try {
      await http.delete(
        Uri.parse('$_kBase/groups/$groupId/members/$userId'),
        headers: await _headers(),
      );
    } catch (_) {}
  }

  static Future<void> deleteGroup(String groupId) async {
    try {
      await http.delete(Uri.parse('$_kBase/groups/$groupId'), headers: await _headers());
    } catch (_) {}
  }

  static Future<void> addDuaName(String groupId, String name) async {
    try {
      await http.post(
        Uri.parse('$_kBase/groups/$groupId/dua-list'),
        headers: await _headers(),
        body: jsonEncode({'name': name}),
      );
    } catch (_) {}
  }

  static Future<void> removeDuaName(String groupId, String name) async {
    try {
      await http.delete(
        Uri.parse('$_kBase/groups/$groupId/dua-list'),
        headers: await _headers(),
        body: jsonEncode({'name': name}),
      );
    } catch (_) {}
  }

  // ── Friends ───────────────────────────────────────────────────────────────

  static Future<List<dynamic>> getFriends() async {
    try {
      final r = await http.get(Uri.parse('$_kBase/friends'), headers: await _headers());
      if (r.statusCode == 200) return jsonDecode(r.body) as List<dynamic>;
    } catch (_) {}
    return [];
  }

  static Future<bool> addFriend(String friendFirebaseUid) async {
    try {
      final r = await http.post(
        Uri.parse('$_kBase/friends'),
        headers: await _headers(),
        body: jsonEncode({'friendFirebaseUid': friendFirebaseUid}),
      );
      return r.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<void> removeFriend(String friendFirebaseUid) async {
    try {
      await http.delete(
        Uri.parse('$_kBase/friends'),
        headers: await _headers(),
        body: jsonEncode({'friendFirebaseUid': friendFirebaseUid}),
      );
    } catch (_) {}
  }
}
