import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/language_provider.dart';
import '../services/group_service.dart';
import '../services/friend_service.dart';
import '../theme/app_colors.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  LanguageProvider get _s => context.read<LanguageProvider>();

  Set<String> _friendUids = {};
  StreamSubscription<List<FriendProfile>>? _friendsSub;
  StreamSubscription<QuranGroup?>? _khatamSub;
  late final Stream<QuranGroup?> _groupStream;
  bool _historyExpanded = false;
  int _lastKhatamCount = -1;
  bool _justTriggeredKhatam = false;
  QuranGroup? _optimisticGroup; // instant UI before next poll
  int _pendingOptimistic = 0; // blocks stream from clearing optimistic while a request is in-flight

  @override
  void initState() {
    super.initState();

    // Single broadcast stream shared by StreamBuilder and khatam listener.
    // This prevents two parallel backend polls.
    _groupStream = GroupService.groupStream(widget.groupId).asBroadcastStream();

    _friendsSub = FriendService.friendsStream().listen((friends) {
      if (mounted) {
        setState(() => _friendUids = friends.map((f) => f.uid).toSet());
      }
    });
    _khatamSub = _groupStream.listen((group) {
      if (group == null || !mounted) return;

      // Fresh data arrived — clear optimistic only when no request is in-flight.
      // If _pendingOptimistic > 0 the API call hasn't finished yet and snap.data
      // is still stale, so keeping the optimistic prevents a visible revert.
      if (_optimisticGroup != null && _pendingOptimistic == 0) {
        setState(() => _optimisticGroup = null);
      }

      final count = group.khatamCount;
      if (_lastKhatamCount == -1) {
        _lastKhatamCount = count;
        return;
      }
      if (count > _lastKhatamCount) {
        _lastKhatamCount = count;
        if (_justTriggeredKhatam) {
          _justTriggeredKhatam = false;
          return; // already showed dialog from Бітті tap
        }
        // Another user triggered khatam — notify everyone in this screen.
        final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final isAdminUser = myUid == group.createdBy;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (isAdminUser) {
            _showAdminKhatamNotification(context, count, duaList: group.duaList);
          } else {
            _showKhatamDialog(context, AppColors.of(context), count);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _friendsSub?.cancel();
    _khatamSub?.cancel();
    super.dispose();
  }

  void _showAdminKhatamNotification(BuildContext context, int number,
      {List<String> duaList = const []}) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🕌', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              _s.tr('khatamMubarak'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: c.gold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _s.khatamGroupMsg(number),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.subtext, height: 1.5),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                _showDuaDialog(context, duaList: duaList);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: c.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _s.tr('openDua'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Text(
                _s.tr('close'),
                style: TextStyle(
                    fontSize: 14,
                    color: c.subtext,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDuaDialog(BuildContext context,
      {List<String> duaList = const []}) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _s.tr('duaTitle'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: c.gold,
                  ),
                ),
                const SizedBox(height: 6),
                Divider(color: c.gold.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                // Arabic
                const Text(
                  'اللَّهُمَّ ارْحَمْنَا بِالْقُرْآنِ، وَاجْعَلْهُ لَنَا إِمَامًا وَنُورًا وَهُدًى وَرَحْمَةً.\n\n'
                  'اللَّهُمَّ ذَكِّرْنَا مِنْهُ مَا نَسِينَا، وَعَلِّمْنَا مِنْهُ مَا جَهِلْنَا، وَارْزُقْنَا تِلَاوَتَهُ آنَاءَ اللَّيْلِ وَأَطْرَافَ النَّهَارِ، وَاجْعَلْهُ لَنَا حُجَّةً يَا رَبَّ الْعَالَمِينَ.\n\n'
                  'اللَّهُمَّ أَصْلِحْ لَنَا دِينَنَا الَّذِي هُوَ عِصْمَةُ أَمْرِنَا، وَأَصْلِحْ لَنَا دُنْيَانَا الَّتِي فِيهَا مَعَاشُنَا، وَأَصْلِحْ لَنَا آخِرَتَنَا الَّتِي إِلَيْهَا مَعَادُنَا.\n\n'
                  'اللَّهُمَّ اجْعَلِ الْقُرْآنَ رَبِيعَ قُلُوبِنَا، وَنُورَ صُدُورِنَا، وَجَلَاءَ أَحْزَانِنَا، وَذَهَابَ هُمُومِنَا وَغُمُومِنَا.\n\n'
                  'وَصَلَّى اللَّهُ عَلَى سَيِّدِنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 20,
                    height: 2.2,
                    color: Color(0xFF2C5F2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: c.border),
                const SizedBox(height: 12),
                // Translated prayer text
                Text(
                  _s.duaTranslation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.7,
                    color: c.subtext,
                  ),
                ),
                if (duaList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Divider(color: c.border),
                  const SizedBox(height: 10),
                  Text(
                    _s.tr('dedicatedTo'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.gold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...duaList.map((name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('🤲',
                                style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.text,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: c.goldTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _s.tr('close'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.gold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKhatamHistorySheet(BuildContext context, QuranGroup group, AppColors c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dc = AppColors.of(ctx);
        final history = group.khatamHistory.reversed.toList();
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: dc.card,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: dc.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _s.khatamHistoryTitle(history.length),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: dc.text,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(_s.tr('noKhatams'),
                      style: TextStyle(color: dc.subtext)),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: history.length,
                    separatorBuilder: (context, i) => Divider(color: dc.border),
                    itemBuilder: (_, i) {
                      final record = history[i];
                      final date = record.completedAt;
                      final dateStr =
                          '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: dc.goldTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _s.khatamNumber(record.number),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: dc.gold,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(dateStr,
                                    style: TextStyle(
                                        fontSize: 12, color: dc.subtext)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: record.entries.map((e) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: dc.surfaceAlt,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: dc.border),
                                  ),
                                  child: Text(
                                    '${_s.myJuzLabel(e.juz)} · ${e.name.split(' ').first}',
                                    style: TextStyle(
                                        fontSize: 11, color: dc.text),
                                  ),
                                );
                              }).toList(),
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
      },
    );
  }

  void _showMembersSheet(BuildContext context, QuranGroup group, AppColors c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _s.membersTitle(group.allMembers.length),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _s.tr('memberHint'),
              style: TextStyle(fontSize: 12, color: c.subtext),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: group.allMembers.length,
                separatorBuilder: (context, i) => Divider(color: c.border, height: 1),
                itemBuilder: (_, i) {
                  final m = group.allMembers[i];
                  final isAdminMember = m.role == 'admin';
                  String status;
                  Color statusColor;
                  if (m.juz != null && m.juzCompleted) {
                    status = _s.juzDone(m.juz!);
                    statusColor = c.gold;
                  } else if (m.juz != null) {
                    status = _s.juzInProgress(m.juz!);
                    statusColor = c.green;
                  } else {
                    status = _s.tr('noJuzAssigned');
                    statusColor = c.subtext;
                  }
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: isAdminMember ? c.goldTint : c.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isAdminMember
                            ? Icon(Icons.shield_rounded, size: 18, color: c.gold)
                            : Text(
                                m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: c.subtext),
                              ),
                      ),
                    ),
                    title: Text(
                      m.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.text),
                    ),
                    subtitle: Text(
                      status,
                      style: TextStyle(fontSize: 12, color: statusColor),
                    ),
                    trailing: isAdminMember
                        ? null
                        : GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (dCtx) => AlertDialog(
                                  backgroundColor: c.card,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Text(_s.tr('removeMember'),
                                      style: TextStyle(color: c.text)),
                                  content: Text(
                                      _s.removeMemberConfirm(m.name),
                                      style: TextStyle(color: c.subtext)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, false),
                                      child: Text(_s.tr('no'),
                                          style:
                                              TextStyle(color: c.subtext)),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dCtx, true),
                                      child: Text(_s.tr('remove'),
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await GroupService.removeMember(
                                    group.id, m.uid);
                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.person_remove_rounded,
                                  size: 16,
                                  color: Colors.red.withValues(alpha: 0.7)),
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDuaListDialog(BuildContext context, QuranGroup group) {
    final c = AppColors.of(context);
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _s.tr('duaListTitle'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _s.tr('duaListSubtitle'),
                    style: TextStyle(fontSize: 12, color: c.subtext),
                  ),
                  const SizedBox(height: 14),

                  // Current list
                  if (group.duaList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _s.tr('emptyDuaList'),
                        style: TextStyle(fontSize: 13, color: c.subtext),
                      ),
                    )
                  else
                    ...group.duaList.map((name) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: c.goldTint,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text('🤲',
                                      style: TextStyle(fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: c.text),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await GroupService.removeDuaName(
                                      group.id, name);
                                  if (ctx.mounted) Navigator.pop(ctx);
                                },
                                child: Icon(Icons.close_rounded,
                                    size: 18, color: c.subtext),
                              ),
                            ],
                          ),
                        )),

                  const SizedBox(height: 8),
                  // Add name row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.border),
                          ),
                          child: TextField(
                            controller: controller,
                            style: TextStyle(fontSize: 14, color: c.text),
                            decoration: InputDecoration(
                              hintText: _s.tr('enterNameHint'),
                              hintStyle: TextStyle(
                                  fontSize: 13, color: c.subtext),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) return;
                          await GroupService.addDuaName(group.id, name);
                          controller.clear();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Container(
                          height: 44,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: c.gold,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _s.tr('add'),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showKhatamDialog(BuildContext context, AppColors c, int number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _s.tr('khatamDone'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: c.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _s.khatamGroupSimple(number),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: c.subtext),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: c.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _s.tr('okay'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Optimistic helpers ────────────────────────────────────────────────────

  QuranGroup _rebuildGroup(QuranGroup g, Map<int, GroupMember> juzAssignments,
      {Map<int, GroupMember>? nextRoundAssignments}) {
    return QuranGroup(
      id: g.id,
      name: g.name,
      createdBy: g.createdBy,
      inviteCode: g.inviteCode,
      juzAssignments: juzAssignments,
      nextRoundAssignments: nextRoundAssignments ?? g.nextRoundAssignments,
      memberUids: g.memberUids,
      khatamCount: g.khatamCount,
      khatamHistory: g.khatamHistory,
      duaList: g.duaList,
      allMembers: g.allMembers,
      myKhatamCount: g.myKhatamCount,
    );
  }

  void _applyNextJuzCompleted(QuranGroup g, int juz, String uid, String name) {
    final nextM = Map<int, GroupMember>.from(g.nextRoundAssignments);
    nextM.remove(juz);
    final currM = Map<int, GroupMember>.from(g.juzAssignments);
    currM[juz] = GroupMember(uid: uid, name: name, completed: true, completedAt: DateTime.now());
    setState(() => _optimisticGroup = _rebuildGroup(g, currM, nextRoundAssignments: nextM));
  }

  void _applyNextJuzAdded(QuranGroup g, int juz, String uid, String name) {
    final m = Map<int, GroupMember>.from(g.nextRoundAssignments);
    m[juz] = GroupMember(uid: uid, name: name);
    setState(() =>
        _optimisticGroup = _rebuildGroup(g, g.juzAssignments, nextRoundAssignments: m));
  }

  void _applyNextJuzRemoved(QuranGroup g, int juz) {
    final m = Map<int, GroupMember>.from(g.nextRoundAssignments);
    m.remove(juz);
    setState(() =>
        _optimisticGroup = _rebuildGroup(g, g.juzAssignments, nextRoundAssignments: m));
  }

  void _applyJuzAdded(QuranGroup g, int juz, String uid, String name) {
    final m = Map<int, GroupMember>.from(g.juzAssignments);
    m[juz] = GroupMember(uid: uid, name: name);
    setState(() => _optimisticGroup = _rebuildGroup(g, m));
  }

  void _applyJuzRemoved(QuranGroup g, int juz) {
    final m = Map<int, GroupMember>.from(g.juzAssignments);
    m.remove(juz);
    setState(() => _optimisticGroup = _rebuildGroup(g, m));
  }

  void _applyJuzCompleted(QuranGroup g, int juz) {
    final m = Map<int, GroupMember>.from(g.juzAssignments);
    final existing = m[juz];
    if (existing != null) {
      m[juz] = GroupMember(
        uid: existing.uid,
        name: existing.name,
        completed: true,
        takenAt: existing.takenAt,
        completedAt: DateTime.now(),
      );
    }
    setState(() => _optimisticGroup = _rebuildGroup(g, m));
  }

  void _applyJuzUncompleted(QuranGroup g, int juz) {
    final m = Map<int, GroupMember>.from(g.juzAssignments);
    final existing = m[juz];
    if (existing != null) {
      m[juz] = GroupMember(
        uid: existing.uid,
        name: existing.name,
        completed: false,
        takenAt: existing.takenAt,
      );
    }
    setState(() => _optimisticGroup = _rebuildGroup(g, m));
  }

  String _memberName(BuildContext context) {
    final o = context.read<OnboardingProvider>();
    final first = o.firstName.trim();
    final last = o.lastName.trim();
    if (first.isNotEmpty) return last.isNotEmpty ? '$first $last' : first;
    return FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        _s.tr('userFallback');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final c = AppColors.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: c.bg,
      body: StreamBuilder<QuranGroup?>(
        stream: _groupStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              _optimisticGroup == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final group = _optimisticGroup ?? snap.data;
          if (group == null) {
            return Center(
              child: Text(_s.tr('groupNotFound'),
                  style: TextStyle(color: c.subtext, fontSize: 15)),
            );
          }

          final isAdmin = uid == group.createdBy;
          final myJuz = group.myJuz(uid);
          final myNextJuz = group.myNextRoundJuz(uid);

          return CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: c.primary,
                  padding: const EdgeInsets.fromLTRB(20, 54, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_ios,
                                color: Colors.white54, size: 14),
                            const SizedBox(width: 4),
                            Text(_s.tr('back'),
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.white54)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield_rounded,
                                      color: Colors.amber, size: 13),
                                  const SizedBox(width: 4),
                                  Text(_s.tr('admin'),
                                      style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showMembersSheet(context, group, c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.people_rounded,
                                        size: 13, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Text(
                                      _s.membersTitle(group.allMembers.length),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _InfoChip(
                            label: _s.assignedJuz(group.assignedCount, 30),
                            icon: Icons.people_outline_rounded,
                          ),
                          const SizedBox(width: 8),
                          if (group.completedCount > 0)
                            _InfoChip(
                              label: _s.completedJuz(group.completedCount),
                              icon: Icons.check_circle_outline,
                            ),
                          const SizedBox(width: 8),
                          if (group.khatamCount > 0)
                            _InfoChip(
                              label: _s.khatamCount(group.khatamCount),
                              icon: Icons.auto_stories_rounded,
                            ),
                        ],
                      ),

                      // ── Invite code — admin only ─────────────────────
                      if (isAdmin) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: group.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    _s.codeCopied(group.inviteCode)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.lock_outline_rounded,
                                    color: Colors.white70, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _s.inviteCodeLabel(group.inviteCode),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy_outlined,
                                    color: Colors.white54, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── My juz banner ────────────────────────────────────────
              // myJuz is non-null only when there is an active (not yet done) juz.
              if (myJuz != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.greenTint,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: c.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_rounded,
                            color: c.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _s.myJuzBanner(myJuz),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.green,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () async {
                            _applyJuzCompleted(group, myJuz);
                            _pendingOptimistic++;
                            try {
                              final isKhatam = await GroupService.markJuzComplete(
                                  group.id, myJuz, _memberName(context), true);
                              await GroupService.recordJuzRead(myJuz);
                              if (isKhatam && mounted) {
                                _justTriggeredKhatam = true;
                                final promoted = <int, GroupMember>{};
                                for (final e in group.nextRoundAssignments.entries) {
                                  promoted[e.key] =
                                      GroupMember(uid: e.value.uid, name: e.value.name);
                                }
                                setState(() => _optimisticGroup = QuranGroup(
                                      id: group.id,
                                      name: group.name,
                                      createdBy: group.createdBy,
                                      inviteCode: group.inviteCode,
                                      juzAssignments: promoted,
                                      nextRoundAssignments: {},
                                      memberUids: group.memberUids,
                                      khatamCount: group.khatamCount + 1,
                                      khatamHistory: group.khatamHistory,
                                      duaList: group.duaList,
                                      allMembers: group.allMembers,
                                      myKhatamCount: group.myKhatamCount + 1,
                                    ));
                                if (context.mounted) {
                                  if (isAdmin) {
                                    _showAdminKhatamNotification(
                                        context, group.khatamCount + 1,
                                        duaList: group.duaList);
                                  } else {
                                    _showKhatamDialog(
                                        context, c, group.khatamCount + 1);
                                  }
                                }
                              }
                            } finally {
                              if (mounted) _pendingOptimistic--;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: c.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _s.tr('doneCheck'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () async {
                            _applyJuzRemoved(group, myJuz);
                            _pendingOptimistic++;
                            try {
                              await GroupService.unassignJuz(group.id, myJuz);
                            } finally {
                              if (mounted) _pendingOptimistic--;
                            }
                          },
                          child: Text(_s.tr('unassign'),
                              style: TextStyle(
                                  fontSize: 12, color: c.subtext)),
                        ),
                      ],
                    ),
                  ),
                ),


              // ── Grid label ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            myJuz == null ? _s.tr('selectJuzHint') : _s.tr('thirtyJuz'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: c.subtext),
                          ),
                          if (!isAdmin) ...[
                            const Spacer(),
                            Row(
                              children: [
                                _LegendDot(color: c.green, label: _s.tr('mine')),
                                const SizedBox(width: 8),
                                _LegendDot(color: c.blue, label: _s.tr('friendLabel')),
                                const SizedBox(width: 8),
                                _LegendDot(color: c.subtext, label: _s.tr('taken')),
                                const SizedBox(width: 8),
                                _LegendDot(color: c.gold, label: _s.tr('complete')),
                              ],
                            ),
                          ],
                          if (isAdmin) const Spacer(),
                          if (isAdmin) ...[
                            GestureDetector(
                              onTap: () =>
                                  _showDuaListDialog(context, group),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: c.blueTint,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: c.blue.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_outline_rounded,
                                        size: 13, color: c.blue),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_s.tr('listLabel')}${group.duaList.isNotEmpty ? ' (${group.duaList.length})' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: c.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showDuaDialog(context, duaList: group.duaList),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: c.goldTint,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: c.gold.withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🤲',
                                        style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _s.tr('dua'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: c.gold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── 30 Juz grid ──────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final juz = i + 1;
                      final member = group.juzAssignments[juz];
                      final isMe = member?.uid == uid;
                      final isEmpty = member == null;
                      final isDone = member?.completed ?? false;

                      final isFriend =
                          !isMe &&
                          member != null &&
                          _friendUids.contains(member.uid);

                      // Admin sees everyone; regular members see self + friends only
                      final canSeeWho = isAdmin || isMe || isFriend;

                      Color bg;
                      Color textColor;
                      Color borderColor;

                      if (isMe && isDone) {
                        bg = c.gold;
                        textColor = Colors.white;
                        borderColor = c.gold;
                      } else if (isMe) {
                        bg = c.primary;
                        textColor = Colors.white;
                        borderColor = c.primary;
                      } else if (!isEmpty && isDone && canSeeWho) {
                        bg = c.goldTint;
                        textColor = c.gold;
                        borderColor = c.gold.withValues(alpha: 0.3);
                      } else if (!isEmpty && isDone) {
                        // Completed by stranger — same gold as friends/admin
                        bg = c.goldTint;
                        textColor = c.gold;
                        borderColor = c.gold.withValues(alpha: 0.3);
                      } else if (!isEmpty && isFriend) {
                        bg = c.blueTint;
                        textColor = c.blue;
                        borderColor = c.blue.withValues(alpha: 0.3);
                      } else if (!isEmpty && isAdmin) {
                        bg = c.blueTint;
                        textColor = c.blue;
                        borderColor = c.blue.withValues(alpha: 0.3);
                      } else if (!isEmpty) {
                        // Taken by stranger (non-admin view)
                        bg = c.surfaceAlt;
                        textColor = c.subtext;
                        borderColor = c.border;
                      } else {
                        bg = c.card;
                        textColor = c.subtext;
                        borderColor = c.border;
                      }

                      return GestureDetector(
                        onTap: () async {
                          if (isMe && isDone) {
                            final memberName = _memberName(context);
                            final messenger = ScaffoldMessenger.of(context);
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) {
                                final c = AppColors.of(ctx);
                                return AlertDialog(
                                  backgroundColor: c.card,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  title: Text(_s.tr('unmarkJuzTitle'),
                                      style: TextStyle(color: c.text, fontSize: 16)),
                                  content: Text(
                                    _s.unmarkJuzConfirm(juz),
                                    style: TextStyle(color: c.subtext),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: Text(_s.tr('no'), style: TextStyle(color: c.subtext)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: Text(_s.tr('yes'), style: TextStyle(color: c.gold, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (confirm == true && mounted) {
                              _applyJuzUncompleted(group, juz);
                              _pendingOptimistic++;
                              try {
                                await GroupService.markJuzComplete(group.id, juz, memberName, false);
                              } catch (_) {
                                if (mounted) setState(() => _optimisticGroup = null);
                                messenger.showSnackBar(
                                  SnackBar(content: Text(_s.tr('errorRetry'))),
                                );
                              } finally {
                                if (mounted) _pendingOptimistic--;
                              }
                            }
                          } else if (isMe && !isDone) {
                            _applyJuzRemoved(group, juz);
                            _pendingOptimistic++;
                            try {
                              await GroupService.unassignJuz(group.id, juz);
                            } finally {
                              if (mounted) _pendingOptimistic--;
                            }
                          } else if (isEmpty && myJuz == null) {
                            _applyJuzAdded(group, juz, uid, _memberName(context));
                            _pendingOptimistic++;
                            try {
                              await GroupService.assignJuz(group.id, juz, _memberName(context));
                            } finally {
                              if (mounted) _pendingOptimistic--;
                            }
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top: number or check icon
                              if (isDone && isMe)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Colors.white,
                                )
                              else if (isDone && canSeeWho)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: c.gold,
                                )
                              else if (isDone)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: c.gold,
                                )
                              else
                                Text(
                                  '$juz',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),

                              // Bottom: name label or taken indicator
                              if (member != null) ...[
                                const SizedBox(height: 3),

                                if (canSeeWho)
                                  Text(
                                    member.name.split(' ').first,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isMe
                                          ? Colors.white70
                                          : isDone
                                              ? c.gold
                                              : c.blue,
                                    ),
                                  )
                                else
                                  Icon(
                                    isDone
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.person_outline_rounded,
                                    size: 10,
                                    color: isDone
                                        ? c.gold
                                        : c.subtext,
                                  ),
                              ] else
                                Icon(
                                  Icons.add,
                                  size: 14,
                                  color: myJuz == null
                                      ? c.subtext
                                      : c.border,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: 30,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.9,
                  ),
                ),
              ),

              // ── Next-round juz selection — only when current round is full ──
              if (group.isComplete) SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: c.border),
                        const SizedBox(height: 12),
                        Text(
                          _s.tr('nextRound'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          myNextJuz == null
                              ? _s.tr('selectJuzHint2')
                              : _s.juzSelectedLabel(myNextJuz),
                          style: TextStyle(fontSize: 12, color: c.subtext),
                        ),
                      ],
                    ),
                  ),
                ),
              if (group.isComplete) SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final juz = i + 1;
                        final nextMember = group.nextRoundAssignments[juz];
                        final isMyNext = nextMember?.uid == uid;
                        final isNextEmpty = nextMember == null;
                        final isFriendNext = !isMyNext &&
                            nextMember != null &&
                            _friendUids.contains(nextMember.uid);
                        final canSeeNextWho =
                            isAdmin || isMyNext || isFriendNext;

                        Color bg;
                        Color textColor;
                        Color borderColor;

                        if (isMyNext) {
                          bg = c.primary;
                          textColor = Colors.white;
                          borderColor = c.primary;
                        } else if (!isNextEmpty && (isAdmin || isFriendNext)) {
                          bg = c.blueTint;
                          textColor = c.blue;
                          borderColor = c.blue.withValues(alpha: 0.3);
                        } else if (!isNextEmpty) {
                          bg = c.surfaceAlt;
                          textColor = c.subtext;
                          borderColor = c.border;
                        } else {
                          bg = c.card;
                          textColor = c.subtext;
                          borderColor = c.border;
                        }

                        return GestureDetector(
                          onTap: () async {
                            if (isMyNext) {
                              final name = _memberName(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final choice = await showDialog<String>(
                                context: context,
                                builder: (ctx) {
                                  final dc = AppColors.of(ctx);
                                  return AlertDialog(
                                    backgroundColor: dc.card,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16)),
                                    title: Text('$juz-жүз',
                                        style: TextStyle(color: dc.text, fontSize: 16)),
                                    content: Text(_s.tr('finishQ'),
                                        style: TextStyle(color: dc.subtext)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, 'unassign'),
                                        child: Text(_s.tr('unassign'), style: TextStyle(color: dc.subtext)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, null),
                                        child: Text(_s.tr('no'), style: TextStyle(color: dc.subtext)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, 'done'),
                                        child: Text(_s.tr('doneCheck'),
                                            style: TextStyle(
                                                color: dc.gold,
                                                fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (!mounted) return;
                              if (choice == 'done') {
                                _applyNextJuzCompleted(group, juz, uid, name);
                                _pendingOptimistic++;
                                try {
                                  final isKhatam = await GroupService.completeNextRoundJuz(group.id);
                                  await GroupService.recordJuzRead(juz);
                                  if (isKhatam && mounted) {
                                    _justTriggeredKhatam = true;
                                    final promoted = <int, GroupMember>{};
                                    for (final e in group.nextRoundAssignments.entries) {
                                      if (e.key != juz) {
                                        promoted[e.key] = GroupMember(uid: e.value.uid, name: e.value.name);
                                      }
                                    }
                                    setState(() => _optimisticGroup = QuranGroup(
                                          id: group.id,
                                          name: group.name,
                                          createdBy: group.createdBy,
                                          inviteCode: group.inviteCode,
                                          juzAssignments: promoted,
                                          nextRoundAssignments: {},
                                          memberUids: group.memberUids,
                                          khatamCount: group.khatamCount + 1,
                                          khatamHistory: group.khatamHistory,
                                          duaList: group.duaList,
                                          allMembers: group.allMembers,
                                          myKhatamCount: group.myKhatamCount + 1,
                                        ));
                                    if (context.mounted) {
                                      if (isAdmin) {
                                        _showAdminKhatamNotification(
                                            context, group.khatamCount + 1,
                                            duaList: group.duaList);
                                      } else {
                                        _showKhatamDialog(context, c, group.khatamCount + 1);
                                      }
                                    }
                                  }
                                } catch (_) {
                                  if (mounted) setState(() => _optimisticGroup = null);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(_s.tr('errorRetry'))),
                                  );
                                } finally {
                                  if (mounted) _pendingOptimistic--;
                                }
                              } else if (choice == 'unassign') {
                                _applyNextJuzRemoved(group, juz);
                                _pendingOptimistic++;
                                try {
                                  await GroupService.unassignFromNextRound(group.id, juz);
                                } finally {
                                  if (mounted) _pendingOptimistic--;
                                }
                              }
                            } else if (isNextEmpty && myNextJuz == null) {
                              final memberName = _memberName(context);
                              final messenger = ScaffoldMessenger.of(context);
                              _applyNextJuzAdded(group, juz, uid, memberName);
                              _pendingOptimistic++;
                              try {
                                await GroupService.assignToNextRound(group.id, juz, memberName);
                              } catch (_) {
                                if (mounted) setState(() => _optimisticGroup = null);
                                messenger.showSnackBar(
                                  SnackBar(content: Text(_s.tr('juzReserved'))),
                                );
                              } finally {
                                if (mounted) _pendingOptimistic--;
                              }
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$juz',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                                if (nextMember != null) ...[
                                  const SizedBox(height: 3),
                                  if (canSeeNextWho)
                                    Text(
                                      nextMember.name.split(' ').first,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isMyNext
                                            ? Colors.white70
                                            : c.blue,
                                      ),
                                    )
                                  else
                                    Icon(Icons.person_outline_rounded,
                                        size: 10, color: c.subtext),
                                ] else
                                  Icon(
                                    Icons.add,
                                    size: 14,
                                    color: myNextJuz == null
                                        ? c.subtext
                                        : c.border,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: 30,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.9,
                    ),
                  ),
                ),

              // ── Leave / Delete group ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                  child: Column(
                    children: [
                      if (isAdmin) ...[
                        GestureDetector(
                          onTap: () => _showKhatamHistorySheet(context, group, c),
                          child: Text(
                            _s.tr('khatamHistory'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: c.subtext),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (isAdmin)
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: c.card,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: Text(_s.tr('deleteGroup'),
                                    style: TextStyle(color: c.text)),
                                content: Text(
                                    _s.deleteGroupConfirm(group.name),
                                    style: TextStyle(color: c.subtext)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text(_s.tr('no'),
                                        style: TextStyle(color: c.subtext)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(_s.tr('delete'),
                                        style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await GroupService.deleteGroup(group.id);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                          child: Text(
                            _s.tr('deleteGroup'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.withValues(alpha: 0.7)),
                          ),
                        ),
                      if (isAdmin) const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: c.card,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: Text(_s.tr('leaveGroup'),
                                  style: TextStyle(color: c.text)),
                              content: Text(
                                  _s.leaveGroupConfirm(group.name),
                                  style: TextStyle(color: c.subtext)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(_s.tr('no'),
                                      style: TextStyle(color: c.subtext)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text(_s.tr('leave'),
                                      style: const TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await GroupService.leaveGroup(group.id);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                        child: Text(
                          _s.tr('leaveGroup'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              color: c.subtext.withValues(alpha: 0.6)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
