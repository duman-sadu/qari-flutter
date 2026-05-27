import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      kzImage: 'assets/intro/slide1_kz.png',
      ruImage: 'assets/intro/slide1_ru.png',
      kzTitle: 'Құранды оқыңыз',
      ruTitle: 'Читайте Коран',
      kzBody: 'Тәжуид түстерімен безендірілген мәтін.\nТранскрипция мен аударма — бір жерде.',
      ruBody: 'Текст с цветовой разметкой таджвида.\nТранскрипция и перевод — в одном месте.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide2_kz.png',
      ruImage: 'assets/intro/slide2_ru.png',
      kzTitle: 'Аятты жаттаңыз',
      ruTitle: 'Заучивайте аяты',
      kzBody: 'Мәтінді жасырып, өзіңізді тексеріңіз.\nЖаттау режимі — қарапайым және тиімді.',
      ruBody: 'Скрывайте текст и проверяйте себя.\nРежим заучивания — просто и эффективно.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide3_kz.png',
      ruImage: 'assets/intro/slide3_ru.png',
      kzTitle: 'Dudi — AI көмекші',
      ruTitle: 'Dudi — AI-ассистент',
      kzBody: 'Кез келген сұрағыңызды қойыңыз.\nDudi Құран бойынша жауап береді.',
      ruBody: 'Задавайте любые вопросы.\nDudi отвечает на вопросы по Корану.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide4_kz.png',
      ruImage: 'assets/intro/slide4_ru.png',
      kzTitle: 'Dudi Quiz',
      ruTitle: 'Dudi Quiz',
      kzBody: 'Жады мен білімді тексеретін тест.\nОйын форматында Құранды үйреніңіз.',
      ruBody: 'Тест на память и знание Корана.\nУчите Коран в формате игры.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide5_kz.png',
      ruImage: 'assets/intro/slide5_ru.png',
      kzTitle: 'Тыңдау режимі',
      ruTitle: 'Режим прослушивания',
      kzBody: '7 атақты қаридің дауысымен тыңдаңыз.\nЖылдамдықты реттеп, ұйқы таймерін қосыңыз.',
      ruBody: 'Слушайте в исполнении 7 известных чтецов.\nРегулируйте скорость и таймер сна.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide6_kz.png',
      ruImage: 'assets/intro/slide6_ru.png',
      kzTitle: 'Хатым тобы',
      ruTitle: 'Группа Хатм',
      kzBody: 'Достарыңызбен бірге Хатым жасаңыз.\nКімнің қай жүзді оқып жатқанын бақылаңыз.',
      ruBody: 'Совершайте хатм вместе с друзьями.\nСледите за прогрессом каждого участника.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide7_kz.png',
      ruImage: 'assets/intro/slide7_ru.png',
      kzTitle: '30 жүз — бір топта',
      ruTitle: '30 джузов — одна группа',
      kzBody: 'Топ мүшелері жүздерді бөліп алады.\nПрогресс нақты уақытта жаңарады.',
      ruBody: 'Участники распределяют джузы между собой.\nПрогресс обновляется в реальном времени.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide8_kz.png',
      ruImage: 'assets/intro/slide8_ru.png',
      kzTitle: 'Статистика',
      ruTitle: 'Статистика',
      kzBody: 'Оқылған беттер, аяттар және стриктер.\nЖетістіктеріңізді бақылаңыз.',
      ruBody: 'Прочитанные страницы, аяты и стрики.\nОтслеживайте свои достижения.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide9_kz.png',
      ruImage: 'assets/intro/slide9_ru.png',
      kzTitle: 'Мақсат қойыңыз',
      ruTitle: 'Ставьте цели',
      kzBody: 'Жаттау немесе оқу мақсатын белгілеңіз.\nЕскерту уақытын реттеп, мерзімін қойыңыз.',
      ruBody: 'Задавайте цели по заучиванию или чтению.\nНастройте напоминание и укажите дедлайн.',
    ),
    _Slide(
      kzImage: 'assets/intro/slide10_kz.png',
      ruImage: 'assets/intro/slide10_ru.png',
      kzTitle: 'Үйренген сүрелер',
      ruTitle: 'Выученные суры',
      kzBody: 'Барлық үйренген сүрелер тізімде.\nПрофильде прогрессіңізді қараңыз.',
      ruBody: 'Все выученные суры в одном списке.\nСмотрите прогресс в своём профиле.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _ctrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _done();
    }
  }

  void _done() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isRu = context.watch<LanguageProvider>().isRu;
    final isLast = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 5),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? c.primary : c.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _done,
                    style: TextButton.styleFrom(
                      foregroundColor: c.subtext,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      isRu ? 'Пропустить' : 'Өткізу',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // ── Slides ───────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) =>
                    _SlideView(slide: _slides[i], isRu: isRu, c: c),
              ),
            ),

            // ── Bottom button ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLast
                            ? (isRu ? 'Начать' : 'Бастау')
                            : (isRu ? 'Далее' : 'Келесі'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  final bool isRu;
  final AppColors c;

  const _SlideView(
      {required this.slide, required this.isRu, required this.c});

  @override
  Widget build(BuildContext context) {
    final imagePath = isRu ? slide.ruImage : slide.kzImage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phone frame with screenshot
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 420, maxWidth: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Container(
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: c.border),
                    ),
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          size: 48, color: c.subtext),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            isRu ? slide.ruTitle : slide.kzTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: c.text,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Body
          Text(
            isRu ? slide.ruBody : slide.kzBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: c.subtext,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String kzImage;
  final String ruImage;
  final String kzTitle;
  final String ruTitle;
  final String kzBody;
  final String ruBody;

  const _Slide({
    required this.kzImage,
    required this.ruImage,
    required this.kzTitle,
    required this.ruTitle,
    required this.kzBody,
    required this.ruBody,
  });
}
