import 'dart:io';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/services/premium_entitlement_label_sync.dart';
import 'package:biblebookapp/services/trial_reminder_ux.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Manage Premium info screen (display only — no IAP / purchase changes).
/// Lifetime, Exit yearly (no trial), and normal trial / post-trial yearly UI.
class ManagePremiumScreen extends StatefulWidget {
  const ManagePremiumScreen({
    super.key,
    required this.expiryDate,
  });

  final DateTime expiryDate;

  @override
  State<ManagePremiumScreen> createState() => _ManagePremiumScreenState();
}

class _ManagePremiumScreenState extends State<ManagePremiumScreen> {
  static const Color _cream = Color(0xFFF7F0E4);
  static const Color _card = Color(0xFFFFF8EC);
  static const Color _ink = Color(0xFF3D2914);
  static const Color _maroon = Color(0xFF8B3A2F);
  static const Color _muted = Color(0xFF6B5344);
  static const Color _check = Color(0xFFC0783A);
  static const Color _border = Color(0xFFE8D4B0);

  bool _loading = true;
  bool _isLifetime = false;
  bool _isExitOffer = false;
  String _planLabel = 'Yearly Premium';
  TrialDrawerState _trial = TrialDrawerState.none;
  final LayerLink _infoLink = LayerLink();
  OverlayEntry? _infoOverlay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _removeInfoTip();
    super.dispose();
  }

  Future<void> _load() async {
    String? plan;
    String? productId;
    try {
      final download = Provider.of<DownloadProvider>(context, listen: false);
      plan = await download.getSubscriptionPlan();
      productId = await PremiumEntitlementLabelSync.readLastProductId();
    } catch (_) {}

    final days = _daysRemaining(widget.expiryDate);
    final kind = PremiumEntitlementLabelSync.periodKind(
      plan: plan,
      productId: productId,
      daysRemaining: days,
    );
    final exit = BibleInfo.isExitOfferYearlyProductId(productId ?? '');
    // Exit yearly must never show Lifetime card (stale platinum / far expiry).
    final lifetime = !exit && kind == 'lifetime';
    TrialDrawerState trial = TrialDrawerState.none;
    if (!lifetime && !exit) {
      try {
        trial = await TrialReminderUx.drawerState();
      } catch (_) {}
    }

    String planLabel = 'Yearly Premium';
    if (exit) {
      planLabel = 'Yearly Premium';
    } else {
      switch (kind) {
        case 'lifetime':
          planLabel = 'Lifetime Access';
          break;
        case 'twoyear':
          planLabel = '2-Year Premium';
          break;
        case 'sixmonth':
          planLabel = '6-Month Premium';
          break;
        case 'month':
          planLabel = 'Monthly Premium';
          break;
        case 'year':
        default:
          planLabel = 'Yearly Premium';
          break;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLifetime = lifetime;
      _isExitOffer = exit;
      _planLabel = planLabel;
      _trial = trial;
      _loading = false;
    });
  }

  int _daysRemaining(DateTime expiry) {
    final e = DateTime(expiry.year, expiry.month, expiry.day);
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return e.difference(today).inDays;
  }

  String _renewsOnLabel() => DateFormat('d MMM yyyy').format(widget.expiryDate);

  void _removeInfoTip() {
    _infoOverlay?.remove();
    _infoOverlay = null;
  }

  void _toggleInfoTip() {
    if (_infoOverlay != null) {
      _removeInfoTip();
      return;
    }
    final overlay = Overlay.of(context);
    _infoOverlay = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _removeInfoTip,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
            CompositedTransformFollower(
              link: _infoLink,
              showWhenUnlinked: false,
              offset: const Offset(-220, 36),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 250,
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: _check),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "To change or cancel your subscription, go to your device's App Store subscription settings.",
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _removeInfoTip,
                        child: const Icon(Icons.close, size: 18, color: _muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_infoOverlay!);
  }

  Future<void> _openStoreSubscriptions() async {
    _removeInfoTip();
    final uri = Uri.parse(
      Platform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions',
    );
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened) return;
    } catch (_) {}
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Manage Premium',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: _ink,
          ),
        ),
        actions: [
          if (!_loading && !_isLifetime)
            CompositedTransformTarget(
              link: _infoLink,
              child: IconButton(
                onPressed: _toggleInfoTip,
                icon: Icon(Icons.info_outline_rounded, color: _check, size: 24),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _maroon))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (_isLifetime) _buildLifetimeCard() else _buildSubscriptionCard(),
                const SizedBox(height: 14),
                _buildIncludesCard(),
              ],
            ),
    );
  }

  Widget _buildLifetimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Text(
            'Premium Active',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: _maroon,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [Color(0xFFA67C3D), Color(0xFF7A5528)],
              ),
            ),
            child: const Text(
              '∞  Lifetime Access',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'You have unlocked Lifetime access to all premium features.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final showTrialStatus =
        !_isExitOffer && _trial.showTrialBadge && _trial.showEndingCard;
    final showTrialOnly =
        !_isExitOffer && _trial.showTrialBadge && !_trial.showEndingCard;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/gold-premium-icons/theme_premium_crown.png',
                width: 42,
                height: 42,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/gold-premium-icons/top_crown.png',
                  width: 42,
                  height: 42,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.workspace_premium, size: 40, color: _check),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Active',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: _maroon,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "You're enjoying unlimited AI with Premium.",
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _detailRow(label: 'Plan', value: _planLabel, onTap: _openStoreSubscriptions),
          if (showTrialStatus)
            _statusChipRow(
              label: 'Status',
              value: _trial.title.isNotEmpty ? _trial.title : 'Trial',
              bg: const Color(0xFFF8E6D4),
              fg: _maroon,
            )
          else if (showTrialOnly)
            _statusChipRow(
              label: 'Status',
              value: 'Trial',
              bg: const Color(0xFFE4F0DC),
              fg: const Color(0xFF4F7A3E),
            )
          else
            _detailRow(
              label: 'Renews On',
              value: _renewsOnLabel(),
              onTap: _openStoreSubscriptions,
            ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChipRow({
    required String label,
    required String value,
    required Color bg,
    required Color fg,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludesCard() {
    final items = _isLifetime
        ? const [
            'Remove ads permanently',
            'Access to all premium reading & study tools',
            '5,000 AI credits (~250 AI chats)',
            'Join and participate in the Prayer Wall community',
          ]
        : const [
            'Unlimited AI chat & answers',
            'Unlimited verse explanations',
            'Unlimited prayer generation',
            'Access to all AI features',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Includes',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: _maroon,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_rounded, size: 20, color: _check),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
