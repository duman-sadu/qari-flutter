import 'package:flutter/material.dart';
import '../services/group_service.dart';
import '../theme/app_colors.dart';

void showAdminKhatamNotification(BuildContext context, int number,
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
            'Хатым Мүбәрак!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: c.gold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Топ $number-ші рет Құранды толық хатым жасады!\n\nХатым дұғасын оқу — сүннет. Ол оқылған Құранның сауабын бекітеді.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.subtext, height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(ctx);
              showDuaDialog(context, duaList: duaList);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: c.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Хатым дұғасын ашу',
                textAlign: TextAlign.center,
                style: TextStyle(
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
              'Жабу',
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

void showDuaDialog(BuildContext context, {List<String> duaList = const []}) {
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
                'Хатым Дұғасы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: c.gold,
                ),
              ),
              const SizedBox(height: 6),
              Divider(color: c.gold.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
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
              Text(
                'Уа, Алла!\n'
                'Бізге Құран арқылы рақым ет.\n'
                'Оны бізге жол көрсетуші, нұр, туралық және мейірім ет.\n\n'
                'Уа, Алла!\n'
                'Ұмытқанымызды Құран арқылы есімізге сал,\n'
                'білмегенімізді үйрет.\n'
                'Күндіз-түні Құран оқуды нәсіп ет.\n'
                'Қиямет күні оны бізге айғақ ет, ей әлемдердің Раббысы!\n\n'
                'Уа, Алла!\n'
                'Дінімізді түзет, өйткені ол біздің қорғанымыз.\n'
                'Дүниемізді түзет, өйткені онда біздің тіршілігіміз бар.\n'
                'Ақыретімізді түзет, өйткені оған қайтамыз.\n\n'
                'Уа, Алла!\n'
                'Құранды жүректеріміздің көктемі,\n'
                'көкіректеріміздің нұры,\n'
                'қайғымыздың кетуі,\n'
                'уайымдарымыздың сейілуі ет.\n\n'
                'Алланың салауаты мен сәлемі\n'
                'Пайғамбарымыз Мұхаммедке (с.а.у.),\n'
                'оның отбасы мен сахабаларына болсын.\n'
                'Әмин.',
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
                  'Арналады:',
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
                          const Text('🤲', style: TextStyle(fontSize: 13)),
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
                    'Жабу',
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

void showMembersSheet(BuildContext context, QuranGroup group) {
  final c = AppColors.of(context);
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
            'Мүшелер (${group.allMembers.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Мүшені ұстап тұрып жою үшін басыңыз',
            style: TextStyle(fontSize: 12, color: c.subtext),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: group.allMembers.length,
              separatorBuilder: (_, _) => Divider(color: c.border, height: 1),
              itemBuilder: (_, i) {
                final m = group.allMembers[i];
                final isAdminMember = m.role == 'admin';
                String status;
                Color statusColor;
                if (m.juz != null && m.juzCompleted) {
                  status = '${m.juz}-жүз ✓';
                  statusColor = c.gold;
                } else if (m.juz != null) {
                  status = '${m.juz}-жүз оқуда';
                  statusColor = c.green;
                } else {
                  status = 'Жүз алмаған';
                  statusColor = c.subtext;
                }
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 38,
                    height: 38,
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
                                title: Text('Мүшені шығару',
                                    style: TextStyle(color: c.text)),
                                content: Text(
                                    '"${m.name}" топтан шығарасыз ба?',
                                    style: TextStyle(color: c.subtext)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dCtx, false),
                                    child: Text('Жоқ',
                                        style: TextStyle(color: c.subtext)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('Шығару',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await GroupService.removeMember(group.id, m.uid);
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

void showDuaListSheet(BuildContext context, QuranGroup group) {
  final c = AppColors.of(context);
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  'Хатымды кімдерге арнаймыз',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Дұғада аталатын есімдер тізімі',
                  style: TextStyle(fontSize: 12, color: c.subtext),
                ),
                const SizedBox(height: 14),
                if (group.duaList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Тізім бос. Төменде есім қосыңыз.',
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
                              child: const Center(
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
                            hintText: 'Есімді енгізіңіз...',
                            hintStyle:
                                TextStyle(fontSize: 13, color: c.subtext),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14),
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
                        child: const Center(
                          child: Text(
                            'Қосу',
                            style: TextStyle(
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

void showKhatamDialog(BuildContext context, int number) {
  final c = AppColors.of(context);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Хатым бітті!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: c.gold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Топ $number-ші рет Құранды хатым жасады!\nЖаңа жүздерді таңдауға болады.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: c.subtext),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: c.gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Жарайды',
                style: TextStyle(
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
