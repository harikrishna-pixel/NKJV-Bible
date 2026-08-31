import 'dart:async';

import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view/constants/images.dart' show Images;

class LeaveRatingScreen extends StatefulWidget {
  const LeaveRatingScreen({super.key});

  @override
  State<LeaveRatingScreen> createState() => _LeaveRatingScreenState();
}

class _LeaveRatingScreenState extends State<LeaveRatingScreen> {
  static const String _kBackground = 'assets/splash-bg.png';

  static const Color _kBrown = Color(0xFF4A2F1D);
  static const Color _kBodyBrown = Color(0xFF6B4E37);
  static const Color _kGold = Color(0xFFC59434);
  static const Color _kButtonBrown = Color(0xFF3D2914);
  static const Color _kScaffoldCream = Color(0xFFF5F0E8);

  static const String _kHeartIcon = 'assets/leave_rating/Heart icon.png';
  static const String _kBookIcon = 'assets/leave_rating/Book icon.png';
  static const String _kShieldIcon = 'assets/leave_rating/Shield icon.png';
  static const String _kStarsIcon = 'assets/leave_rating/Star icon.png';
  static const String _kThumbsUpIcon = 'assets/leave_rating/thumbsup_icon.png';

  bool _showRatedLink = false;
  bool _ratingRequestStarted = false;
  bool _ratingPromptCompleted = false;
  Timer? _clearDeferUpgradeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await precacheImage(const AssetImage(_kBackground), context);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _clearDeferUpgradeTimer?.cancel();
    super.dispose();
  }

  void _goToReading() {
    try {
      final provider = Provider.of<DownloadProvider>(context, listen: false);
      provider.warmDataBeforeHomeScreen();
    } catch (e) {
      debugPrint('warmDataBeforeHomeScreen error: $e');
    }
    // Clear rating defer so the next app open can show open ad (same as Day 2).
    unawaited(
        SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, false));
    // Additive preload only — open ad / rating flow unchanged.
    AdService.preloadInterstitialAdIfNeeded();
    Get.offAll(
          () => HomeScreen(
        From: "splash",
        selectedVerseNumForRead: "",
        selectedBookForRead: "",
        selectedChapterForRead: "",
        selectedBookNameForRead: "",
        selectedVerseForRead: "",
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 280),
      opaque: true,
    );
  }

  Future<void> _markFirstStreakRatingHandled() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    await SharPreferences.setString(
        SharPreferences.streakCelebrationShownDate, today);
    await SharPreferences.setBoolean(
        SharPreferences.hasShownLeaveRatingScreen, true);
    await SharPreferences.setInt(
        SharPreferences.pendingStreakCompleteCelebration, 0);
  }

  Future<void> _prepareRatingEnvironment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('showopenad', 'false');
      await SharPreferences.setString('OpenAd', '1');
      await SharPreferences.setBoolean(
          SharPreferences.deferUpgradeAlert, true);
    } catch (_) {}
  }

  Future<void> _clearDeferUpgradeAfterRating() async {
    _clearDeferUpgradeTimer?.cancel();
    _clearDeferUpgradeTimer = Timer(const Duration(seconds: 5), () {
      unawaited(
          SharPreferences.setBoolean(SharPreferences.deferUpgradeAlert, false));
    });
  }

  Future<void> _triggerRating() async {
    if (_ratingRequestStarted) return;
    _ratingRequestStarted = true;
    if (mounted) {
      setState(() => _showRatedLink = true);
    }

    await _markFirstStreakRatingHandled();
    await _prepareRatingEnvironment();

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } catch (e, st) {
      debugPrint('Leave rating screen review request failed: $e,$st');
    }

    await _clearDeferUpgradeAfterRating();

    if (mounted) {
      setState(() => _ratingPromptCompleted = true);
    }
  }

  void _onLeaveRatingTap() {
    if (_ratingPromptCompleted) {
      _goToReading();
      return;
    }
    if (!_ratingRequestStarted) {
      unawaited(_triggerRating());
    }
  }

  void _onRatedLinkTap() {
    if (_ratingPromptCompleted) {
      _goToReading();
    }
  }

  Widget _sparkle({double size = 12, double opacity = 0.85}) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: _kGold.withOpacity(opacity),
    );
  }

  Widget _topEmblem() {
    return Container(
      height: 84,
      width: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(Images.appIcon1024),
          fit: BoxFit.cover,
        ),
      ),

    );
  }

  Widget _referenceThumb(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _kThumbsUpIcon,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }

  Widget _centralGraphic({required bool isCompact}) {
    final ringSize = isCompact ? 228.0 : 252.0;
    final starsWidth = isCompact ? 176.0 : 196.0;
    final thumbSize = isCompact ? 108.0 : 120.0;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            width: ringSize,
            height: ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF9F1DC).withOpacity(0.9),
              border: Border.all(
                color: _kGold.withOpacity(0.34),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kGold.withOpacity(0.22),
                  blurRadius: 26,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          Container(
            width: ringSize * 0.9,
            height: ringSize * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _kGold.withOpacity(0.14),
                width: 1,
              ),
            ),
          ),
          Positioned(
            top: ringSize * 0.07,
            child: Image.asset(
              _kStarsIcon,
              width: starsWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned(
            top: ringSize * 0.34,
            left: ringSize * 0.14,
            child: _sparkle(size: 10, opacity: 0.7),
          ),
          Positioned(
            top: ringSize * 0.36,
            right: ringSize * 0.14,
            child: _sparkle(size: 11, opacity: 0.75),
          ),
          Positioned(
            bottom: ringSize * 0.28,
            left: ringSize * 0.2,
            child: _sparkle(size: 9, opacity: 0.65),
          ),
          Positioned(
            bottom: ringSize * 0.3,
            right: ringSize * 0.2,
            child: _sparkle(size: 10, opacity: 0.68),
          ),
          Positioned(
            bottom: ringSize * 0.12,
            child: _referenceThumb(thumbSize),
          ),
        ],
      ),
    );
  }

  Widget _benefitDivider() {
    return Container(
      width: 1,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: _kBrown.withOpacity(0.16),
    );
  }

  Widget _benefitItem({
    required String asset,
    required String label,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: _kBrown,
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaButton({required bool isCompact}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _onLeaveRatingTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: double.infinity,
          height: isCompact ? 52 : 56,
          decoration: BoxDecoration(
            color: _kButtonBrown,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: _kGold.withOpacity(0.55),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _kButtonBrown.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                'Leave a Rating!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isCompact ? 17 : 18,
                  fontWeight: FontWeight.w700,
                  color: _kGold,
                  fontFamily: 'Georgia',
                ),
              ),
              Positioned(
                left: 18,
                child: Icon(
                  Icons.star_outline_rounded,
                  color: _kGold.withOpacity(0.95),
                  size: 22,
                ),
              ),
              Positioned(
                right: 16,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: _kGold.withOpacity(0.95),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isCompact = media.size.width < 375 || media.size.height < 700;
    final horizontalPad = isCompact ? 22.0 : 28.0;

    return Scaffold(
      backgroundColor: _kScaffoldCream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              _kBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: _kScaffoldCream);
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.14),
                    ],
                    stops: const [0.58, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      36,
                      horizontalPad,
                      8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_topEmblem()],
                        ),
                        SizedBox(height: isCompact ? 12 : 16),
                        Text(
                          'Leave a Rating!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 28 : 32,
                            fontWeight: FontWeight.w700,
                            color: _kBrown,
                            fontFamily: 'Georgia',
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your rating encourages us to keep going.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 15,
                            color: _kBodyBrown,
                            fontFamily: 'Georgia',
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: isCompact ? 16 : 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _centralGraphic(isCompact: isCompact),
                          ],
                        ),
                        SizedBox(height: isCompact ? 18 : 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _benefitItem(
                              asset: _kHeartIcon,
                              label: 'Encourages\nour team',
                            ),
                            _benefitDivider(),
                            _benefitItem(
                              asset: _kBookIcon,
                              label: 'Helps more people\ndiscover the Bible',
                            ),
                            _benefitDivider(),
                            _benefitItem(
                              asset: _kShieldIcon,
                              label: 'Supports\nour mission',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    0,
                    horizontalPad,
                    media.padding.bottom > 0
                        ? media.padding.bottom + 8
                        : (isCompact ? 16 : 24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showRatedLink) ...[
                        GestureDetector(
                          onTap: _onRatedLinkTap,
                          child: Text(
                            'I rated!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _kGold,
                              fontFamily: 'Georgia',
                              decoration: TextDecoration.underline,
                              decorationColor: _kGold,
                              decorationThickness: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _ctaButton(isCompact: isCompact),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                onPressed: () => Get.back(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _kBrown,
                  size: 20,
                ),
              ),
            ),
          ],
            ),
          ),
        ],
      ),
    );
  }
}