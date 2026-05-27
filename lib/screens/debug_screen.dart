import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const String _base = 'https://qari-backend-production-e8df.up.railway.app/api/v1';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<_LogEntry> _logs = [];
  bool _loading = false;

  void _log(String msg, {bool ok = true, String? detail}) {
    setState(() => _logs.insert(
          0,
          _LogEntry(
            time: DateTime.now().toIso8601String().substring(11, 19),
            msg: msg,
            ok: ok,
            detail: detail,
          ),
        ));
  }

  Future<String?> _token() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(true);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>> _headers() async {
    final t = await _token();
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  Future<void> _runChecks() async {
    setState(() {
      _logs.clear();
      _loading = true;
    });

    // 1. Firebase
    final user = FirebaseAuth.instance.currentUser;
    _log('Firebase uid: ${user?.uid ?? "NULL"}', ok: user != null);
    _log('Email: ${user?.email ?? "нет"}', ok: user?.email != null);

    if (user == null) {
      _log('Стоп: пользователь не залогинен', ok: false);
      setState(() => _loading = false);
      return;
    }

    // 2. Token
    final token = await _token();
    _log('Token: ${token != null ? "✅ ${token.length} chars" : "null"}',
        ok: token != null);

    final h = await _headers();

    // 3. GET /users/me
    try {
      final r = await http.get(Uri.parse('$_base/users/me'), headers: h);
      _log('GET /users/me → ${r.statusCode}',
          ok: r.statusCode == 200, detail: r.statusCode != 200 ? r.body : null);
    } catch (e) {
      _log('GET /users/me error: $e', ok: false);
    }

    // 4. GET /groups
    List groups = [];
    try {
      final r = await http.get(Uri.parse('$_base/groups'), headers: h);
      _log('GET /groups → ${r.statusCode}', ok: r.statusCode == 200);
      if (r.statusCode == 200) {
        groups = jsonDecode(r.body) as List;
        for (final g in groups) {
          _log('  • ${g["name"]} (${g["id"]})', ok: true);
        }
      } else {
        _log('Body: ${r.body}', ok: false);
      }
    } catch (e) {
      _log('GET /groups error: $e', ok: false);
    }

    if (groups.isEmpty) {
      _log('Нет групп — тест assignJuz пропущен', ok: false);
      setState(() => _loading = false);
      return;
    }

    // 5. GET /groups/:id — полный детальный ответ
    final gId = groups.first['id'] as String;
    try {
      final r =
          await http.get(Uri.parse('$_base/groups/$gId'), headers: h);
      _log('GET /groups/$gId → ${r.statusCode}', ok: r.statusCode == 200);

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body) as Map<String, dynamic>;
        final members = data['members'] as List? ?? [];
        _log('  Участников: ${members.length}', ok: true);
        final myUid = user.uid;
        final myMember = members.firstWhere(
          (m) => m['userId'] == myUid,
          orElse: () => null,
        );
        if (myMember != null) {
          _log(
            '  Мой жуз: ${myMember["juz"] ?? "не назначен"}'
            ' | completed: ${myMember["juzCompleted"]}'
            ' | nextJuz: ${myMember["nextJuz"] ?? "нет"}',
            ok: true,
          );
        } else {
          _log('  Я не участник этой группы!', ok: false);
        }
      } else {
        _log('Body: ${r.body}', ok: false);
      }
    } catch (e) {
      _log('GET /groups/:id error: $e', ok: false);
    }

    // 6. POST /groups/:id/juz — с полным телом ответа
    try {
      final r = await http.post(
        Uri.parse('$_base/groups/$gId/juz'),
        headers: h,
        body: jsonEncode({'juz': 2}),
      );
      _log(
        'POST /groups/$gId/juz(2) → ${r.statusCode}',
        ok: r.statusCode == 200 || r.statusCode == 201,
        detail: r.body, // всегда показываем тело
      );
    } catch (e) {
      _log('POST /juz error: $e', ok: false);
    }

    // 7. DELETE /juz — попробуем снять и назначить заново
    try {
      final r = await http.delete(
        Uri.parse('$_base/groups/$gId/juz'),
        headers: h,
      );
      _log('DELETE /groups/$gId/juz → ${r.statusCode}',
          ok: r.statusCode == 200, detail: r.statusCode != 200 ? r.body : null);
    } catch (e) {
      _log('DELETE /juz error: $e', ok: false);
    }

    // 8. POST снова после снятия
    try {
      final r = await http.post(
        Uri.parse('$_base/groups/$gId/juz'),
        headers: h,
        body: jsonEncode({'juz': 3}),
      );
      _log(
        'POST /groups/$gId/juz(3) после DELETE → ${r.statusCode}',
        ok: r.statusCode == 200 || r.statusCode == 201,
        detail: r.body,
      );
    } catch (e) {
      _log('POST /juz(3) error: $e', ok: false);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('🔧 Debug', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _runChecks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('▶ Запустить проверку',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text('Нажми кнопку выше',
                        style: TextStyle(color: Colors.white38)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final e = _logs[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '[${e.time}] ${e.msg}',
                              style: TextStyle(
                                fontSize: 12,
                                color: e.ok
                                    ? (e.msg.startsWith('  ')
                                        ? Colors.white38
                                        : const Color(0xFF69F0AE))
                                    : const Color(0xFFFF5252),
                                fontFamily: 'monospace',
                                height: 1.4,
                              ),
                            ),
                            if (e.detail != null)
                              Container(
                                margin: const EdgeInsets.only(top: 3, left: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D0D1A),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  e.detail!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFFFD54F),
                                    fontFamily: 'monospace',
                                    height: 1.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final String time;
  final String msg;
  final bool ok;
  final String? detail;

  const _LogEntry(
      {required this.time,
      required this.msg,
      required this.ok,
      this.detail});
}