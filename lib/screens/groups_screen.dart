import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/group_service.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import 'group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  LanguageProvider get _s => context.read<LanguageProvider>();

  bool _signingIn = false;
  bool _khatamExpanded = true;
  List<Map<String, dynamic>> _deletedKhatams = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedKhatams();
  }

  Future<void> _loadDeletedKhatams() async {
    if (!GroupService.isLoggedIn) return;
    final data = await GroupService.getDeletedGroupKhatams();
    if (mounted) setState(() => _deletedKhatams = data);
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final result = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (result.user == null && result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
  }

  Future<void> _showCreateDialog(BuildContext context, AppColors c) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_s.tr('createGroup'), style: TextStyle(color: c.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: c.text),
          decoration: InputDecoration(
            hintText: _s.tr('groupName'),
            hintStyle: TextStyle(color: c.subtext),
            filled: true,
            fillColor: c.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.green),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_s.tr('cancel'), style: TextStyle(color: c.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.tr('create'), style: TextStyle(color: c.green,
                fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    await GroupService.createGroup(name);
  }

  Future<void> _showJoinDialog(BuildContext context, AppColors c) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_s.tr('joinGroup'), style: TextStyle(color: c.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: c.text, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: _s.tr('inviteCode'),
            hintStyle: TextStyle(color: c.subtext),
            filled: true,
            fillColor: c.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: c.green),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_s.tr('cancel'), style: TextStyle(color: c.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.tr('join'), style: TextStyle(color: c.green,
                fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final code = ctrl.text.trim();
    if (code.isEmpty) return;
    final group = await GroupService.joinByCode(code);
    if (!context.mounted) return;
    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_s.tr('groupNotFoundCode'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final c = AppColors.of(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;

        if (user == null) {
          return _buildLoginGate(c);
        }

        return _buildGroupsList(context, c, user.uid);
      },
    );
  }

  Widget _buildLoginGate(AppColors c) {
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Container(
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
                          style:
                              const TextStyle(fontSize: 14, color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _s.tr('groupsTitle'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c.blueTint,
                      ),
                      child: Icon(Icons.groups_rounded,
                          size: 44, color: c.blue),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _s.tr('signInWithGoogleBtn'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _s.tr('signInForGroups'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: c.subtext, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _signingIn ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _signingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🔵',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Text(
                                    _s.tr('signInGoogle'),
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList(BuildContext context, AppColors c, String uid) {
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // Header
          Container(
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
                          style: const TextStyle(fontSize: 14, color: Colors.white54)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _s.tr('groupsTitle'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _s.tr('readingTogether'),
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showCreateDialog(context, c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '+ ${_s.tr('createGroup')}',
                              style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showJoinDialog(context, c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: Text(
                              _s.tr('joinGroup'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
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

          // Group list
          Expanded(
            child: StreamBuilder<List<QuranGroup>>(
              stream: GroupService.myGroupsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final groups = snap.data ?? [];
                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_outlined,
                            size: 56, color: c.border),
                        const SizedBox(height: 12),
                        Text(
                          _s.tr('noGroups'),
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: c.subtext),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _s.tr('noGroupsDesc'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: c.subtext),
                        ),
                      ],
                    ),
                  );
                }

                final khatamGroups =
                    groups.where((g) => g.myKhatamCount > 0).toList();
                final activeTotal = khatamGroups.fold<int>(
                    0, (s, g) => s + g.myKhatamCount);
                final deletedTotal = _deletedKhatams.fold<int>(
                    0, (s, e) => s + ((e['count'] as num?)?.toInt() ?? 0));
                final totalKhatams = activeTotal + deletedTotal;
                final hasKhatams =
                    khatamGroups.isNotEmpty || _deletedKhatams.isNotEmpty;

                return Column(
                  children: [
                    if (hasKhatams)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: c.goldTint,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: c.gold.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row — always visible
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                                child: Row(
                                  children: [
                                    const Text('🕌',
                                        style: TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _s.tr('myKhatams'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: c.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: c.gold,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$totalKhatams',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _khatamExpanded = !_khatamExpanded),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: AnimatedRotation(
                                          turns: _khatamExpanded ? 0 : 0.5,
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(Icons.expand_less,
                                              color: c.gold, size: 20),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Collapsible rows
                              AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeInOut,
                                child: _khatamExpanded
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                        child: Column(
                                          children: [
                                            // Active groups
                                            ...khatamGroups.map((g) => Padding(
                                              padding: const EdgeInsets.only(bottom: 4),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      g.name,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: c.text,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${g.myKhatamCount}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: c.gold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  GestureDetector(
                                                    onTap: () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) => AlertDialog(
                                                          backgroundColor: c.card,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16)),
                                                          title: Text(_s.tr('resetKhatams'),
                                                              style: TextStyle(color: c.text, fontSize: 15)),
                                                          content: Text(
                                                            _s.resetKhatamsConfirm(g.name),
                                                            style: TextStyle(color: c.subtext, fontSize: 13),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx, false),
                                                              child: Text(_s.tr('cancel'),
                                                                  style: TextStyle(color: c.subtext)),
                                                            ),
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(ctx, true),
                                                              child: Text(_s.tr('yes'),
                                                                  style: const TextStyle(
                                                                      color: Colors.redAccent,
                                                                      fontWeight: FontWeight.w700)),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        await GroupService.resetMyKhatams(g.id);
                                                      }
                                                    },
                                                    child: Icon(Icons.refresh,
                                                        size: 16, color: c.subtext),
                                                  ),
                                                ],
                                              ),
                                            )),
                                            // Deleted groups (read-only, grayed)
                                            ..._deletedKhatams.map((e) {
                                              final name = e['groupName']?.toString() ?? '';
                                              final count = (e['count'] as num?)?.toInt() ?? 0;
                                              return Padding(
                                                padding: const EdgeInsets.only(bottom: 4),
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline,
                                                        size: 13, color: c.subtext),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w500,
                                                          color: c.subtext,
                                                          decoration: TextDecoration.lineThrough,
                                                          decorationColor: c.subtext,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Text(
                                                      '$count',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w600,
                                                        color: c.subtext,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    GestureDetector(
                                                      onTap: () async {
                                                        final messenger = ScaffoldMessenger.of(context);
                                                        final isRu = _s.isRu;
                                                        final confirm = await showDialog<bool>(
                                                          context: context,
                                                          builder: (ctx) => AlertDialog(
                                                            backgroundColor: c.card,
                                                            shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(16)),
                                                            title: Text(_s.tr('resetKhatams'),
                                                                style: TextStyle(color: c.text, fontSize: 15)),
                                                            content: Text(
                                                              _s.resetKhatamsConfirm(name),
                                                              style: TextStyle(color: c.subtext, fontSize: 13),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(ctx, false),
                                                                child: Text(_s.tr('cancel'),
                                                                    style: TextStyle(color: c.subtext)),
                                                              ),
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(ctx, true),
                                                                child: Text(_s.tr('yes'),
                                                                    style: const TextStyle(
                                                                        color: Colors.redAccent,
                                                                        fontWeight: FontWeight.w700)),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                        if (confirm == true) {
                                                          final ok = await GroupService.clearDeletedGroupKhatam(name);
                                                          if (ok) {
                                                            _loadDeletedKhatams();
                                                          } else if (mounted) {
                                                            messenger.showSnackBar(
                                                              SnackBar(content: Text(isRu ? 'Ошибка сброса' : 'Сброс қатесі')),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      child: Icon(Icons.refresh,
                                                          size: 16, color: c.subtext),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                            16, hasKhatams ? 12 : 16, 16, 32),
                        itemCount: groups.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    final myJuz = g.myJuz(uid);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(groupId: g.id),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c.greenTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(Icons.groups_rounded,
                                    color: c.green, size: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: c.text,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      _ProgressPill(
                                          assigned: g.assignedCount,
                                          complete: g.isComplete,
                                          c: c),
                                      if (myJuz != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: c.greenTint,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _s.myJuzLabel(myJuz),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: c.green,
                                            ),
                                          ),
                                        ),
                                      if (g.myKhatamCount > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: c.goldTint,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _s.khatamCount(g.myKhatamCount),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: c.gold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                color: c.subtext, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final int assigned;
  final bool complete;
  final AppColors c;
  const _ProgressPill(
      {required this.assigned, required this.complete, required this.c});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: complete ? c.greenTint : c.blueTint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline
                : Icons.people_outline_rounded,
            size: 11,
            color: complete ? c.green : c.blue,
          ),
          const SizedBox(width: 4),
          Text(
            complete ? s.tr('fullGroup') : s.juzProgress(assigned),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: complete ? c.green : c.blue,
            ),
          ),
        ],
      ),
    );
  }
}
