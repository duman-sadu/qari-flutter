import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plan_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

class SurahSelectScreen extends StatefulWidget {
  final bool isReadMode;
  const SurahSelectScreen({super.key, this.isReadMode = false});

  @override
  State<SurahSelectScreen> createState() => _SurahSelectScreenState();
}

class _SurahSelectScreenState extends State<SurahSelectScreen> {
  LanguageProvider get _s => context.read<LanguageProvider>();

  late List<int> _selected;
  String _search = '';

  bool get _allSelected => _selected.length == surahNames.length;

  List<int> get _filteredIndices {
    if (_search.isEmpty) return List.generate(surahNames.length, (i) => i);
    final q = _search.toLowerCase();
    return List.generate(surahNames.length, (i) => i)
        .where((i) =>
            surahNames[i].toLowerCase().contains(q) ||
            surahNamesRu[i].toLowerCase().contains(q) ||
            '${i + 1}'.contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    final plan = context.read<PlanProvider>();
    _selected = List.from(
      widget.isReadMode ? plan.selectedReadSurahs : plan.selectedSurahs,
    );
  }

  Future<void> _toggle(int index) async {
    if (_selected.contains(index)) {
      setState(() => _selected.remove(index));
      return;
    }

    // Warn in learn mode if surah is already known or fully learned
    if (!widget.isReadMode) {
      final plan = context.read<PlanProvider>();
      final onboarding = context.read<OnboardingProvider>();
      final isKnown = onboarding.knownSurahs.contains(index);
      final isLearned =
          plan.surahLearnedCount(index) >= ayahCounts[index];

      if (isKnown || isLearned) {
        final c = AppColors.of(context);
        final name = (_s.isRu ? surahNamesRu : surahNames)[index];
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: c.card,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚠️',
                      style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 14),
                  Text(
                    _s.surahWarnTitle(isLearned),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: c.text),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _s.surahWarnBody(name, isLearned),
                    style:
                        TextStyle(fontSize: 14, color: c.subtext, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: c.surfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_s.tr('no'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: c.text)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_s.tr('yesAdd'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (confirmed != true) return;
      }
    }

    setState(() => _selected.add(index));
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected = [];
      } else {
        _selected = List.generate(surahNames.length, (i) => i);
      }
    });
  }

  Future<void> _save() async {
    final plan = context.read<PlanProvider>();
    if (widget.isReadMode) {
      await plan.setSelectedReadSurahs(_selected);
    } else {
      await plan.setSelectedSurahs(_selected);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final c = AppColors.of(context);
    final indices = _filteredIndices;

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
            decoration: BoxDecoration(color: c.primary),
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
                      Text(
                        _s.tr('back'),
                        style: const TextStyle(fontSize: 14, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _s.tr('selectSurah'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _s.selectedFraction(_selected.length, surahNames.length),
                  style: const TextStyle(fontSize: 13, color: Colors.white60),
                ),
              ],
            ),
          ),

          // ── Search + select all ──────────────────────────────────────
          Container(
            color: c.card,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: TextStyle(fontSize: 14, color: c.text),
                  decoration: InputDecoration(
                    hintText: _s.tr('search'),
                    hintStyle: TextStyle(color: c.subtext),
                    prefixIcon: Icon(Icons.search, color: c.subtext, size: 20),
                    filled: true,
                    fillColor: c.bg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _s.surahsFmt(indices.length),
                      style: TextStyle(fontSize: 13, color: c.subtext),
                    ),
                    GestureDetector(
                      onTap: _toggleAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: _allSelected ? c.greenTint : c.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _allSelected ? c.green : c.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _allSelected ? c.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _allSelected ? c.green : c.subtext,
                                  width: 1.5,
                                ),
                              ),
                              child: _allSelected
                                  ? const Icon(Icons.check,
                                      size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _allSelected
                                  ? _s.tr('deselectAll')
                                  : _s.tr('selectAll'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _allSelected ? c.green : c.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: c.border),

          // ── Surah list ───────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              itemCount: indices.length,
              itemBuilder: (_, i) {
                final index = indices[i];
                final isSelected = _selected.contains(index);
                return GestureDetector(
                  onTap: () => _toggle(index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? c.greenTint : c.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? c.green : c.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected ? c.green : c.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : c.subtext,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_s.isRu ? surahNamesRu : surahNames)[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? c.green : c.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${ayahCounts[index]} ${_s.tr('ayah')}',
                                style: TextStyle(fontSize: 12, color: c.subtext),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? c.green : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? c.green : c.border,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── Save FAB ─────────────────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selected.isNotEmpty ? _save : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              disabledBackgroundColor: c.primary.withValues(alpha: 0.35),
              elevation: 4,
              shadowColor: c.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _selected.isNotEmpty
                  ? _s.saveSurahsBtn(_selected.length)
                  : _s.tr('selectSurahsHint'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
