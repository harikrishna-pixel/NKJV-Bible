import 'dart:async';
import 'dart:io';

import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/core/notifiers/download.notifier.dart';
import 'package:biblebookapp/utils/custom_share.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/share_preferences.dart';
import 'package:biblebookapp/view/screens/auth/splash.dart';
import 'package:biblebookapp/view/screens/category_detail_screen/view/image_detail_screen.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/dashboard/home_screen.dart';
import 'package:biblebookapp/view/screens/verse_topics/verse_topics_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class VerseTopicDetailScreen extends StatefulWidget {
  const VerseTopicDetailScreen({
    super.key,
    required this.categoryName,
  });

  final String categoryName;

  @override
  State<VerseTopicDetailScreen> createState() => _VerseTopicDetailScreenState();
}

class _VerseTopicDetailScreenState extends State<VerseTopicDetailScreen>
    with WidgetsBindingObserver {
  static const Color _ink = Color(0xFF3D2914);
  static const Color _card = Color(0xFFF8F4EB);
  static const Color _gold = Color(0xFF8B6914);

  final ScrollController _scrollController = ScrollController();
  bool _showCategoryTitleInTopBar = false;

  List<VerseTopicVerse> _allVerses = [];
  bool _loading = true;

  /// Display-only monetization (does not change verse/action logic).
  final AdService _adService = AdService();
  bool _adsEnabled = false;
  int _actionTapCount = 0;
  final Map<int, BannerAd> _bannerAds = {};
  final Set<int> _bannerSlotsLoading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    _loadVerses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    for (final ad in _bannerAds.values) {
      ad.dispose();
    }
    _bannerAds.clear();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final shouldShow = _scrollController.offset > 140;
    if (shouldShow == _showCategoryTitleInTopBar) return;
    setState(() => _showCategoryTitleInTopBar = shouldShow);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  Future<void> _loadVerses() async {
    final verses =
        await VerseTopicsData.loadVersesForCategory(widget.categoryName);
    if (!mounted) return;
    setState(() {
      _allVerses = verses;
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAdsIfNeeded();
    });
  }

  Future<void> _initAdsIfNeeded() async {
    if (!mounted || _allVerses.isEmpty) return;
    final shouldLoad = await SharPreferences.shouldLoadAd();
    if (!mounted || !shouldLoad) return;

    setState(() => _adsEnabled = true);
    _adService.loadInterstitialAd(() {
      if (mounted) setState(() {});
    });

    final slotCount = _allVerses.length ~/ 4;
    for (var slot = 0; slot < slotCount; slot++) {
      unawaited(_loadAdaptiveBanner(slot));
    }
  }

  Future<void> _loadAdaptiveBanner(int slotIndex) async {
    if (!_adsEnabled || !mounted) return;
    if (_bannerAds.containsKey(slotIndex) ||
        _bannerSlotsLoading.contains(slotIndex)) {
      return;
    }
    _bannerSlotsLoading.add(slotIndex);

    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width,
      );
      if (size == null || !mounted) {
        _bannerSlotsLoading.remove(slotIndex);
        return;
      }

      final adUnitId =
          await SharPreferences.getString(SharPreferences.googleBannerId);
      if (adUnitId == null || adUnitId.isEmpty || !mounted) {
        _bannerSlotsLoading.remove(slotIndex);
        return;
      }

      final banner = BannerAd(
        size: size,
        adUnitId: adUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _bannerSlotsLoading.remove(slotIndex);
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _bannerAds[slotIndex] = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, error) {
            _bannerSlotsLoading.remove(slotIndex);
            ad.dispose();
          },
        ),
        request: await AdConsentManager.getAdRequest(),
      );
      await banner.load();
    } catch (_) {
      _bannerSlotsLoading.remove(slotIndex);
    }
  }

  /// Counts Read/Copy/Share/Ask taps; every 10th shows interstitial, then runs
  /// the existing action unchanged.
  Future<void> _onVerseAction(FutureOr<void> Function() action) async {
    _actionTapCount++;
    if (_actionTapCount % 10 == 0) {
      final shouldLoad = await SharPreferences.shouldLoadAd();
      if (shouldLoad && mounted) {
        await _adService.showInterstitialAdAndWait();
      }
    }
    if (!mounted) return;
    await action();
  }

  Widget _buildInlineBanner(int slotIndex) {
    final ad = _bannerAds[slotIndex];
    if (ad == null) {
      return const SizedBox(height: 12);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(key: ValueKey('topic-banner-$slotIndex'), ad: ad),
        ),
      ),
    );
  }

  List<Widget> _buildVerseListChildren({
    required bool isWide,
    required bool isDark,
    required Color cardBorder,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < _allVerses.length; i++) {
      final verse = _allVerses[i];
      children.add(
        _VerseCard(
          verse: verse,
          isWide: isWide,
          isDark: isDark,
          cardBorder: cardBorder,
          onRead: () => _onVerseAction(() => _readVerse(verse)),
          onCopy: () => _onVerseAction(() => _copyVerse(verse)),
          onShare: () => _onVerseAction(() => _shareVerse(verse)),
          onAsk: () => _onVerseAction(() => _askAboutVerse(verse)),
        ),
      );
      final oneBased = i + 1;
      if (_adsEnabled && oneBased % 4 == 0) {
        children.add(_buildInlineBanner((oneBased ~/ 4) - 1));
      }
    }
    return children;
  }

  Future<void> _shareVerse(VerseTopicVerse verse) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ShareAlertBox(
        verseTitle: verse.reference,
        onShareAsText: () async {
          Navigator.of(dialogContext).pop();
          await _shareAsText(verse);
        },
        onShareAsImage: () async {
          Navigator.of(dialogContext).pop();
          final appPackageName =
              (await PackageInfo.fromPlatform()).packageName;
          final appid = BibleInfo.apple_AppId;
          final shareFooterMessage = Platform.isAndroid
              ? '\n\nYou can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName'
              : '\n\nYou can read more at:\nhttps://itunes.apple.com/app/id$appid';
          final controller = DashBoardController();
          if (!mounted) return;
          await showModalBottomSheet<void>(
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            context: context,
            builder: (sheetContext) {
              return ImageBottomSheets.dailyVerse(
                controller: controller,
                content: verse.contentHtml,
                selectedBook: verse.bookName,
                selectedChapter: '${verse.chapterNum + 1}',
                selectedVerseView: '${verse.verseNum + 1}',
                shareFooterMessage: shareFooterMessage,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _shareAsText(VerseTopicVerse verse) async {
    final appPackageName = (await PackageInfo.fromPlatform()).packageName;
    final appid = BibleInfo.apple_AppId;
    final message = Platform.isAndroid
        ? '${verse.plainText}.\n\nYou can read more at:\nhttps://play.google.com/store/apps/details?id=$appPackageName'
        : '${verse.plainText}.\n${verse.reference}\n\nYou can read more at:\nhttps://itunes.apple.com/app/id$appid';
    await Share.share(
      message,
      sharePositionOrigin: Rect.fromPoints(const Offset(2, 2), const Offset(3, 3)),
    );
  }

  Future<void> _copyVerse(VerseTopicVerse verse) async {
    await SharPreferences.setString('OpenAd', '1');
    await Clipboard.setData(
      ClipboardData(text: '${verse.plainText}\n${verse.reference}'),
    );
    Constants.showToast('Copied');
  }

  Future<void> _readVerse(VerseTopicVerse verse) async {
    Provider.of<DownloadProvider>(context, listen: false).enableAd();
    await SharPreferences.setString('OpenAd', '1');
    final bookName = verse.bookName;
    final bookNum = verse.bookNum;
    final chapter = verse.chapterNum + 1;
    final verseIndex = verse.verseNum;
    final verseText = verse.plainText;
    await SharPreferences.setString(
      SharPreferences.selectedBook,
      bookName,
    );
    await SharPreferences.setString(
      SharPreferences.selectedChapter,
      '$chapter',
    );
    await SharPreferences.setString(
      SharPreferences.selectedBookNum,
      '$bookNum',
    );
    // Prefer updating existing Home + pop to root (smooth) over offAll rebuild.
    try {
      final controller = Get.find<DashBoardController>();
      controller.selectedBook.value = bookName;
      controller.selectedBookNum.value = '$bookNum';
      controller.selectedChapter.value = '$chapter';
      controller.selectChapterChange.value = chapter;
      controller.selectedBookNameForRead.value = bookName;
      controller.selectedBookNumForRead.value = '$bookNum';
      controller.selectedChapterForRead.value = '$chapter';
      controller.selectedVerseForRead.value = '$verseIndex';
      controller.isFetchContent.value = true;
      controller.selectedBookContent.clear();
      await controller.getSelectedChapterAndBook();
      controller.isFetchContent.value = false;
      controller.readHighlight.value = true;
      controller.selectedIndex.value = verseIndex;
      if (Navigator.of(context).canPop()) {
        Get.until((route) => route.isFirst);
      } else {
        Get.offAll(
          () => HomeScreen(
            From: 'Read',
            selectedBookForRead: bookNum,
            selectedChapterForRead: chapter,
            selectedVerseNumForRead: verseIndex,
            selectedBookNameForRead: bookName,
            selectedVerseForRead: verseText,
            fromSearch: true,
          ),
          // Avoid fadeIn — it briefly reveals the light app bridge color.
          transition: Transition.cupertino,
          duration: const Duration(milliseconds: 280),
          opaque: true,
        );
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 80), () async {
          try {
            await controller.scrollToIndex(verseIndex);
          } catch (_) {}
          Future.delayed(const Duration(seconds: 6), () {
            controller.readHighlight.value = false;
            controller.selectedIndex.value = -1;
          });
        });
      });
    } catch (_) {
      Get.offAll(
        () => HomeScreen(
          From: 'Read',
          selectedBookForRead: bookNum,
          selectedChapterForRead: chapter,
          selectedVerseNumForRead: verseIndex,
          selectedBookNameForRead: bookName,
          selectedVerseForRead: verseText,
          fromSearch: true,
        ),
        // Avoid fadeIn — it briefly reveals the light app bridge color.
        transition: Transition.cupertino,
        duration: const Duration(milliseconds: 280),
        opaque: true,
      );
    }
  }

  void _askAboutVerse(VerseTopicVerse verse) {
    Get.to(
      () => ChatScreen(
        verseContext: {
          'verseText': verse.plainText,
          'book': verse.bookName,
          'chapter': '${verse.chapterNum + 1}',
          'verse': '${verse.verseNum + 1}',
        },
      ),
      transition: Transition.cupertino,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 450;
    final isDark =
        Provider.of<ThemeProvider>(context, listen: false).themeMode ==
            ThemeMode.dark;
    final cardBorder =
        isDark ? _ink.withValues(alpha: 0.38) : _ink.withValues(alpha: 0.12);
    final bgColor = isDark
        ? CommanColor.darkPrimaryColor
        : const Color(0xFFF5F0E6);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: isDark ? Colors.white : _ink,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showCategoryTitleInTopBar ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        widget.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: isWide ? 18 : 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : _ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: isDark ? Colors.white : _ink,
                      ),
                    )
                  : ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          children: [
                            Center(
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  isDark ? Colors.white : _ink,
                                  BlendMode.srcIn,
                                ),
                                child: Image.asset(
                                  Images.searchPlaceHolder(context),
                                  width: isWide ? 88 : 72,
                                  height: isWide ? 88 : 72,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.categoryName,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: isWide ? 30 : 26,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : _ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              VerseTopicsData.subtitleForCategory(
                                widget.categoryName,
                              ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: isWide ? 16 : 14,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.82)
                                    : _ink.withValues(alpha: 0.82),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : _gold.withValues(alpha: 0.9),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_allVerses.length} Verses Found',
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: isWide ? 15 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : _ink.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (_allVerses.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Text(
                                  'No verses found.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: isWide ? 16 : 14,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : _ink.withValues(alpha: 0.7),
                                  ),
                                ),
                              )
                            else
                              ..._buildVerseListChildren(
                                isWide: isWide,
                                isDark: isDark,
                                cardBorder: cardBorder,
                              ),
                          ],
                        ),
                ),
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  const _VerseCard({
    required this.verse,
    required this.isWide,
    required this.isDark,
    required this.cardBorder,
    required this.onRead,
    required this.onCopy,
    required this.onShare,
    required this.onAsk,
  });

  final VerseTopicVerse verse;
  final bool isWide;
  final bool isDark;
  final Color cardBorder;
  final VoidCallback onRead;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onAsk;

  static const Color _ink = Color(0xFF3D2914);
  static const Color _card = Color(0xFFF8F4EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: isDark ? 1.3 : 1),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: isDark ? 0.1 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    verse.reference,
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: isWide ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                // Icon(
                //   Icons.bookmark_border,
                //   color: _ink.withValues(alpha: 0.55),
                //   size: 22,
                // ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              verse.plainText,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: isWide ? 16 : 14,
                height: 1.5,
                color: _ink.withValues(alpha: 0.92),
              ),
            ),
          ),
          Divider(height: 1, color: _ink.withValues(alpha: 0.12)),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.menu_book_outlined,
                    label: 'Read',
                    onTap: onRead,
                    isWide: isWide,
                    isDark: isDark,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: _ink.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy_outlined,
                    label: 'Copy',
                    onTap: onCopy,
                    isWide: isWide,
                    isDark: isDark,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: _ink.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: onShare,
                    isWide: isWide,
                    isDark: isDark,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  color: _ink.withValues(alpha: 0.12),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Ask',
                    onTap: onAsk,
                    isWide: isWide,
                    isDark: isDark,
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
    required this.isWide,
    this.isDark = false,
  });

  final IconData? icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;
  final bool isWide;
  final bool isDark;

  static const Color _ink = Color(0xFF3D2914);

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isDark ? _ink.withValues(alpha: 0.95) : _ink.withValues(alpha: 0.85);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Image.asset(
                iconAsset!,
                height: 20,
                width: 20,
                color: iconColor,
              )
            else
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: isWide ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
