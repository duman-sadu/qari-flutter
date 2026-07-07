import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';

// Legal links required for auto-renewable subscriptions (App Store / Play)
const _kPrivacyPolicyUrl = 'https://duman-sadu.github.io/qari-privacy/';
const _kTermsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

// Product IDs — must match exactly in Google Play Console AND App Store Connect
const _kSubscriptionId = 'qari_sponsor_monthly';
const _kTierIds = <String>{
  'qari_support_tier1',
  'qari_support_tier2',
  'qari_support_tier3',
};
final _kAllProductIds = {..._kTierIds, _kSubscriptionId};

String _pick(String lang, String kz, String ru, String en) {
  switch (lang) {
    case 'ru': return ru;
    case 'en': return en;
    default:   return kz;
  }
}

class SupportSheet extends StatefulWidget {
  final String lang;
  const SupportSheet({super.key, required this.lang});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> _tiers = [];
  ProductDetails? _sponsorProduct;
  bool _loading = true;
  bool _unavailable = false;
  String? _feedback;

  String _tr(String kz, String ru, String en) => _pick(widget.lang, kz, ru, en);

  @override
  void initState() {
    super.initState();
    _sub = _iap.purchaseStream.listen(_onPurchase, onError: (_) {});
    _loadProducts();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) {
      setState(() { _loading = false; _unavailable = true; });
      return;
    }
    final resp = await _iap.queryProductDetails(_kAllProductIds);
    if (!mounted) return;
    final tiers = resp.productDetails
        .where((p) => _kTierIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    final sponsor = resp.productDetails
        .where((p) => p.id == _kSubscriptionId)
        .firstOrNull;
    setState(() {
      _tiers = tiers;
      _sponsorProduct = sponsor;
      _loading = false;
    });
  }

  void _onDonationSuccess() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('hasDonated', true);
      NotificationService.cancelSupportReminder();
    });
  }

  void _onPurchase(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        _iap.completePurchase(p);
        _onDonationSuccess();
        final isSponsor = p.productID == _kSubscriptionId;
        if (mounted) {
          setState(() => _feedback = isSponsor
              ? _tr(
                  'МашааАллах! Сіз Qari демеушісі болдыңыз 👑\nАллах сізді марапаттасын!',
                  'МашааАллах! Вы стали спонсором Qari 👑\nАллах вознаградит вас!',
                  'MashaAllah! You became a Qari sponsor 👑\nMay Allah reward you!')
              : _tr(
                  'БаракаллаhУ фик! Аллах садақаңды қабыл алсын 🤲',
                  'БаракаллахуфикА! Аллах принял твоё пожертвование 🤲',
                  'BarakAllahu fik! May Allah accept your donation 🤲'));
        }
      } else if (p.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _feedback = _tr(
            'Растау күтілуде...',
            'Ожидание подтверждения...',
            'Waiting for confirmation...'));
      } else if (p.status == PurchaseStatus.error) {
        _iap.completePurchase(p);
        if (mounted) setState(() => _feedback = null);
      } else if (p.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _feedback = null);
      }
    }
  }

  void _buyTier(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: param);
  }

  void _buySponsor(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🤲', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            _tr('Qari қолдаңыз', 'Поддержать Qari', 'Support Qari'),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c.text),
          ),
          const SizedBox(height: 10),
          Text(
            _tr(
                'Бұл қолданба үмметтің игілігі үшін жасалды. Қолдауыңыз оны дамытуға көмектеседі.',
                'Это приложение создано с любовью и для блага уммы. Ваша поддержка помогает его развитию.',
                'This app was made with love for the good of the ummah. Your support helps it grow.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.subtext, height: 1.5),
          ),
          const SizedBox(height: 24),

          if (_feedback != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D56).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2E7D56).withValues(alpha: 0.3)),
              ),
              child: Text(
                _feedback!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF2E7D56), fontWeight: FontWeight.w600),
              ),
            ),
          ] else if (_loading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ] else if (_unavailable) ...[
            _UnavailableHint(lang: widget.lang, c: c),
          ] else ...[

            // ── Sponsor subscription button ──────────────────────────
            if (_sponsorProduct != null) ...[
              _SponsorButton(
                product: _sponsorProduct!,
                lang: widget.lang,
                onTap: () => _buySponsor(_sponsorProduct!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Divider(color: c.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _tr('немесе бір реттік донат', 'или разовый донат',
                          'or a one-time donation'),
                      style: TextStyle(fontSize: 11, color: c.subtext),
                    ),
                  ),
                  Expanded(child: Divider(color: c.border)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ── One-time tier buttons ────────────────────────────────
            if (_tiers.isEmpty)
              _UnavailableHint(lang: widget.lang, c: c)
            else
              ..._tiers.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TierButton(product: p, c: c, onTap: () => _buyTier(p)),
              )),
          ],

          const SizedBox(height: 20),
          Text(
            _tr(
                'Алла разы болсын! Алла қабыл етсін 🤲',
                'Спасибо за поддержку! Пусть Аллах вознаградит вас и примет ваше доброе дело 🤲',
                'Thank you for your support! May Allah reward you and accept your good deed 🤲'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.subtext, height: 1.6),
          ),
          const SizedBox(height: 16),
          Text(
            _tr(
                '«Демеуші болу» жазылымы сіз болдырмағанша, жоғарыда көрсетілген баға бойынша ай сайын автоматты түрде ұзартылады.',
                'Подписка «Стать спонсором» продлевается автоматически каждый месяц по цене, указанной выше, пока вы её не отмените.',
                'The "Become a sponsor" subscription renews automatically every month at the price shown above until you cancel it.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: c.subtext, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink(
                label: _tr('Құпиялылық саясаты', 'Политика конфиденциальности',
                    'Privacy Policy'),
                url: _kPrivacyPolicyUrl,
                c: c,
              ),
              Text('  ·  ', style: TextStyle(fontSize: 12, color: c.subtext)),
              _LegalLink(
                label: _tr('Пайдалану шарттары', 'Условия использования',
                    'Terms of Use'),
                url: _kTermsOfUseUrl,
                c: c,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  final AppColors c;
  const _LegalLink({required this.label, required this.url, required this.c});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: c.subtext,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

class _SponsorButton extends StatelessWidget {
  final ProductDetails product;
  final String lang;
  final VoidCallback onTap;
  const _SponsorButton({required this.product, required this.lang, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B4F00), Color(0xFFD4A017)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4A017).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('👑', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _pick(lang, 'Демеуші болу', 'Стать спонсором',
                        'Become a sponsor'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.price,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900),
                    ),
                    Text(
                      _pick(lang, 'айына', 'в месяц', 'per month'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _pick(lang,
                  'Автотөлем · Кез келген уақытта болдырмауға болады',
                  'Автооплата · Отмена в любое время',
                  'Auto-renews · Cancel anytime'),
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierButton extends StatelessWidget {
  final ProductDetails product;
  final AppColors c;
  final VoidCallback onTap;
  const _TierButton({required this.product, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E3B), Color(0xFF2E7D56)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                product.title.replaceAll(RegExp(r'\s*\(.*?\)'), ''),
                style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              product.price,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnavailableHint extends StatelessWidget {
  final String lang;
  final AppColors c;
  const _UnavailableHint({required this.lang, required this.c});

  @override
  Widget build(BuildContext context) {
    final store = Platform.isIOS ? 'App Store' : 'Google Play';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Text(
        _pick(lang,
            'Төлем уақытша қолжетімсіз.\n$store құрылғыда жұмыс істейтінін тексеріңіз.',
            'Оплата временно недоступна.\nПожалуйста, убедитесь, что $store работает на вашем устройстве.',
            'Payments are temporarily unavailable.\nPlease make sure $store works on your device.'),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: c.subtext, height: 1.5),
      ),
    );
  }
}
