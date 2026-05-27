import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';

// Product IDs — create matching Consumable products in Google Play Console
const _kProductIds = <String>{
  'qari_support_tier1',
  'qari_support_tier2',
  'qari_support_tier3',
};

class SupportSheet extends StatefulWidget {
  final bool isRu;
  const SupportSheet({super.key, required this.isRu});

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _unavailable = false;
  String? _feedback;

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
    final resp = await _iap.queryProductDetails(_kProductIds);
    if (!mounted) return;
    setState(() {
      _products = resp.productDetails
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
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
      if (p.status == PurchaseStatus.purchased) {
        _iap.completePurchase(p);
        _onDonationSuccess();
        if (mounted) {
          setState(() => _feedback = widget.isRu
              ? 'БаракаллахуфикА! Аллах принял твоё пожертвование 🤲'
              : 'БаракаллаhУ фик! Аллах садақаңды қабыл алсын 🤲');
        }
      } else if (p.status == PurchaseStatus.error) {
        _iap.completePurchase(p);
        if (mounted) setState(() => _feedback = null);
      } else if (p.status == PurchaseStatus.canceled) {
        if (mounted) setState(() => _feedback = null);
      }
    }
  }

  void _buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    _iap.buyConsumable(purchaseParam: param);
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
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 24),
          const Text('🤲', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            widget.isRu ? 'Поддержать Qari' : 'Qari қолдаңыз',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c.text),
          ),
          const SizedBox(height: 10),
          Text(
            widget.isRu
                ? 'Это приложение создано с любовью и для блага уммы. Ваша поддержка помогает его развитию.'
                : 'Бұл қолданба үмметтің игілігі үшін жасалды. Қолдауыңыз оны дамытуға көмектеседі.',
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
          ] else if (_unavailable || _products.isEmpty) ...[
            _UnavailableHint(isRu: widget.isRu, c: c),
          ] else ...[
            ..._products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TierButton(product: p, c: c, onTap: () => _buy(p)),
            )),
          ],

          const SizedBox(height: 20),
          Text(
            widget.isRu
                ? 'Спасибо за поддержку! Пусть Аллах вознаградит вас и примет ваше доброе дело 🤲'
                : 'Алла разы болсын! Алла қабыл етсін 🤲',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: c.subtext, height: 1.6),
          ),
        ],
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
  final bool isRu;
  final AppColors c;
  const _UnavailableHint({required this.isRu, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Text(
        isRu
            ? 'Оплата временно недоступна.\nПожалуйста, убедитесь, что Google Play работает на вашем устройстве.'
            : 'Төлем уақытша қолжетімсіз.\nGoogle Play құрылғыда жұмыс істейтінін тексеріңіз.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: c.subtext, height: 1.5),
      ),
    );
  }
}
