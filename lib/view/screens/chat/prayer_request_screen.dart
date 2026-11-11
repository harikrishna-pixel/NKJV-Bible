import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/wallet/wallet_screen.dart';
import 'package:biblebookapp/view/widget/credits_sheets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who the prayer is for (screen 2 / 3).
enum PrayerFor { myself, family, someoneElse }

/// What the user filled in on "Your Prayer Request".
class PrayerRequestResult {
  const PrayerRequestResult({
    required this.prayerFor,
    required this.request,
    this.details = '',
    this.name = '',
    this.relationship = '',
    this.answerLength,
  });

  final PrayerFor prayerFor;
  final String request;
  final String details;
  final String name;
  final String relationship;

  /// 'small' | 'medium' | 'large' chosen on "Choose Credit Amount" for this
  /// prayer only. Null when credits are skipped (AI Premium): use saved length.
  final String? answerLength;
}

/// Screens 2 & 3: "Your Prayer Request". Pops with [PrayerRequestResult], or
/// null when the user goes back / taps Change.
class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({
    super.key,
    required this.categoryTitle,
    required this.categorySubtitle,
    required this.categoryIconAsset,
    required this.defaultRequests,
    required this.skipCredits,
    required this.initialAnswerLength,
    this.isCustomFlow = false,
  });

  final String categoryTitle;
  final String categorySubtitle;
  final String? categoryIconAsset;

  /// Default request text for Myself / My family / Someone else.
  final Map<PrayerFor, String> defaultRequests;

  /// AI Premium: no credits, so no credit sheet and no cost on the button.
  final bool skipCredits;
  final String initialAnswerLength;

  /// Pray for Me: same request form, no category card / Change.
  final bool isCustomFlow;

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen> {
  static const _bg = 'assets/prayer_gudiance-bg.png';
  static const _prayingHands = 'assets/take_moment/praying_hands.png';
  static const _brown = Color(0xFF6D4C41);
  static const _brownDark = Color(0xFF4E342E);
  static const _ink = Color(0xFF3D2914);
  static const _muted = Color(0xFF7A6455);
  static const _gold = Color(0xFFC59434);
  static const _cardLight = Color(0xFFFFFAF4);
  static const _borderLight = Color(0xFFE6D8C8);

  static const _relationships = [
    'Friend',
    'Relative',
    'Coworker',
    'Neighbor',
    'Teacher / Mentor',
    'Church member',
    'Other',
  ];

  PrayerFor _for = PrayerFor.myself;
  late final TextEditingController _request;
  final TextEditingController _detailsMyself = TextEditingController();
  final TextEditingController _detailsFamily = TextEditingController();
  final TextEditingController _detailsSomeone = TextEditingController();
  final TextEditingController _name = TextEditingController();
  String? _relationship;
  int _credits = 0;
  /// Lightbulb tip: first visit to this Prayer Request screen only.
  bool _showInfoTip = false;
  static const _infoTipSeenKey = 'prayer_request_info_tip_seen';

  TextEditingController get _details {
    switch (_for) {
      case PrayerFor.family:
        return _detailsFamily;
      case PrayerFor.someoneElse:
        return _detailsSomeone;
      case PrayerFor.myself:
        return _detailsMyself;
    }
  }

  @override
  void initState() {
    super.initState();
    // Pray for Me starts empty (placeholder only); "Use default" fills it.
    _request = TextEditingController(
        text: widget.isCustomFlow ? '' : _defaultFor(PrayerFor.myself));
    _request.addListener(_refresh);
    _detailsMyself.addListener(_refresh);
    _detailsFamily.addListener(_refresh);
    _detailsSomeone.addListener(_refresh);
    _name.addListener(_refresh);
    if (!widget.skipCredits) {
      WalletService.getCredits().then((c) {
        if (mounted) setState(() => _credits = c);
      });
    }
    _loadInfoTipVisibility();
  }

  Future<void> _loadInfoTipVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_infoTipSeenKey) ?? false;
    if (!mounted) return;
    if (!seen) {
      setState(() => _showInfoTip = true);
      await prefs.setBool(_infoTipSeenKey, true);
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _request.dispose();
    _detailsMyself.dispose();
    _detailsFamily.dispose();
    _detailsSomeone.dispose();
    _name.dispose();
    super.dispose();
  }

  String _defaultFor(PrayerFor f) => widget.defaultRequests[f] ?? '';

  /// Same as the Prayer Guidance wallet badge; refresh the balance on return.
  Future<void> _openWallet() async {
    FocusScope.of(context).unfocus();
    await Get.to(() => const WalletScreen());
    final c = await WalletService.getCredits();
    if (mounted) setState(() => _credits = c);
  }

  void _selectFor(PrayerFor f) {
    if (f == _for) return;
    // Swap the text only if the user hasn't edited the current default.
    final untouched = _request.text.trim() == _defaultFor(_for).trim() ||
        _request.text.trim().isEmpty;
    final wasEmpty = _request.text.trim().isEmpty;
    setState(() {
      _for = f;
      if (untouched && !(widget.isCustomFlow && wasEmpty)) {
        _request.text = _defaultFor(f);
      }
    });
  }

  int get _defaultCost =>
      WalletService.getChatCostForLength(widget.initialAnswerLength);

  Future<void> _onGenerate() async {
    FocusScope.of(context).unfocus();
    final request = _request.text.trim();
    if (request.isEmpty) {
      Constants.showToast('Please enter your prayer request.', 2000);
      return;
    }
    String? length;
    if (!widget.skipCredits) {
      // Use saved answer length — do not ask "Choose Credit Amount" each time.
      length =
          const ['small', 'medium', 'large'].contains(widget.initialAnswerLength)
              ? widget.initialAnswerLength
              : await WalletService.getAnswerLength();
      if (!mounted) return;
      // Not enough credits: show the credits sheet here so the typed request
      // stays on this screen.
      final cost = WalletService.getChatCostForLength(length);
      if (await WalletService.getCredits() < cost) {
        if (!mounted) return;
        await CreditsSheets.showOutOfCredits(
          context,
          from: CreditsSheetFrom.prayer,
          needed: cost,
        );
        final c = await WalletService.getCredits();
        if (mounted) setState(() => _credits = c);
        return;
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      PrayerRequestResult(
        prayerFor: _for,
        request: request,
        details: _details.text.trim(),
        name: _for == PrayerFor.someoneElse ? _name.text.trim() : '',
        relationship:
            _for == PrayerFor.someoneElse ? (_relationship ?? '') : '',
        answerLength: length,
      ),
    );
  }

  bool _isDark(BuildContext context) =>
      Provider.of<ThemeProvider>(context, listen: false).themeMode ==
      ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final ink = isDark ? Colors.white : _ink;
    final muted = isDark ? Colors.white70 : _muted;
    final card = isDark ? Colors.black.withValues(alpha: 0.45) : _cardLight;
    final border = isDark ? Colors.white.withValues(alpha: 0.25) : _borderLight;
    final isTablet = MediaQuery.sizeOf(context).width > 450;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F4EE),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _bg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            if (isDark)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.6)),
              ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _topBar(ink),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                          children: [
                            if (widget.isCustomFlow) ...[
                              _header(ink, muted, isTablet),
                              const SizedBox(height: 16),
                            ] else ...[
                              const SizedBox(height: 4),
                              _categoryCard(ink, muted, card, border),
                              const SizedBox(height: 18),
                            ],
                            _label('Who are you praying for?', ink),
                            const SizedBox(height: 10),
                            _whoChips(ink, card, border),
                            if (widget.isCustomFlow &&
                                _for == PrayerFor.someoneElse) ...[
                              const SizedBox(height: 18),
                              _label('Tell us a little about them', ink),
                              const SizedBox(height: 10),
                              _smallLabel('Name (optional)', ink),
                              const SizedBox(height: 6),
                              _textField(
                                controller: _name,
                                hint: 'e.g. John, My friend, My colleague',
                                maxLength: 50,
                                maxLines: 1,
                                ink: ink,
                                muted: muted,
                                card: card,
                                border: border,
                              ),
                              const SizedBox(height: 10),
                              _smallLabel('Relationship (optional)', ink),
                              const SizedBox(height: 6),
                              _relationshipField(ink, muted, card, border),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                    child: _label('Your prayer request', ink)),
                                TextButton.icon(
                                  onPressed: () => setState(
                                      () => _request.text = _defaultFor(_for)),
                                  // Gold + light halo so it stays readable on
                                  // the dark photo areas (same accent as Change).
                                  icon: const Icon(Icons.refresh,
                                      size: 16, color: _gold),
                                  label: Text(
                                    'Use default',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _gold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: _gold,
                                      shadows: _onPhotoShadow(_ink),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _textField(
                              controller: _request,
                              hint: widget.isCustomFlow
                                  ? 'Speak from your heart...'
                                  : 'Share what you would like to pray for...',
                              maxLength: 500,
                              maxLines: widget.isCustomFlow ? 5 : 10,
                              minLines: widget.isCustomFlow ? 3 : 7,
                              ink: ink,
                              muted: muted,
                              card: card,
                              border: border,
                            ),
                            if (!widget.isCustomFlow &&
                                _for == PrayerFor.someoneElse) ...[
                              const SizedBox(height: 14),
                              Text.rich(
                                TextSpan(
                                  text: 'Relationship',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' (optional)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _relationshipField(ink, muted, card, border),
                            ],
                            if (widget.isCustomFlow) ...[
                              const SizedBox(height: 14),
                              _label('Additional details (optional)', ink),
                              const SizedBox(height: 8),
                              KeyedSubtree(
                                key: ValueKey(_for),
                                child: _textField(
                                  controller: _details,
                                  hint:
                                      "Share anything specific you'd like to include...\n(e.g. a situation, a person, or something on your heart)",
                                  maxLength: 500,
                                  maxLines: 4,
                                  minLines: 3,
                                  ink: ink,
                                  muted: muted,
                                  card: card,
                                  border: border,
                                ),
                              ),
                            ],
                            if (_showInfoTip) ...[
                              const SizedBox(height: 14),
                              _infoCard(ink, muted, isDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _bottomBar(isDark, muted),
      ),
    );
  }

  Widget _topBar(Color ink) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          if (!widget.skipCredits)
            GestureDetector(
              onTap: _openWallet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _cardLight.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined,
                        size: 16, color: _brownDark),
                    const SizedBox(width: 6),
                    Text(
                      '$_credits',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _brownDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(Color ink, Color muted, bool isTablet) {
    final title = widget.isCustomFlow
        ? "What's on your heart today?"
        : 'Your Prayer Request';
    final subtitle = widget.isCustomFlow
        ? "Share your prayer, and we'll create a meaningful, Bible-based prayer just for you."
        : 'Take a moment to make this prayer your own.';
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _cardLight,
            border: Border.all(color: _gold.withValues(alpha: 0.7), width: 2),
          ),
          child: Image.asset(
            _prayingHands,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.volunteer_activism, color: _brown),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: isTablet ? 26 : 23,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: muted, height: 1.35),
        ),
        if (widget.isCustomFlow) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: muted.withValues(alpha: 0.35),
                  thickness: 1,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.favorite, size: 16, color: _gold),
              ),
              Expanded(
                child: Divider(
                  color: muted.withValues(alpha: 0.35),
                  thickness: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _categoryCard(Color ink, Color muted, Color card, Color border) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _gold.withValues(alpha: 0.18),
            ),
            child: widget.categoryIconAsset != null
                ? Image.asset(widget.categoryIconAsset!, fit: BoxFit.contain)
                : const Icon(Icons.favorite, color: _brown),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryTitle,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.categorySubtitle,
                  style: TextStyle(fontSize: 12.5, color: muted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: _gold,
              side: const BorderSide(color: _gold),
              padding: const EdgeInsets.only(left: 12, right: 6),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color ink) => Text(
        text,
        style: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      );

  List<Shadow> _onPhotoShadow(Color ink) {
    if (ink == Colors.white || ink == Colors.white70) return const [];
    return const [Shadow(color: Color(0xF5FFF8F0), blurRadius: 8)];
  }

  Widget _smallLabel(String text, Color ink) => Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
          shadows: _onPhotoShadow(ink),
        ),
      );

  Widget _whoChips(Color ink, Color card, Color border) {
    Widget chip(PrayerFor f, IconData icon, String label) {
      final selected = _for == f;
      return Expanded(
        child: Material(
          color: selected ? _brown : card,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _selectFor(f),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected ? _brown : border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: selected ? Colors.white : ink),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : ink,
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

    // Equal-width chips that fill the row; on narrow screens (SE) the row
    // scrolls horizontally instead of cutting the labels.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: IntrinsicWidth(
            child: Row(
              children: [
                chip(PrayerFor.myself, Icons.person_outline, 'Myself'),
                const SizedBox(width: 8),
                chip(PrayerFor.family, Icons.groups_outlined, 'My family'),
                const SizedBox(width: 8),
                chip(PrayerFor.someoneElse, Icons.person_add_alt_outlined,
                    'Someone else'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required Color muted,
    required Color card,
    required Color border,
    required Color ink,
    String? counter,
  }) {
    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.75), fontSize: 14),
      filled: true,
      fillColor: card,
      counterText: counter,
      counterStyle: TextStyle(
        color: ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        shadows: _onPhotoShadow(ink),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(_brown, 1.5),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required int maxLines,
    int? minLines,
    required Color ink,
    required Color muted,
    required Color card,
    required Color border,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: minLines,
      style: TextStyle(fontSize: 15, height: 1.4, color: ink),
      decoration: _decoration(
        hint: hint,
        muted: muted,
        card: card,
        border: border,
        ink: ink,
        counter: '${controller.text.length}/$maxLength',
      ),
    );
  }

  Widget _relationshipField(Color ink, Color muted, Color card, Color border) {
    return DropdownButtonFormField<String>(
      initialValue: _relationship,
      isExpanded: true,
      dropdownColor: card == _cardLight ? _cardLight : const Color(0xFF2C2118),
      icon: Icon(Icons.keyboard_arrow_down, color: muted),
      style: TextStyle(fontSize: 15, color: ink),
      hint: Text('Select relationship',
          style: TextStyle(color: muted.withValues(alpha: 0.75), fontSize: 14)),
      decoration: _decoration(
        hint: '',
        muted: muted,
        card: card,
        border: border,
        ink: ink,
        counter: '',
      ),
      items: _relationships
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: (v) => setState(() => _relationship = v),
    );
  }

  Widget _infoCard(Color ink, Color muted, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF3E6D2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: isDark ? _gold : _brown),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A personalized prayer for your needs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "We will create a prayer guided by God's Word based on your request and the details you share.",
                  style: TextStyle(fontSize: 12.5, height: 1.35, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(bool isDark, Color muted) {
    final label = widget.skipCredits
        ? 'Generate My Prayer'
        : 'Generate My Prayer · $_defaultCost credits';
    return SafeArea(
      top: false,
      child: Container(
        color: isDark ? Colors.black : const Color(0xFFF8F4EE),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onGenerate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brownDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You can edit your request anytime before generating.',
                  style: TextStyle(fontSize: 11.5, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Choose Credit Amount" (20 / 50 / 100 = small / medium / large).
/// Shown once on first Prayer Guidance open; Generate uses the saved length after.
class PrayerChooseCreditAmountSheet extends StatefulWidget {
  const PrayerChooseCreditAmountSheet({
    super.key,
    required this.initialLength,
    required this.isDark,
  });

  final String initialLength;
  final bool isDark;

  static Future<String?> show(
    BuildContext context, {
    required String initialLength,
  }) {
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PrayerChooseCreditAmountSheet(
        initialLength: initialLength,
        isDark: isDark,
      ),
    );
  }

  @override
  State<PrayerChooseCreditAmountSheet> createState() =>
      _PrayerChooseCreditAmountSheetState();
}

class _PrayerChooseCreditAmountSheetState
    extends State<PrayerChooseCreditAmountSheet> {
  static const _brown = Color(0xFF6D4C41);
  static const _brownDark = Color(0xFF4E342E);
  static const _ink = Color(0xFF3D2914);
  static const _muted = Color(0xFF7A6455);
  static const _gold = Color(0xFFC59434);

  static const _options = [
    (
      length: 'small',
      title: 'Short prayer (1–2 paragraphs)',
      subtitle: 'Good for simple requests',
    ),
    (
      length: 'medium',
      title: 'Detailed prayer (longer)',
      subtitle: 'With more scripture and guidance',
    ),
    (
      length: 'large',
      title: 'In-depth prayer',
      subtitle: 'More detailed and personalized',
    ),
  ];

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected =
        const ['small', 'medium', 'large'].contains(widget.initialLength)
            ? widget.initialLength
            : 'small';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final sheet = isDark ? const Color(0xFF2C2118) : const Color(0xFFFFFAF4);
    final ink = isDark ? Colors.white : _ink;
    final muted = isDark ? Colors.white70 : _muted;
    final border =
        isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE6D8C8);
    final cost = WalletService.getChatCostForLength(_selected);

    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: sheet,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Choose Credit Amount',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 6),
                for (final o in _options) ...[
                  _option(o.length, o.title, o.subtitle, ink, muted, border),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brownDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Continue',
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Generate with $cost credits',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can change the credit amount anytime.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _option(String length, String title, String subtitle, Color ink,
      Color muted, Color border) {
    final selected = _selected == length;
    final cost = WalletService.getChatCostForLength(length);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selected = length),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _brown : border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withValues(alpha: 0.18),
                  border: Border.all(color: _gold.withValues(alpha: 0.6)),
                ),
                child: const Icon(Icons.star_rounded, color: _gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$cost credits',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(title, style: TextStyle(fontSize: 13, color: ink)),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: muted)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? _brown : muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
