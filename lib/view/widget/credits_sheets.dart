import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biblebookapp/services/paywall_preload_service.dart';
import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart'
    show AdConsentManager;
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/intro_subcribtion_screen.dart';
import 'package:biblebookapp/view/screens/paywall_navigation.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where the user ran out of credits.
enum CreditsSheetFrom { chat, prayer }

/// Out-of-credits bottom sheets (Chat / Prayer). Reuses existing wallet rules:
/// reward ad = 50 credits (max 2/day), free claim = 20 credits / 15 min,
/// credit packs bought in Wallet, plans via the existing purchase screen.
class CreditsSheets {
  CreditsSheets._();

  /// Checkout id passed to the purchase screen so success returns here.
  static const String checkadId = 'credits_sheet';

  static Future<void> showOutOfCredits(
    BuildContext context, {
    required CreditsSheetFrom from,
    required int needed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final plan =
        (prefs.getString('subscription_plan') ?? '').toLowerCase().trim();
    final isLifetime =
        plan == 'platinum' && await BibleInfo.hasActivePremiumPlan();
    final credits = await WalletService.getCredits();
    unawaited(_RewardAd.preload());
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (isLifetime) return _RefillSheet(credits: credits);
        if (from == CreditsSheetFrom.chat) {
          return _KeepGoingSheet(credits: credits);
        }
        return _PrayerNeedsSheet(credits: credits, needed: needed);
      },
    );
  }
}

// ── Shared look ──────────────────────────────────────────────────────────────

const _cream = Color(0xFFFFFAF4);
const _ink = Color(0xFF4A2C17);
const _muted = Color(0xFF7A6455);
const _tile = Color(0xFFF6E9D6);
const _tileBorder = Color(0xFFE9D7B8);
const _amber = Color(0xFFD9822B);

const _brownGradient = LinearGradient(
  colors: [Color(0xFFA9673C), Color(0xFF7A4524)],
);
const _goldGradient = LinearGradient(
  colors: [Color(0xFFCFA03A), Color(0xFFAE7B1C)],
);

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.credits, required this.children});

  final int credits;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            decoration: const BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _tileBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(child: Center(child: _CreditsLeftPill(credits))),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: _tile,
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.close, size: 18, color: _muted),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreditsLeftPill extends StatelessWidget {
  const _CreditsLeftPill(this.credits);
  final int credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE3CF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 14, color: _amber),
          const SizedBox(width: 5),
          Text(
            '$credits credits left',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45E1C),
            ),
          ),
        ],
      ),
    );
  }
}

Text _title(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Georgia',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: _ink,
      ),
    );

Text _subtitle(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14.5, height: 1.35, color: _muted),
    );

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.gradient,
    required this.onTap,
    required this.child,
    this.height = 56,
  });

  final Gradient gradient;
  final VoidCallback? onTap;
  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7A4524).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  const _TileButton({
    required this.onTap,
    required this.child,
    this.outlined = false,
    this.highlighted = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool outlined;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : _tile,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted ? const Color(0xFFC99A2E) : _tileBorder,
              width: highlighted ? 1.6 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

Future<void> _openWallet() async {
  await Get.to(() => const WalletScreen());
}

/// Watch-ad button state shared by the sheets.
mixin _AdState<T extends StatefulWidget> on State<T> {
  int credits = 0;
  int adsLeft = 2;
  bool adBusy = false;

  Future<void> refreshWallet() async {
    final c = await WalletService.getCredits();
    final left = await WalletService.getRemainingAdsToday();
    if (!mounted) return;
    setState(() {
      credits = c;
      adsLeft = left < 0 ? 0 : left;
    });
  }

  Future<void> watchAd() async {
    if (adBusy) return;
    setState(() => adBusy = true);
    try {
      await _RewardAd.watch();
      // Reward callback can land just after the ad closes.
      await Future<void>.delayed(const Duration(milliseconds: 400));
    } finally {
      if (mounted) setState(() => adBusy = false);
      await refreshWallet();
    }
  }
}

// ── 1. Chat, free user: "Keep the conversation going" ────────────────────────

class _KeepGoingSheet extends StatefulWidget {
  const _KeepGoingSheet({required this.credits});
  final int credits;

  @override
  State<_KeepGoingSheet> createState() => _KeepGoingSheetState();
}

class _KeepGoingSheetState extends State<_KeepGoingSheet>
    with _AdState<_KeepGoingSheet> {
  bool _yearly = true;
  ProductDetails? _month;
  ProductDetails? _year;

  @override
  void initState() {
    super.initState();
    credits = widget.credits;
    refreshWallet();
    for (final p in PaywallPreloadService.getPreloadedProducts()) {
      if (_month == null && BibleInfo.isArOneMonthProductId(p.id)) _month = p;
      if (_year == null && BibleInfo.isArOneYearProductId(p.id)) _year = p;
    }
  }

  int? get _savePercent {
    final m = _month, y = _year;
    if (m == null || y == null || m.rawPrice <= 0) return null;
    final pct = ((1 - y.rawPrice / (m.rawPrice * 12)) * 100).round();
    return pct > 0 ? pct : null;
  }

  Future<void> _startPlan() async {
    if (!await SubscriptionScreen.isDashboardIapEnabled()) return;
    final lifeTime = await SharPreferences.getString('lifeTimePlan') ??
        BibleInfo.lifeTimePlanid;
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: BibleInfo.arOneMonthPlanid,
          oneYearPlan: BibleInfo.arOneYearPlanid,
          lifeTimePlan: lifeTime,
          checkad: CreditsSheets.checkadId,
          initialSelectedPlanIndex: _yearly ? 1 : 0,
          autoStartSelectedPlanPurchase: true,
          invisiblePurchaseHost: true,
        ),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _restore() async {
    final lifeTime = await SharPreferences.getString('lifeTimePlan') ??
        BibleInfo.lifeTimePlanid;
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, _, __) => SubscriptionScreen(
          sixMonthPlan: BibleInfo.arOneMonthPlanid,
          oneYearPlan: BibleInfo.arOneYearPlanid,
          lifeTimePlan: lifeTime,
          checkad: CreditsSheets.checkadId,
          invisiblePurchaseHost: true,
          autoStartRestore: true,
        ),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _openLegal(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Widget _planChip(String label, bool selected, {String? badge}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _yearly = label == '1 Year'),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF1ECFB) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF6A54C9)
                      : const Color(0xFFDCD3EE),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected ? const Color(0xFF4B3AA8) : _ink,
                ),
              ),
            ),
            if (badge != null)
              Positioned(
                top: -9,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFAE7B1C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = BibleInfo.isAutoRenewablePaywallMode;
    final price = _yearly ? _year?.price : _month?.price;
    final per = _yearly ? '/year' : '/month';
    final save = _savePercent;
    return _SheetShell(
      credits: credits,
      children: [
        const SizedBox(height: 6),
        _title('Keep the conversation going'),
        const SizedBox(height: 6),
        _subtitle(
            'Unlimited AI guidance, prayer and answers whenever you need them.'),
        const SizedBox(height: 16),
        if (ar) ...[
          Row(
            children: [
              _planChip('1 Month', !_yearly),
              const SizedBox(width: 12),
              _planChip('1 Year', _yearly,
                  badge: save != null ? 'SAVE $save%' : null),
            ],
          ),
          const SizedBox(height: 14),
          if (price != null)
            Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: price,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1B3A),
                  ),
                ),
                TextSpan(
                  text: per,
                  style: const TextStyle(fontSize: 15, color: _muted),
                ),
              ]),
            ),
          if (_yearly) ...[
            const SizedBox(height: 4),
            const Text(
              "You won't be charged anything today.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _GradientButton(
            gradient: _goldGradient,
            onTap: _startPlan,
            child: Center(
              child: Text(
                _yearly ? 'Start My 3-Day Free Trial →' : 'Continue →',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (price != null) ...[
            const SizedBox(height: 6),
            Text(
              _yearly
                  ? 'Then $price/year · Auto-renews · Cancel anytime.'
                  : '$price/month · Auto-renews · Cancel anytime.',
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
          const SizedBox(height: 14),
        ],
        Row(
          children: [
            Expanded(
              child: _TileButton(
                outlined: true,
                onTap: adsLeft > 0 && !adBusy ? watchAd : null,
                child: Center(
                  child: Text(
                    adsLeft > 0 ? '▶  Watch ad +50' : 'Come back tomorrow',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TileButton(
                outlined: true,
                onTap: () async {
                  await _openWallet();
                  await refreshWallet();
                },
                child: const Center(
                  child: Text(
                    '✦  Buy credits',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            _link(
                'Terms of Use',
                () => _openLegal(
                    'https://bibleoffice.com/terms_conditions.html')),
            const Text(' · ', style: TextStyle(fontSize: 12, color: _muted)),
            _link(
                'Privacy Policy',
                () =>
                    _openLegal('https://bibleoffice.com/privacy_policy.html')),
            if (ar) ...[
              const Text(' · ', style: TextStyle(fontSize: 12, color: _muted)),
              _link('Restore Purchases', _restore),
            ],
          ],
        ),
      ],
    );
  }
}

Widget _link(String text, VoidCallback onTap) => GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: _muted,
          decoration: TextDecoration.underline,
        ),
      ),
    );

// ── 2. Lifetime user: "Refill your credits" ──────────────────────────────────

class _RefillSheet extends StatefulWidget {
  const _RefillSheet({required this.credits});
  final int credits;

  @override
  State<_RefillSheet> createState() => _RefillSheetState();
}

class _RefillSheetState extends State<_RefillSheet>
    with _AdState<_RefillSheet> {
  int _claimSeconds = 0;
  Timer? _tick;
  bool _claiming = false;
  List<({String id, String credits, String price})> _packs = [];

  @override
  void initState() {
    super.initState();
    credits = widget.credits;
    refreshWallet();
    _refreshClaim();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_claimSeconds > 0 && mounted) setState(() => _claimSeconds--);
    });
    _loadPacks();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _refreshClaim() async {
    final s = await WalletService.getClaimCooldownSeconds();
    if (mounted) setState(() => _claimSeconds = s);
  }

  Future<void> _claim() async {
    if (_claiming || _claimSeconds > 0) return;
    setState(() => _claiming = true);
    final result = await WalletService.claimFreeCredits();
    if (result != null) Constants.showToast('Claimed 20 credits!', 2000);
    await _refreshClaim();
    await refreshWallet();
    if (mounted) setState(() => _claiming = false);
  }

  /// Same pack credits as Wallet (dashboard `coin_packs`, else constants);
  /// prices from the App Store when available.
  Future<void> _loadPacks() async {
    final ids = [
      BibleInfo.coinPack1Id,
      BibleInfo.coinPack2Id,
      BibleInfo.coinPack3Id
    ];
    final fallbackCredits = [
      BibleInfo.coinPack1Credits,
      BibleInfo.coinPack2Credits,
      BibleInfo.coinPack3Credits,
    ];
    final fallbackPrices = [
      BibleInfo.coinPack1Price,
      BibleInfo.coinPack2Price,
      BibleInfo.coinPack3Price,
    ];
    final creditsById = <String, String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('coin_packs');
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((id, data) {
          final c = (data is Map ? data['credits'] : null)?.toString() ?? '';
          if (c.isNotEmpty) creditsById[id] = c;
        });
      }
    } catch (_) {}
    final pricesById = <String, String>{};
    try {
      if (await InAppPurchase.instance.isAvailable()) {
        final res =
            await InAppPurchase.instance.queryProductDetails(ids.toSet());
        for (final p in res.productDetails) {
          pricesById[p.id] = p.price;
        }
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _packs = [
        for (var i = 0; i < ids.length; i++)
          (
            id: ids[i],
            credits: creditsById[ids[i]] ?? fallbackCredits[i],
            price: pricesById[ids[i]] ?? fallbackPrices[i],
          ),
      ];
    });
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  String _withCommas(String n) {
    final v = int.tryParse(n);
    if (v == null) return n;
    final s = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      credits: credits,
      children: [
        const SizedBox(height: 6),
        _title('Refill your credits'),
        const SizedBox(height: 6),
        _subtitle(
            'Your Lifetime plan keeps ads off. AI runs on credits, so earn them free or top up.'),
        const SizedBox(height: 16),
        _GradientButton(
          gradient: _brownGradient,
          height: 64,
          onTap: adsLeft > 0 && !adBusy ? watchAd : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  adsLeft > 0 ? '▶  Watch & earn' : 'Come back tomorrow',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+50 credits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _TileButton(
          onTap: _claimSeconds == 0 && !_claiming ? _claim : null,
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: _ink),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Free +20 credits',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                _claimSeconds > 0 ? 'in ${_fmt(_claimSeconds)}' : 'Claim now',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAE7B1C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: Divider(color: _tileBorder)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'or buy credits · never expire',
                style: TextStyle(fontSize: 12.5, color: _muted),
              ),
            ),
            Expanded(child: Divider(color: _tileBorder)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < _packs.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _TileButton(
                  highlighted: i == 1,
                  onTap: () async {
                    await _openWallet();
                    await refreshWallet();
                  },
                  child: Column(
                    children: [
                      Text(
                        '✦ ${_withCommas(_packs[i].credits)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        i == 1 ? '${_packs[i].price} · BEST' : _packs[i].price,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Prices in your App Store currency',
          style: TextStyle(fontSize: 12, color: _muted),
        ),
      ],
    );
  }
}

// ── 4. Prayer, free user: "This prayer needs N credits" ──────────────────────

class _PrayerNeedsSheet extends StatefulWidget {
  const _PrayerNeedsSheet({required this.credits, required this.needed});
  final int credits;
  final int needed;

  @override
  State<_PrayerNeedsSheet> createState() => _PrayerNeedsSheetState();
}

class _PrayerNeedsSheetState extends State<_PrayerNeedsSheet>
    with _AdState<_PrayerNeedsSheet> {
  String _fromPrice = BibleInfo.coinPack1Price;

  @override
  void initState() {
    super.initState();
    credits = widget.credits;
    refreshWallet();
    _loadFromPrice();
  }

  Future<void> _loadFromPrice() async {
    try {
      if (await InAppPurchase.instance.isAvailable()) {
        final res = await InAppPurchase.instance
            .queryProductDetails({BibleInfo.coinPack1Id});
        if (res.productDetails.isNotEmpty && mounted) {
          setState(() => _fromPrice = res.productDetails.first.price);
        }
      }
    } catch (_) {}
  }

  Future<void> _invite() async {
    final link = Platform.isIOS
        ? 'https://itunes.apple.com/app/id${BibleInfo.apple_AppId}'
        : 'https://play.google.com/store/apps/details?id=${BibleInfo.android_Package_Name}';
    final size = MediaQuery.sizeOf(context);
    await Share.share(
      'Read, pray, and grow closer to God with ${BibleInfo.bible_shortName}: $link',
      sharePositionOrigin:
          Rect.fromLTWH(size.width / 2 - 50, size.height / 2 - 50, 100, 100),
    );
  }

  Future<void> _openPremium() async {
    final six = await SharPreferences.getString('sixMonthPlan') ??
        BibleInfo.sixMonthPlanid;
    final year = await SharPreferences.getString('oneYearPlan') ??
        BibleInfo.oneYearPlanid;
    final life = await SharPreferences.getString('lifeTimePlan') ??
        BibleInfo.lifeTimePlanid;
    if (!mounted) return;
    Navigator.of(context).pop();
    await PaywallNavigation.openStacked(
      sixMonthPlan: six,
      oneYearPlan: year,
      lifeTimePlan: life,
      checkad: CreditsSheets.checkadId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetShell(
      credits: credits,
      children: [
        const Text('🙏', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 4),
        _title('This prayer needs ${widget.needed} credits'),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14.5, height: 1.35, color: _muted),
            children: [
              const TextSpan(text: 'You have '),
              TextSpan(
                text: '$credits',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, color: _ink),
              ),
              const TextSpan(
                  text:
                      '. Watch a short ad to continue. Your words are saved.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _GradientButton(
          gradient: _brownGradient,
          onTap: adsLeft > 0 && !adBusy ? watchAd : null,
          child: Center(
            child: Text(
              adsLeft > 0 ? '▶  Watch ad · +50 credits' : 'Come back tomorrow',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TileButton(
                onTap: () async {
                  await _openWallet();
                  await refreshWallet();
                },
                child: Column(
                  children: [
                    const Text(
                      '✦ Get credits',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'from $_fromPrice',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TileButton(
                onTap: _invite,
                child: const Column(
                  children: [
                    Text(
                      '🎁 Invite friend',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Share the app',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (BibleInfo.isAutoRenewablePaywallMode) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _openPremium,
            child: const Text(
              'Premium includes unlimited prayers →',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A4F2A),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Reward ad (same rules as Wallet: 50 credits, max 2 per day) ──────────────

class _RewardAd {
  static RewardedAd? _ad;
  static bool _loading = false;

  static Future<void> preload() async {
    if (_ad != null || _loading) return;
    if (!await SharPreferences.adsEnabledFromApiOrConstant()) return;
    final unit = await SharPreferences.getString(SharPreferences.rewardedAd);
    if (unit == null || unit.isEmpty) return;
    AdRequest request;
    try {
      request = await AdConsentManager.getAdRequest();
    } catch (_) {
      request = const AdRequest();
    }
    _loading = true;
    RewardedAd.load(
      adUnitId: unit,
      request: request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('CreditsSheets: reward ad failed to load: $error');
          _ad = null;
          _loading = false;
        },
      ),
    );
  }

  static Future<void> watch() async {
    if (!await InternetConnection().hasInternetAccess) {
      Constants.showToast('No Internet Connection', 2000);
      return;
    }
    if (!await WalletService.canWatchAd()) {
      Constants.showToast(
          'You have already watched 2 ads Today. Come back Tomorrow!', 2000);
      return;
    }
    final ad = _ad;
    if (ad == null) {
      Constants.showToast('Ad is loading. Please try again in a moment.', 2000);
      unawaited(preload());
      return;
    }
    _ad = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        unawaited(preload());
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        a.dispose();
        Constants.showToast('Failed to show ad. Please try again.', 2000);
        unawaited(preload());
        if (!done.isCompleted) done.complete();
      },
    );
    await SharPreferences.setString('OpenAd', '1');
    ad.show(onUserEarnedReward: (_, __) async {
      final balance = await WalletService.watchAdForCredits();
      Constants.showToast(
        balance != null
            ? 'Watched ad! Received 50 credits.'
            : 'You have already watched 2 ads today',
        2000,
      );
    });
    await done.future;
  }
}
