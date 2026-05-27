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
  bool _loadingGoogle = false;
  bool _googleConnected = false;
  String _studyMode = 'Жаттау';

  final List<int> _knownSurahs = [];

  final List<String> surahNames = [
    'әл-Фатиха сүресі (Кітап ашушы)',
    'әл-Бақара сүресі (Сиыр)',
    'Әли Имран сүресі (Имран жанұясы)',
    'ән-Ниса сүресі (Әйелдер)',
    'әл-Мәида сүресі (Ас толы дастархан)',
    'әл-Әнғам сүресі (Малдар)',
    'әл-Ағраф сүресі (Биік тосқауылдар)',
    'әл-Әнфал сүресі (Соғыс олжалары)',
    'әт-Тәубә сүресі (Тәубе)',
    'Жүніс сүресі (Жүніс пайғамбар)',
    'Һуд сүресі (Һуд пайғамбар)',
    'Юсуф сүресі (Юсуф пайғамбар)',
    'әр-Рағд сүресі (Найзағай)',
    'Ибраһим сүресі (Ибраһим пайғамбар)',
    'әл-Хижр сүресі (Хижр өлкесі)',
    'ән-Нахл сүресі (Бал арасы)',
    'әл-Исра сүресі (Түнгі сапар)',
    'әл-Кәһф сүресі (Үңгір)',
    'Мәриям сүресі (Мәриям ана)',
    'Та-Һа сүресі',
    'әл-Әнбия сүресі (Пайғамбарлар)',
    'әл-Хаж сүресі (Қажылық)',
    'әл-Муминун сүресі (Мүміндер)',
    'ән-Нұр сүресі (Нұр)',
    'әл-Фурқан сүресі (Ақиқатты айырушы)',
    'әш-Шуғара сүресі (Ақындар)',
    'ән-Нәмл сүресі (Құмырсқа)',
    'әл-Қасас сүресі (Қиссалар)',
    'әл-Анкабут сүресі (Өрмекші)',
    'әр-Рум сүресі (Румдықтар)',
    'Лұқман сүресі',
    'әс-Сәжде сүресі (Сәжде)',
    'әл-Ахзаб сүресі (Одақтастар)',
    'Сәбә сүресі (Сәбә елі)',
    'Фатыр сүресі (Жаратушы)',
    'Ясин сүресі',
    'әс-Саффат сүресі (Сап түзегендер)',
    'Сад сүресі',
    'әз-Зумар сүресі (Топтар)',
    'Ғафир сүресі (Кешіруші)',
    'Фуссилат сүресі (Анық баяндалған)',
    'әш-Шура сүресі (Кеңес)',
    'әз-Зухруф сүресі (Алтын әшекей)',
    'әд-Духан сүресі (Түтін)',
    'әл-Жәсия сүресі (Тізерлегендер)',
    'әл-Ахқаф сүресі (Құм төбелер)',
    'Мұхаммед сүресі',
    'әл-Фатх сүресі (Жеңіс)',
    'әл-Хужурат сүресі (Бөлмелер)',
    'Қаф сүресі',
    'әз-Зәрият сүресі (Шашыратушылар)',
    'әт-Тур сүресі (Тур тауы)',
    'ән-Нәжм сүресі (Жұлдыз)',
    'әл-Қамар сүресі (Ай)',
    'әр-Рахман сүресі (Аса Рахымды)',
    'әл-Уақиға сүресі (Болатын оқиға)',
    'әл-Хадид сүресі (Темір)',
    'әл-Мужадила сүресі (Таласушы әйел)',
    'әл-Хашр сүресі (Жиналу)',
    'әл-Мумтахана сүресі (Сыналушы әйел)',
    'әс-Сафф сүресі (Сап)',
    'әл-Жұма сүресі (Жұма)',
    'әл-Мунафиқун сүресі (Мұнафықтар)',
    'әт-Тәғабун сүресі (Алдану)',
    'әт-Талақ сүресі (Талақ)',
    'әт-Тахрим сүресі (Тыйым салу)',
    'әл-Мүлк сүресі (Билік)',
    'әл-Қалам сүресі (Қалам)',
    'әл-Хаққа сүресі (Ақиқат)',
    'әл-Мағариж сүресі (Баспалдақтар)',
    'Нұх сүресі (Нұх пайғамбар)',
    'әл-Жин сүресі (Жындар)',
    'әл-Мүззәммил сүресі (Оранған)',
    'әл-Мүддәссир сүресі (Жамылған)',
    'әл-Қияма сүресі (Қиямет)',
    'әл-Инсан сүресі (Адам)',
    'әл-Мурсалат сүресі (Жіберілгендер)',
    'ән-Нәбә сүресі (Ұлы хабар)',
    'ән-Назиғат сүресі (Жұлқып алушылар)',
    'Абаса сүресі (Қабағын түйді)',
    'әт-Такуир сүресі (Оралу)',
    'әл-Инфитар сүресі (Жарылу)',
    'әл-Мутаффифин сүресі (Өлшеуде кемітушілер)',
    'әл-Иншиқақ сүресі (Жарылу)',
    'әл-Буруж сүресі (Шоқжұлдыздар)',
    'әт-Тариқ сүресі (Түнгі жұлдыз)',
    'әл-Ағла сүресі (Ең жоғары)',
    'әл-Ғашия сүресі (Қаптаушы)',
    'әл-Фәжр сүресі (Таң)',
    'әл-Балад сүресі (Қала)',
    'әш-Шәмс сүресі (Күн)',
    'әл-Ләйл сүресі (Түн)',
    'әд-Духа сүресі (Таңғы жарық)',
    'әш-Шарх сүресі (Көңіл ашу)',
    'әт-Тин сүресі (Інжір)',
    'әл-Алақ сүресі (Ұйыған қан)',
    'әл-Қадр сүресі (Қадір түні)',
    'әл-Бәййина сүресі (Анық дәлел)',
    'әз-Залзала сүресі (Зілзала)',
    'әл-Адият сүресі (Шабушы аттар)',
    'әл-Қариға сүресі (Соққы беруші)',
    'әт-Такәсур сүресі (Көбейту жарысы)',
    'әл-Асыр сүресі (Заман)',
    'әл-Һумаза сүресі (Өсекші)',
    'әл-Фил сүресі (Піл)',
    'Құрайыш сүресі',
    'әл-Мағун сүресі (Көмек)',
    'әл-Кәусар сүресі (Кәусар)',
    'әл-Кафирун сүресі (Кәпірлер)',
    'ән-Наср сүресі (Жәрдем)',
    'әл-Мәсәд сүресі (Қураған талшық)',
    'әл-Ықылас сүресі (Шынайылық)',
    'әл-Фәлақ сүресі (Таңның атуы)',
    'ән-Нас сүресі (Адамдар)',
  ];

  final List<String> surahNamesRu = [
    'аль-Фатиха (Открывающая)',
    'аль-Бакара (Корова)',
    'Аль Имран (Семья Имрана)',
    'ан-Ниса (Женщины)',
    'аль-Маида (Трапеза)',
    'аль-Анам (Скот)',
    'аль-Араф (Преграды)',
    'аль-Анфаль (Добыча)',
    'ат-Тауба (Покаяние)',
    'Юнус (Пророк Юнус)',
    'Худ (Пророк Худ)',
    'Юсуф (Пророк Юсуф)',
    'ар-Рад (Гром)',
    'Ибрахим (Пророк Ибрахим)',
    'аль-Хиджр (Каменистая долина)',
    'ан-Нахль (Пчёлы)',
    'аль-Исра (Ночное путешествие)',
    'аль-Кахф (Пещера)',
    'Марьям (Мария)',
    'Та-Ха',
    'аль-Анбия (Пророки)',
    'аль-Хадж (Паломничество)',
    'аль-Муминун (Верующие)',
    'ан-Нур (Свет)',
    'аль-Фуркан (Различение)',
    'аш-Шуара (Поэты)',
    'ан-Намль (Муравьи)',
    'аль-Касас (Повествование)',
    'аль-Анкабут (Паук)',
    'ар-Рум (Румы)',
    'Лукман (Пророк Лукман)',
    'ас-Саджда (Земной поклон)',
    'аль-Ахзаб (Союзники)',
    'Саба (Народ Сабы)',
    'Фатир (Творец)',
    'Ясин',
    'ас-Саффат (Стоящие в ряды)',
    'Сад',
    'аз-Зумар (Толпы)',
    'Гафир (Прощающий)',
    'Фуссилат (Разъяснены)',
    'аш-Шура (Совет)',
    'аз-Зухруф (Украшения)',
    'ад-Духан (Дым)',
    'аль-Джасия (Коленопреклонённые)',
    'аль-Ахкаф (Барханы)',
    'Мухаммад',
    'аль-Фатх (Победа)',
    'аль-Худжурат (Комнаты)',
    'Каф',
    'аз-Зарият (Рассеивающие)',
    'ат-Тур (Гора)',
    'ан-Наджм (Звезда)',
    'аль-Камар (Луна)',
    'ар-Рахман (Милостивый)',
    'аль-Вакиа (Неизбежное)',
    'аль-Хадид (Железо)',
    'аль-Муджадала (Препирающаяся)',
    'аль-Хашр (Сбор)',
    'аль-Мумтахана (Испытуемая)',
    'ас-Сафф (Ряды)',
    'аль-Джумуа (Пятница)',
    'аль-Мунафикун (Лицемеры)',
    'ат-Тагабун (Взаимный обман)',
    'ат-Талак (Развод)',
    'ат-Тахрим (Запрещение)',
    'аль-Мульк (Власть)',
    'аль-Калам (Перо)',
    'аль-Хакка (Неминуемое)',
    'аль-Мааридж (Ступени)',
    'Нух (Пророк Нух)',
    'аль-Джинн (Джинны)',
    'аль-Муззаммиль (Закутавшийся)',
    'аль-Муддассир (Укрывшийся)',
    'аль-Кияма (Воскресение)',
    'аль-Инсан (Человек)',
    'аль-Мурсалат (Посланные)',
    'ан-Наба (Весть)',
    'ан-Назиат (Вырывающие)',
    'Абаса (Нахмурился)',
    'ат-Таквир (Скручивание)',
    'аль-Инфитар (Раскалывание)',
    'аль-Мутаффифин (Обвешивающие)',
    'аль-Иншикак (Разрыв)',
    'аль-Бурудж (Созвездия)',
    'ат-Тарик (Ночная звезда)',
    'аль-Аля (Высочайший)',
    'аль-Гашия (Покрывающее)',
    'аль-Фаджр (Заря)',
    'аль-Балад (Город)',
    'аш-Шамс (Солнце)',
    'аль-Ляйль (Ночь)',
    'ад-Духа (Утро)',
    'аш-Шарх (Раскрытие)',
    'ат-Тин (Смоковница)',
    'аль-Алак (Сгусток крови)',
    'аль-Кадр (Могущество)',
    'аль-Баййина (Ясное знамение)',
    'аз-Залзала (Землетрясение)',
    'аль-Адият (Скачущие)',
    'аль-Кариа (Сокрушительный удар)',
    'ат-Такасур (Страсть к умножению)',
    'аль-Аср (Время)',
    'аль-Хумаза (Хулитель)',
    'аль-Филь (Слон)',
    'Курайш',
    'аль-Маун (Помощь)',
    'аль-Каусар (Изобилие)',
    'аль-Кафирун (Неверующие)',
    'ан-Наср (Помощь Аллаха)',
    'аль-Масад (Пальмовые волокна)',
    'аль-Ихляс (Искренность)',
    'аль-Фалак (Рассвет)',
    'ан-Нас (Люди)',
  ];

  bool get _isValid =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _ageController.text.trim().isNotEmpty &&
      _gender != null;

  Future<void> _googleLogin() async {
    setState(() => _loadingGoogle = true);
    final result = await AuthService.signInWithGoogle();
    final user = result.user;
    if (user != null) {
      setState(() {
        _googleConnected = true;
        final parts = (user.displayName ?? '').split(' ');
        if (parts.isNotEmpty) _firstNameController.text = parts.first;
        if (parts.length > 1) _lastNameController.text = parts.sublist(1).join(' ');
      });
    }
    setState(() => _loadingGoogle = false);
  }

  Future<void> _continue() async {
    if (!_isValid) return;

    final onboarding = context.read<OnboardingProvider>();
    final plan = context.read<PlanProvider>();

    await onboarding.setAll(
      first: _firstNameController.text.trim(),
      last: _lastNameController.text.trim(),
      middle: '',
      g: _gender!,
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
                                _s.isRu ? surahNamesRu[index] : surahNames[index],
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
                    // Google connect
                    GestureDetector(
                      onTap: _loadingGoogle ? null : _googleLogin,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: _googleConnected
                              ? _c.greenTint
                              : _c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _googleConnected ? _c.green : _c.border,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: _loadingGoogle
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
                                    Text(
                                      _googleConnected ? '✅' : '🔵',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _googleConnected
                                          ? s.tr('googleConnected')
                                          : s.tr('signInGoogle'),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _googleConnected
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
                    _label(s.tr('lastName')),
                    const SizedBox(height: 8),
                    _input(_lastNameController, s.tr('lastNameHint')),

                    const SizedBox(height: 16),

                    // First name
                    _label(s.tr('firstName')),
                    const SizedBox(height: 8),
                    _input(_firstNameController, s.tr('firstNameHint')),

                    const SizedBox(height: 16),

                    // Age
                    _label(s.tr('age')),
                    const SizedBox(height: 8),
                    _input(
                      _ageController,
                      s.tr('ageHint'),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                    ),

                    const SizedBox(height: 16),

                    // Gender
                    _label(s.tr('genderLabel')),
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
                        onPressed: () {
                          if (!_isValid) {
                            final msg = _firstNameController.text.trim().isEmpty
                                ? _s.tr('enterFirstName')
                                : _lastNameController.text.trim().isEmpty
                                    ? _s.tr('enterLastName')
                                    : _ageController.text.trim().isEmpty
                                        ? _s.tr('enterAge')
                                        : _s.tr('selectGender');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          _continue();
                        },
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
