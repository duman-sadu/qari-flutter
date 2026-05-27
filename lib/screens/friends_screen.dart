import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/friend_service.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import 'qr_scanner_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  LanguageProvider get _s => context.read<LanguageProvider>();

  bool _signingIn = false;
  String _myCode = '';

  @override
  void initState() {
    super.initState();
    _loadMyCode();
    FriendService.refreshFriendSnapshots();
    _processPendingRequests();
    _publishMyStats();
  }

  Future<void> _publishMyStats() async {
    // Ensure own /userStats/{uid} doc exists and is up to date.
    // The plan_provider sync handles streak/learnedCount on every study action,
    // but we trigger once on open in case the doc was never created.
    await FriendService.publishMyStats();
  }

  Future<void> _processPendingRequests() async {
    final newFriends = await FriendService.processPendingRequests();
    if (!mounted || newFriends.isEmpty) return;
    for (final friend in newFriends) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_s.addedYouMsg(friend.name)),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _loadMyCode() async {
    final code = await FriendService.getOrCreateMyCode();
    if (mounted) setState(() => _myCode = code);
  }

  Future<void> _signIn() async {
    setState(() => _signingIn = true);
    final result = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _signingIn = false);
    if (result.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
    } else if (result.user != null) {
      _loadMyCode();
    }
  }

  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (code == null || !mounted) return;
    final result = await FriendService.addFriendByCode(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success
          ? _s.friendAddedMsg(result.profile?.name ?? _s.tr('friendLabel'))
          : (result.error ?? _s.tr('error'))),
    ));
  }

  Future<void> _shareCode() async {
    if (_myCode.isEmpty) return;
    await Share.share(_s.shareCodeMsg(_myCode));
  }

  Future<void> _showAddDialog(AppColors c) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_s.tr('addFriend'), style: TextStyle(color: c.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(color: c.text, letterSpacing: 2),
          decoration: InputDecoration(
            hintText: _s.tr('friendCode'),
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
            child: Text(_s.tr('add'),
                style: TextStyle(
                    color: c.green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final code = ctrl.text.trim();
    if (code.isEmpty) return;

    final result = await FriendService.addFriendByCode(code);
    if (!mounted) return;
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_s.friendAddedMsg(result.profile?.name ?? _s.tr('friendLabel'))),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? _s.tr('error'))),
      );
    }
  }

  Future<void> _confirmRemove(AppColors c, FriendProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_s.tr('removeFriendTitle'), style: TextStyle(color: c.text)),
        content: Text(_s.removeFriendConfirm(friend.name),
            style: TextStyle(color: c.subtext)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_s.tr('no'), style: TextStyle(color: c.subtext)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_s.tr('remove'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await FriendService.removeFriend(friend.uid);
  }

  String _lastActiveLabel(String? dateStr) =>
      _s.friendActivityLabel(dateStr ?? '');

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) return _buildLoginGate(c);
        return _buildContent(c);
      },
    );
  }

  Widget _buildLoginGate(AppColors c) {
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _buildHeader(c, showActions: false),
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
                          shape: BoxShape.circle, color: c.greenTint),
                      child: Icon(Icons.people_rounded,
                          size: 44, color: c.green),
                    ),
                    const SizedBox(height: 20),
                    Text(_s.tr('signInWithGoogleBtn'),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: c.text)),
                    const SizedBox(height: 8),
                    Text(
                      _s.tr('signInForFriends'),
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: c.subtext, height: 1.5),
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
                                        Colors.white)),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('🔵',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Text(_s.tr('signInGoogle'),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
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

  Widget _buildContent(AppColors c) {
    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          _buildHeader(c, showActions: true),

          // ── My QR code card ────────────────────────────────────────
          if (_myCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    // QR code
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: QrImageView(
                        data: 'qari://friend/$_myCode',
                        version: QrVersions.auto,
                        size: 80,
                        eyeStyle: QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black,
                        ),
                        dataModuleStyle: QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_s.tr('myFriendCode'),
                              style: TextStyle(
                                  fontSize: 11, color: c.subtext)),
                          const SizedBox(height: 3),
                          Text(
                            _myCode,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: c.text,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Copy
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _myCode));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(_s.tr('copied')),
                                      duration: const Duration(seconds: 2),
                                    ));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: c.surfaceAlt,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.copy_outlined,
                                            size: 14, color: c.subtext),
                                        const SizedBox(width: 5),
                                        Text(_s.tr('copy'),
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: c.subtext)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Share (WhatsApp)
                              Expanded(
                                child: GestureDetector(
                                  onTap: _shareCode,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text('📲',
                                            style:
                                                TextStyle(fontSize: 13)),
                                        const SizedBox(width: 5),
                                        Text(_s.tr('send'),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF25D366),
                                            )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Friends list ───────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<FriendProfile>>(
              stream: FriendService.friendsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friends = snap.data ?? [];
                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 56, color: c.border),
                        const SizedBox(height: 12),
                        Text(_s.tr('noFriends'),
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: c.subtext)),
                        const SizedBox(height: 6),
                        Text(
                          _s.tr('noFriendsDesc'),
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: c.subtext),
                        ),
                      ],
                    ),
                  );
                }

                // Sort by streak descending
                final sorted = [...friends]
                  ..sort((a, b) => b.streak.compareTo(a.streak));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: sorted.length,
                  separatorBuilder: (context, _) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _FriendCard(
                    friend: sorted[i],
                    rank: i + 1,
                    lastActiveLabel:
                        _lastActiveLabel(sorted[i].lastStudyDate),
                    c: c,
                    onRemove: () => _confirmRemove(c, sorted[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors c, {required bool showActions}) {
    return Container(
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
                const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(_s.tr('back'),
                    style: const TextStyle(fontSize: 14, color: Colors.white54)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _s.tr('friendsTitle'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (showActions) ...[
                // Scan QR
                GestureDetector(
                  onTap: _scanQr,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Add by code (with pending request badge)
                StreamBuilder<int>(
                  stream: FriendService.pendingRequestCountStream(),
                  builder: (context, snap) {
                    final pending = snap.data ?? 0;
                    return GestureDetector(
                      onTap: () => _showAddDialog(c),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+ ${_s.tr('addFriend')}',
                              style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (pending > 0)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$pending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _s.tr('friendsAchievements'),
            style: const TextStyle(fontSize: 13, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final FriendProfile friend;
  final int rank;
  final String lastActiveLabel;
  final AppColors c;
  final VoidCallback onRemove;

  const _FriendCard({
    required this.friend,
    required this.rank,
    required this.lastActiveLabel,
    required this.c,
    required this.onRemove,
  });

  void _showDetails(BuildContext context, LanguageProvider s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final initials = friend.name.trim().split(' ')
            .where((w) => w.isNotEmpty)
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                        color: c.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              // Avatar + name
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: c.greenTint),
                child: Center(
                  child: Text(initials.isEmpty ? '?' : initials,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: c.green)),
                ),
              ),
              const SizedBox(height: 10),
              Text(friend.name,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.text)),
              const SizedBox(height: 4),
              Text(
                s.isRu ? '#$rank в списке друзей' : '#$rank достар тізімінде',
                style: TextStyle(fontSize: 12, color: c.subtext),
              ),
              const SizedBox(height: 20),
              Divider(color: c.border, height: 1),
              const SizedBox(height: 16),
              // Stats rows
              _FriendDetailRow(
                icon: '🔥',
                label: s.isRu ? 'Серия' : 'Жалғасу',
                value: s.streakDays(friend.streak),
                c: c,
              ),
              _FriendDetailRow(
                icon: '📖',
                label: s.isRu ? 'Выучено аятов' : 'Үйренген аяттар',
                value: s.learnedAyahs(friend.learnedCount),
                c: c,
              ),
              _FriendDetailRow(
                icon: '🕐',
                label: s.isRu ? 'Последняя активность' : 'Соңғы белсенділік',
                value: lastActiveLabel,
                c: c,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>();
    final initials = friend.name.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.greenTint,
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: c.green,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _StatBadge(
                        icon: '🔥',
                        label: s.streakDays(friend.streak),
                        c: c),
                    const SizedBox(width: 6),
                    _StatBadge(
                        icon: '📖',
                        label: s.learnedAyahs(friend.learnedCount),
                        c: c),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lastActiveLabel,
                  style: TextStyle(fontSize: 11, color: c.subtext),
                ),
              ],
            ),
          ),

          // Buttons
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _showDetails(context, s),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 6),
                  child: Icon(Icons.info_outline_rounded,
                      size: 20, color: c.primary.withValues(alpha: 0.7)),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.person_remove_outlined,
                      size: 18, color: c.subtext.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FriendDetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final AppColors c;
  const _FriendDetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.c});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 13, color: c.subtext))),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.text)),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String label;
  final AppColors c;
  const _StatBadge({required this.icon, required this.label, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.subtext)),
        ],
      ),
    );
  }
}
