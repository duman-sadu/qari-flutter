import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plan_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  AppColors get _c => AppColors.of(context);
  LanguageProvider get _s => context.read<LanguageProvider>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();

  String? _gender;
  bool _tajweed = false;
  bool _loadingApple = false;
  bool _appleConnected = false;
  String _studyMode = 'Жаттау';

  @override
  void initState() {
    super.initState();
    _prefillFromFirebase();
  }

  void _prefillFromFirebase() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final name = user.displayName ?? '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(' ');
      _firstNameController.text = parts.first;
      if (parts.length > 1) {
        _lastNameController.text = parts.sublist(1).join(' ');
      }
    }
  }

  final List<int> _knownSurahs = [];

  final List<String> surahNames = [
    'әл-Фатиха сүресі',
    'әл-Бақара сүресі',
    'Әли Имран сүресі',
    'ән-Ниса сүресі',
    'әл-Мәида сүресі',
    'әл-Әнғам сүресі',
    'әл-Ағраф сүресі',
    'әл-Әнфал сүресі',
    'әт-Тәубә сүресі',
    'Жүніс сүресі',
    'Һуд сүресі',
    'Юсуф сүресі',
    'әр-Рағд сүресі',
    'Ибраһим сүресі',
    'әл-Хижр сүресі',
    'ән-Нахл сүресі',
    'әл-Исра сүресі',
    'әл-Кәһф сүресі',
    'Мәриям сүресі',
    'Та-Һа сүресі',
    'әл-Әнбия сүресі',
    'әл-Хаж сүресі',
    'әл-Муминун сүресі',
    'ән-Нұр сүресі',
    'әл-Фурқан сүресі',
    'әш-Шуғара сүресі',
    'ән-Нәмл сүресі',
    'әл-Қасас сүресі',
    'әл-Анкабут сүресі',
    'әр-Рум сүресі',
    'Лұқман сүресі',
    'әс-Сәжде сүресі',
    'әл-Ахзаб сүресі',
    'Сәбә сүресі',
    'Фатыр сүресі',
    'Ясин сүресі',
    'әс-Саффат сүресі',
    'Сад сүресі',
    'әз-Зумар сүресі',
    'Ғафир сүресі',
    'Фуссилат сүресі',
    'әш-Шура сүресі',
    'әз-Зухруф сүресі',
    'әд-Духан сүресі',
    'әл-Жәсия сүресі',
    'әл-Ахқаф сүресі',
    'Мұхаммед сүресі',
    'әл-Фатх сүресі',
    'әл-Хужурат сүресі',
    'Қаф сүресі',
    'әз-Зәрият сүресі',
    'әт-Тур сүресі',
    'ән-Нәжм сүресі',
    'әл-Қамар сүресі',
    'әр-Рахман сүресі',
    'әл-Уақиға сүресі',
    'әл-Хадид сүресі',
    'әл-Мужадила сүресі',
    'әл-Хашр сүресі',
    'әл-Мумтахана сүресі',
    'әс-Сафф сүресі',
    'әл-Жұма сүресі',
    'әл-Мунафиқун сүресі',
    'әт-Тәғабун сүресі',
    'әт-Талақ сүресі',
    'әт-Тахрим сүресі',
    'әл-Мүлк сүресі',
    'әл-Қалам сүресі',
    'әл-Хаққа сүресі',
    'әл-Мағариж сүресі',
    'Нұх сүресі',
    'әл-Жин сүресі',
    'әл-Мүззәммил сүресі',
    'әл-Мүддәссир сүресі',
    'әл-Қияма сүресі',
    'әл-Инсан сүресі',
    'әл-Мурсалат сүресі',
    'ән-Нәбә сүресі',
    'ән-Назиғат сүресі',
    'Абаса сүресі',
    'әт-Такуир сүресі',
    'әл-Инфитар сүресі',
    'әл-Мутаффифин сүресі',
    'әл-Иншиқақ сүресі',
    'әл-Буруж сүресі',
    'әт-Тариқ сүресі',
    'әл-Ағла сүресі',
    'әл-Ғашия сүресі',
    'әл-Фәжр сүресі',
    'әл-Балад сүресі',
    'әш-Шәмс сүресі',
    'әл-Ләйл сүресі',
    'әд-Духа сүресі',
    'әш-Шарх сүресі',
    'әт-Тин сүресі',
    'әл-Алақ сүресі',
    'әл-Қадр сүресі',
    'әл-Бәййина сүресі',
    'әз-Залзала сүресі',
    'әл-Адият сүресі',
    'әл-Қариға сүресі',
    'әт-Такәсур сүресі',
    'әл-Асыр сүресі',
    'әл-Һумаза сүресі',
    'әл-Фил сүресі',
    'Құрайыш сүресі',
    'әл-Мағун сүресі',
    'әл-Кәусар сүресі',
    'әл-Кафирун сүресі',
    'ән-Наср сүресі',
    'әл-Мәсәд сүресі',
    'әл-Ықылас сүресі',
    'әл-Фәлақ сүресі',
    'ән-Нас сүресі',
  ];

  final List<String> surahNamesRu = [
    'аль-Фатиха',
    'аль-Бакара',
    'Аль Имран',
    'ан-Ниса',
    'аль-Маида',
    'аль-Анам',
    'аль-Араф',
    'аль-Анфаль',
    'ат-Тауба',
    'Юнус',
    'Худ',
    'Юсуф',
    'ар-Рад',
    'Ибрахим',
    'аль-Хиджр',
    'ан-Нахль',
    'аль-Исра',
    'аль-Кахф',
    'Марьям',
    'Та-Ха',
    'аль-Анбия',
    'аль-Хадж',
    'аль-Муминун',
    'ан-Нур',
    'аль-Фуркан',
    'аш-Шуара',
    'ан-Намль',
    'аль-Касас',
    'аль-Анкабут',
    'ар-Рум',
    'Лукман',
    'ас-Саджда',
    'аль-Ахзаб',
    'Саба',
    'Фатир',
    'Ясин',
    'ас-Саффат',
    'Сад',
    'аз-Зумар',
    'Гафир',
    'Фуссилат',
    'аш-Шура',
    'аз-Зухруф',
    'ад-Духан',
    'аль-Джасия',
    'аль-Ахкаф',
    'Мухаммад',
    'аль-Фатх',
    'аль-Худжурат',
    'Каф',
    'аз-Зарият',
    'ат-Тур',
    'ан-Наджм',
    'аль-Камар',
    'ар-Рахман',
    'аль-Вакиа',
    'аль-Хадид',
    'аль-Муджадала',
    'аль-Хашр',
    'аль-Мумтахана',
    'ас-Сафф',
    'аль-Джумуа',
    'аль-Мунафикун',
    'ат-Тагабун',
    'ат-Талак',
    'ат-Тахрим',
    'аль-Мульк',
    'аль-Калам',
    'аль-Хакка',
    'аль-Мааридж',
    'Нух',
    'аль-Джинн',
    'аль-Муззаммиль',
    'аль-Муддассир',
    'аль-Кияма',
    'аль-Инсан',
    'аль-Мурсалат',
    'ан-Наба',
    'ан-Назиат',
    'Абаса',
    'ат-Таквир',
    'аль-Инфитар',
    'аль-Мутаффифин',
    'аль-Иншикак',
    'аль-Бурудж',
    'ат-Тарик',
    'аль-Аля',
    'аль-Гашия',
    'аль-Фаджр',
    'аль-Балад',
    'аш-Шамс',
    'аль-Ляйль',
    'ад-Духа',
    'аш-Шарх',
    'ат-Тин',
    'аль-Алак',
    'аль-Кадр',
    'аль-Баййина',
    'аз-Залзала',
    'аль-Адият',
    'аль-Кариа',
    'ат-Такасур',
    'аль-Аср',
    'аль-Хумаза',
    'аль-Филь',
    'Курайш',
    'аль-Маун',
    'аль-Каусар',
    'аль-Кафирун',
    'ан-Наср',
    'аль-Масад',
    'аль-Ихляс',
    'аль-Фалак',
    'ан-Нас',
  ];

  Future<void> _appleLogin() async {
    setState(() => _loadingApple = true);
    final result = await AuthService.signInWithApple();
    final user = result.user;
    if (user != null) {
      setState(() {
        _appleConnected = true;
        final parts = (user.displayName ?? '').split(' ');
        if (parts.isNotEmpty) _firstNameController.text = parts.first;
        if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
      });
    } else if (result.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error!)),
      );
    }
    if (mounted) setState(() => _loadingApple = false);
  }

  Future<void> _continue() async {
    final onboarding = context.read<OnboardingProvider>();
    final plan = context.read<PlanProvider>();

    await onboarding.setAll(
      first: _firstNameController.text.trim(),
      last: _lastNameController.text.trim(),
      middle: '',
      g: _gender ?? '',
      a: _ageController.text.trim(),
      tajweed: _tajweed,
      known: _knownSurahs,
    );

    await plan.setStudyMode(_studyMode);
    if (_studyMode == 'Жаттау') {
      await plan.setKnownSurahs(_knownSurahs);
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/learning', (_) => false);
  }

  void _openSurahSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: _c.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _c.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _s.tr('knownSurahsTitle'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _c.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _s.selectedCount(_knownSurahs.length),
                style: TextStyle(fontSize: 13, color: _c.subtext),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: surahNames.length,
                  itemBuilder: (_, index) {
                    final selected = _knownSurahs.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _knownSurahs.remove(index);
                          } else {
                            _knownSurahs.add(index);
                          }
                        });
                        setModalState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? _c.greenTint : _c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? _c.green : _c.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color:
                                    selected ? _c.green : _c.surfaceAlt,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : _c.subtext,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _s.surahNamesL10n[index],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? _c.green : _c.text,
                                ),
                              ),
                            ),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: selected ? _c.green : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: selected ? _c.green : _c.border,
                                  width: 2,
                                ),
                              ),
                              child: selected
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _c.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _s.tr('done'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: _c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              decoration: BoxDecoration(
                color: _c.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _c.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          s.tr('register'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _c.gold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Language picker
                      _LangPicker(s: s),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    s.tr('registerTitle'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.tr('registerSubtitle'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ──────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Apple connect
                    GestureDetector(
                      onTap: _loadingApple ? null : _appleLogin,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _appleConnected
                              ? _c.greenTint
                              : _c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _appleConnected ? _c.green : _c.border,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: _loadingApple
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: _c.green,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _appleConnected
                                          ? Icons.check_circle
                                          : Icons.apple,
                                      size: 20,
                                      color: _appleConnected
                                          ? _c.green
                                          : _c.text,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _appleConnected
                                          ? s.tr('googleConnected')
                                          : s.tr('signInApple'),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _appleConnected
                                            ? _c.green
                                            : _c.text,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Last name
                    _label('${s.tr('lastName')} · ${s.tr('optional')}'),
                    const SizedBox(height: 8),
                    _input(_lastNameController, s.tr('lastNameHint')),

                    const SizedBox(height: 16),

                    // First name
                    _label('${s.tr('firstName')} · ${s.tr('optional')}'),
                    const SizedBox(height: 8),
                    _input(_firstNameController, s.tr('firstNameHint')),

                    const SizedBox(height: 16),

                    // Age
                    _label('${s.tr('age')} · ${s.tr('optional')}'),
                    const SizedBox(height: 8),
                    _input(
                      _ageController,
                      s.tr('ageHint'),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                    ),

                    const SizedBox(height: 16),

                    // Gender
                    _label('${s.tr('genderLabel')} · ${s.tr('optional')}'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _genderButton('male', '👨', s.tr('male')),
                        const SizedBox(width: 10),
                        _genderButton('female', '👩', s.tr('female')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Study mode
                    _label(s.tr('studyTypeLabel')),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _modeButton('Жаттау', '📘', s.tr('memorizeMode')),
                        const SizedBox(width: 10),
                        _modeButton('Оқу', '📖', s.tr('readMode')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tajweed toggle
                    Container(
                      decoration: BoxDecoration(
                        color: _c.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _c.border),
                      ),
                      child: SwitchListTile(
                        value: _tajweed,
                        activeThumbColor: _c.green,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        title: Text(
                          s.tr('tajweedMarks'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _c.text,
                          ),
                        ),
                        subtitle: Text(
                          s.tr('tajweedSubtitle'),
                          style: TextStyle(fontSize: 12, color: _c.subtext),
                        ),
                        onChanged: (v) => setState(() => _tajweed = v),
                      ),
                    ),

                    // Known surahs (only Жаттау mode)
                    if (_studyMode == 'Жаттау') ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _openSurahSelector,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: _c.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _c.border),
                          ),
                          child: Row(
                            children: [
                              const Text('📖', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _knownSurahs.isEmpty
                                      ? s.tr('selectKnownSurahs')
                                      : s.selectedSurahsCount(_knownSurahs.length),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _knownSurahs.isEmpty
                                        ? _c.subtext
                                        : _c.green,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: _c.subtext,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _c.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          s.tr('continueBtn'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _c.subtext,
          letterSpacing: 0.5,
        ),
      );

  Widget _input(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: (_) => setState(() {}),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _c.text,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(color: _c.subtext, fontSize: 14),
          filled: true,
          fillColor: _c.card,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _c.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _c.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _c.green, width: 1.5),
          ),
        ),
      );

  Widget _genderButton(String value, String emoji, String text) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _c.greenTint : _c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _c.green : _c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? _c.green : _c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String value, String emoji, String text) {
    final selected = _studyMode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _studyMode = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _c.greenTint : _c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _c.green : _c.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? _c.green : _c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangPicker extends StatelessWidget {
  final LanguageProvider s;
  const _LangPicker({required this.s});

  static const _langs = [
    ('kz', 'ҚАЗ', 'Қазақша'),
    ('ru', 'РУС', 'Русский'),
    ('en', 'ENG', 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final current = _langs.firstWhere(
      (l) => l.$1 == s.lang,
      orElse: () => _langs.first,
    );
    return PopupMenuButton<String>(
      onSelected: s.setLanguage,
      color: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => _langs
          .map((l) => PopupMenuItem<String>(
                value: l.$1,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 16,
                      color: s.lang == l.$1 ? c.primary : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    Text(l.$3,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: c.text)),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.$2,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 14, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
